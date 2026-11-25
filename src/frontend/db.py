"""
数据库访问层：连接生命周期、参数化查询与存储过程调用。

三条约定：

1. 每个请求一个连接，挂在 Flask ``g`` 上，请求结束由 ``teardown_appcontext`` 关闭；
2. 所有 SQL 都是参数化的，本模块不接受调用方拼好的 SQL 文本；
3. 存储过程统一走 ``call_borrow_book`` / ``call_return_book`` / ``call_renew_book``，
   它们负责消费过程产生的空结果集，并把"静默更新 0 行"翻译成明确的返回值。
"""

from typing import Any

import pymysql
from flask import Flask, g
from pymysql.connections import Connection
from pymysql.cursors import DictCursor

from config import DB_CONFIG


class DbError(Exception):
    """
    数据库访问失败时抛出的统一异常，路由层据此渲染错误页。

    *Return:
        无（异常对象）。
    """

    def __init__(self, message: str, code: int = 0) -> None:
        """
        *Args:
            message: 面向页面的中文说明，不包含原始 SQL 与参数值。
            code: MySQL 错误码（如 1054 未知列、1146 表不存在），无法确定时为 0。
        *Return:
            无。
        """
        super().__init__(message)
        self.message = message
        self.code = code


def _translate(exc: pymysql.err.MySQLError) -> DbError:
    """
    把驱动异常转换成带中文说明的 ``DbError``。

    *Args:
        exc: PyMySQL 抛出的异常，``args[0]`` 为错误码，末位为原始描述。
    *Return:
        待抛出的 ``DbError``；``1054`` 与 ``1146`` 换成针对 init.sql 的提示，
        其余保留原始描述，错误码一律保留。
    """
    code = int(exc.args[0]) if exc.args and isinstance(exc.args[0], int) else 0
    detail = str(exc.args[-1]) if exc.args else str(exc)
    if code == 1054:
        return DbError("数据库字段尚未就绪（未知列），需后端线补齐 04_init.sql。", code)
    if code == 1146:
        return DbError("数据表不存在，请先执行 src/backend/sql/04_init.sql。", code)
    if code in (2006, 2013):
        return DbError("数据库连接已断开，请检查网络或 Tailscale 是否掉线。", code)
    return DbError(f"数据库操作失败：{detail}", code)


def _connect() -> Connection:
    """
    按 ``config.DB_CONFIG`` 建立一个连接。

    *Args:
        无。
    *Return:
        已建立的 PyMySQL 连接；连接失败抛 ``DbError``（错误码 2003 表示无法连接）。
    """
    try:
        return pymysql.connect(**DB_CONFIG)  # type: ignore[arg-type]
    except pymysql.err.OperationalError as exc:
        code = int(exc.args[0]) if exc.args and isinstance(exc.args[0], int) else 0
        if code in (2003, 2013):
            # 2003 连不上、2013 握手中被断开：组长的库在 Tailscale 内网，
            # 最常见原因是 Tailscale 没登录，或者 Clash 把 100.64.0.0/10 也代理了。
            raise DbError(
                "无法连接数据库：请确认 Tailscale 已登录、Clash 等代理没有接管"
                " 100.64.0.0/10，以及账号密码正确。",
                2003,
            ) from exc
        raise DbError("无法连接数据库，请确认 MySQL 已启动且账号密码正确。", 2003) from exc
    except pymysql.err.MySQLError as exc:
        raise _translate(exc) from exc


def check_connection() -> None:
    """
    开一个连接再立刻关掉，用于启动时的连通性自检。

    *Args:
        无。
    *Return:
        无；连不上时抛 ``DbError``，由调用方决定是提示还是中断。
    """
    _connect().close()


def get_conn() -> Connection:
    """
    取当前请求的连接，没有则新建。

    *Args:
        无。
    *Return:
        当前请求复用的连接对象；同一请求内多次调用返回同一个连接。
    """
    if "db" not in g:
        g.db = _connect()
    return g.db


def close_db(exc: BaseException | None = None) -> None:
    """
    关闭当前请求的连接，由 Flask 在请求结束时调用。

    *Args:
        exc: Flask 传入的未处理异常（可能为 None），本函数不改变它。
    *Return:
        无。
    """
    conn: Connection | None = g.pop("db", None)
    if conn is not None:
        conn.close()


def init_app(app: Flask) -> None:
    """
    把连接的释放逻辑挂到 Flask 应用上。

    *Args:
        app: 当前 Flask 应用实例。
    *Return:
        无。
    """
    app.teardown_appcontext(close_db)


