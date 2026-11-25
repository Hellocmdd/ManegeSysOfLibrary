"""
图书管理系统前端入口：登录、书目查询、借还续借与统计报表。

启动：

    python src/frontend/app.py

访问 http://127.0.0.1:5000 ，用测试数据里的管理员账号登录。

路由与 docs/08_前端交付物/README.md 的功能清单一一对应；所有写操作都走 POST，
数据库访问全部经由 ``db.py`` 与 ``queries.py``，本文件不出现 SQL 字面量。
"""

import math
import os
from functools import wraps
from typing import Any, Callable

from flask import (
    Flask,
    flash,
    redirect,
    render_template,
    request,
    session,
    url_for,
)

import queries
from config import BORROW_DAYS, BORROW_LIMIT, HOST, PAGE_SIZE, PORT, SECRET_KEY
from db import (
    DbError,
    call_borrow_book,
    call_renew_book,
    call_return_book,
    init_app,
)

app = Flask(__name__)
app.config["SECRET_KEY"] = SECRET_KEY
init_app(app)

# 借书返回码 → (flash 级别, 页面文案)，与 05_存储过程.sql 的约定一致。
BORROW_MESSAGES: dict[int, tuple[str, str]] = {
    0: ("ok", "借书成功，请在借阅历史里核对应还日期。"),
    -1: ("err", "该副本当前不在馆，请换一本。"),
    -2: ("err", "该读者已被禁用，无法借书。"),
    -3: ("err", f"该读者已借满 {BORROW_LIMIT} 本，请先归还。"),
    -4: ("err", "借书失败，事务已回滚，请稍后重试。"),
}


def login_required(view: Callable[..., Any]) -> Callable[..., Any]:
    """
    要求当前会话已登录，未登录时跳转到登录页。

    *Args:
        view: 被装饰的视图函数。
    *Return:
        包装后的视图函数；未登录时返回登录页重定向。
    """

    @wraps(view)
    def wrapped(*args: Any, **kwargs: Any) -> Any:
        """
        *Args:
            *args: 原样转交给被装饰的视图。
            **kwargs: 原样转交给被装饰的视图。
        *Return:
            已登录时是视图的返回值，未登录时是登录页重定向。
        """
        if not session.get("admin_id"):
            flash("请先用管理员账号登录。", "err")
            return redirect(url_for("login"))
        return view(*args, **kwargs)

    return wrapped


def _page_arg() -> int:
    """
    读取页码参数。

    *Args:
        无（从 ``request.args["page"]`` 取）。
    *Return:
        大于等于 1 的页码；非法输入按第 1 页处理。
    """
    raw = request.args.get("page", "1")
    try:
        return max(1, int(raw))
    except (TypeError, ValueError):
        return 1


def _safe_target(candidate: str | None, fallback: str) -> str:
    """
    校验回跳地址，只允许站内相对路径。

    *Args:
        candidate: 表单里的 ``next`` 值，可能为空或被篡改。
        fallback: 不合法时使用的站内地址。
    *Return:
        以单个 ``/`` 开头且不是 ``//host`` 的地址，否则返回 fallback。
    """
    if candidate and candidate.startswith("/") and not candidate.startswith("//"):
        return candidate
    return fallback


@app.route("/")
def index() -> Any:
    """
    首页直接跳到书目列表，避免多一次点击。

    *Args:
        无。
    *Return:
        指向 ``/books`` 的重定向。
    """
    return redirect(url_for("book_list"))


@app.route("/login", methods=["GET", "POST"])
def login() -> Any:
    """
    管理员登录。

    *Args:
        无（POST 时从表单取 ``account`` / ``password``）。
    *Return:
        GET 渲染登录页；POST 成功后重定向到书目列表，失败重渲染并提示。
    """
    account = ""
    if request.method == "POST":
        account = (request.form.get("account") or "").strip()
        password = request.form.get("password") or ""
        if not account or not password:
            flash("账号和密码都不能为空。", "err")
        else:
            admin = queries.login_admin(account, password)
            if admin is None:
                flash("账号或密码错误。", "err")
            else:
                session.clear()
                session["admin_id"] = admin["admin_id"]
                session["admin_name"] = admin["name"]
                session["admin_role"] = admin["role"]
                flash(f"欢迎，{admin['name']}。", "ok")
                return redirect(url_for("book_list"))
    return render_template("login.html", account=account)


@app.route("/logout")
def logout() -> Any:
    """
    退出登录，清空会话。

    *Args:
        无。
    *Return:
        指向登录页的重定向。
    """
    session.clear()
    flash("已退出登录。", "ok")
    return redirect(url_for("login"))