def query_all(sql: str, params: tuple[Any, ...] | None = None) -> list[dict[str, Any]]:
    """
    执行查询并取回全部行。

    *Args:
        sql: 参数化 SQL，占位符统一写作 ``%s``。
        params: 与占位符一一对应的参数元组；无参数时必须传 None，
            否则 PyMySQL 会对含 ``%Y`` 等字面量的 SQL 做 Python 格式化并报错。
    *Return:
        行字典列表，列名即字典键；没有命中时返回空列表（不是 None）。
    """
    conn = get_conn()
    try:
        with conn.cursor(DictCursor) as cursor:
            cursor.execute(sql, params)
            return list(cursor.fetchall())
    except pymysql.err.MySQLError as exc:
        raise _translate(exc) from exc


def query_one(sql: str, params: tuple[Any, ...] | None = None) -> dict[str, Any] | None:
    """
    执行查询并取回第一行。

    *Args:
        sql: 参数化 SQL，占位符统一写作 ``%s``。
        params: 与占位符一一对应的参数元组；无参数时传 None。
    *Return:
        第一行的字典；没有命中时返回 None，调用方必须显式判断。
    """
    rows = query_all(sql, params)
    return rows[0] if rows else None


def _drain(cursor: Any) -> None:
    """
    消费存储过程调用留下的结果集。

    *Args:
        cursor: 已经执行过 ``CALL`` 的游标。
    *Return:
        无。不消费的话，下一条语句会报 "Unread result found"。
    """
    while cursor.nextset():
        cursor.fetchall()


def call_borrow_book(reader_id: str, copy_id: str) -> int:
    """
    调用 ``borrow_book`` 借出一本图书。

    *Args:
        reader_id: 读者编号，对应 ``Reader.reader_id``。
        copy_id: 副本编号，对应 ``Copy.copy_id``，应在馆。
    *Return:
        存储过程返回码：0 成功；-1 副本不在馆；-2 读者被禁用；
        -3 已借满 5 本；-4 其他错误（过程内已回滚）。无法取值时按 -4 处理。
    """
    conn = get_conn()
    try:
        with conn.cursor(DictCursor) as cursor:
            cursor.execute("CALL borrow_book(%s, %s, @p_result)", (reader_id, copy_id))
            _drain(cursor)
            cursor.execute("SELECT @p_result AS result")
            row = cursor.fetchone()
    except pymysql.err.MySQLError as exc:
        raise _translate(exc) from exc
    if not row or row["result"] is None:
        return -4
    return int(row["result"])


def call_return_book(borrow_id: str, admin_id: str) -> bool:
    """
    调用 ``return_book`` 归还图书，并复查是否真的写入。

    *Args:
        borrow_id: 借阅编号，对应 ``Borrow.borrow_id``。
        admin_id: 经办管理员编号，来自登录会话。
    *Return:
        True 表示该记录已变为"已归还"；False 表示记录不存在或此前已归还
        （存储过程对这两种情况只更新 0 行、不报错）。
    """
    conn = get_conn()
    try:
        with conn.cursor(DictCursor) as cursor:
            cursor.execute("CALL return_book(%s, %s)", (borrow_id, admin_id))
            _drain(cursor)
            cursor.execute(
                "SELECT status, return_date FROM Borrow WHERE borrow_id = %s",
                (borrow_id,),
            )
            row = cursor.fetchone()
    except pymysql.err.MySQLError as exc:
        raise _translate(exc) from exc
    if not row:
        return False
    return row["status"] == "已归还" and row["return_date"] is not None


def call_renew_book(borrow_id: str) -> bool:
    """
    调用 ``renew_book`` 续借，并通过应还日期是否变化判断成功。

    *Args:
        borrow_id: 借阅编号，对应 ``Borrow.borrow_id``。
    *Return:
        True 表示续借成功（应还日期已顺延）；False 表示记录不存在或已归还。
    """
    conn = get_conn()
    try:
        with conn.cursor(DictCursor) as cursor:
            cursor.execute(
                "SELECT due_date FROM Borrow WHERE borrow_id = %s", (borrow_id,)
            )
            before = cursor.fetchone()
            if not before:
                return False
            cursor.execute("CALL renew_book(%s)", (borrow_id,))
            _drain(cursor)
            cursor.execute(
                "SELECT due_date, status FROM Borrow WHERE borrow_id = %s",
                (borrow_id,),
            )
            after = cursor.fetchone()
    except pymysql.err.MySQLError as exc:
        raise _translate(exc) from exc
    if not after or after["status"] != "在借":
        return False
    return after["due_date"] != before["due_date"]