@app.route("/books")
@login_required
def book_list() -> Any:
    """
    书目列表，支持书名模糊查询、分类筛选与分页，并列出可借副本。

    *Args:
        无（从查询串取 ``title`` / ``cat_id`` / ``reader_id`` / ``page``）。
    *Return:
        渲染 ``book_list.html``；页码越界时收敛到最后一页。
    """
    title_kw = (request.args.get("title") or "").strip()
    cat_id = (request.args.get("cat_id") or "").strip() or None
    reader_id = (request.args.get("reader_id") or "").strip()
    total = queries.count_books(title_kw, cat_id)
    total_pages = max(1, math.ceil(total / PAGE_SIZE))
    page = min(_page_arg(), total_pages)
    books = queries.list_books(title_kw, cat_id, page, PAGE_SIZE)
    copies = queries.available_copies([str(book["book_id"]) for book in books])
    return render_template(
        "book_list.html",
        books=books,
        copies=copies,
        categories=queries.list_categories(),
        readers=queries.list_readers(),
        title_kw=title_kw,
        cat_id=cat_id or "",
        reader_id=reader_id,
        page=page,
        total=total,
        total_pages=total_pages,
        borrow_days=BORROW_DAYS,
        borrow_limit=BORROW_LIMIT,
    )


@app.post("/borrow")
@login_required
def borrow() -> Any:
    """
    借书：调用 ``borrow_book`` 存储过程，按返回码给出提示。

    *Args:
        无（表单字段 ``reader_id`` / ``copy_id`` / ``next``）。
    *Return:
        重定向回列表页，结果通过 flash 提示。
    """
    reader_id = (request.form.get("reader_id") or "").strip()
    copy_id = (request.form.get("copy_id") or "").strip()
    target = _safe_target(request.form.get("next"), url_for("book_list"))
    if not reader_id or not copy_id:
        flash("请先在下拉框选择读者，再点副本编号借书。", "err")
        return redirect(target)
    code = call_borrow_book(reader_id, copy_id)
    level, message = BORROW_MESSAGES.get(code, BORROW_MESSAGES[-4])
    flash(message, level)
    return redirect(target)


@app.post("/borrow/<borrow_id>/return")
@login_required
def return_book(borrow_id: str) -> Any:
    """
    还书：调用 ``return_book``，并把当前管理员记为经办人。

    *Args:
        borrow_id: 借阅编号，来自 URL。
    *Return:
        有读者编号时回到该读者的借阅历史，否则回到上一页。
    """
    reader_id = (request.form.get("reader_id") or "").strip()
    admin_id = str(session.get("admin_id", ""))
    target = _safe_target(request.form.get("next"), url_for("book_list"))
    if call_return_book(borrow_id, admin_id):
        flash("已归还，副本状态同步恢复为在馆。", "ok")
    else:
        flash("该借阅记录不存在或已归还，未做修改。", "err")
    if reader_id:
        return redirect(url_for("reader_history", reader_id=reader_id))
    return redirect(target)


@app.post("/borrow/<borrow_id>/renew")
@login_required
def renew_book(borrow_id: str) -> Any:
    """
    续借：调用 ``renew_book``，把应还日期顺延一个借期。

    *Args:
        borrow_id: 借阅编号，来自 URL。
    *Return:
        有读者编号时回到该读者的借阅历史，否则回到上一页。
    """
    reader_id = (request.form.get("reader_id") or "").strip()
    target = _safe_target(request.form.get("next"), url_for("book_list"))
    if call_renew_book(borrow_id):
        flash(f"续借成功，应还日期顺延 {BORROW_DAYS} 天。", "ok")
    else:
        flash("该记录不存在或已归还，无法续借。", "err")
    if reader_id:
        return redirect(url_for("reader_history", reader_id=reader_id))
    return redirect(target)


@app.route("/readers/<reader_id>")
@login_required
def reader_history(reader_id: str) -> Any:
    """
    读者档案与全部借阅记录，可在本页直接还书、续借。

    *Args:
        reader_id: 读者编号，来自 URL。
    *Return:
        渲染 ``reader_history.html``；编号不存在时渲染 404。
    """
    reader = queries.get_reader(reader_id)
    if reader is None:
        return render_template(
            "error.html", message="读者编号不存在。", code=404
        ), 404
    return render_template(
        "reader_history.html",
        reader=reader,
        borrows=queries.borrow_history(reader_id),
        next=request.full_path,
    )


@app.route("/reports")
@login_required
def reports() -> Any:
    """
    统计报表：热门图书、分类馆藏、当前逾期、月度借阅量。

    *Args:
        无。
    *Return:
        渲染 ``reports.html``，四组数据一次查询取齐。
    """
    return render_template(
        "reports.html",
        top_books=queries.top_books(),
        category_stock=queries.category_stock(),
        overdue=queries.overdue_borrows(),
        monthly=queries.monthly_borrows(),
    )


@app.errorhandler(DbError)
def handle_db_error(exc: DbError) -> tuple[str, int]:
    """
    数据库错误统一渲染成错误页，而不是把堆栈暴露给使用者。

    *Args:
        exc: ``db.DbError`` 实例，自带中文说明与 MySQL 错误码。
    *Return:
        ``(错误页 HTML, 503)``。
    """
    return render_template("error.html", message=exc.message, code=exc.code), 503


@app.errorhandler(404)
def handle_not_found(exc: Any) -> tuple[str, int]:
    """
    未匹配的地址渲染错误页。

    *Args:
        exc: Flask 传入的 404 异常，本函数不使用。
    *Return:
        ``(错误页 HTML, 404)``。
    """
    return render_template(
        "error.html", message="页面不存在，请从书目列表重新进入。", code=404
    ), 404


if __name__ == "__main__":
    app.run(host=HOST, port=PORT, debug=os.getenv("FLASK_DEBUG") == "1")
