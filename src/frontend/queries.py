"""
查询层：把页面需要的 SQL 集中在这里，路由只负责取数与渲染。

约定：

1. 每条 SQL 都是参数化的，``%s`` 数量固定；``IN`` 列表按长度动态拼占位符，
   但拼进去的只有 ``%s``，不含任何用户数据；
2. 报表 SQL 必须带 ``ORDER BY``，避免同分数据换机器换页序；
3. 本模块的 SQL 与 ``09_查询样例.sql`` 保持一致，改这里就要同步改那里。
"""

from typing import Any

from db import query_all, query_one

# ---------------------------------------------------------------- 登录与基础数据

LOGIN_SQL = """
SELECT admin_id, name, role
FROM Admin
WHERE account = %s AND pwd = SHA2(%s, 256)
"""

CATEGORY_SQL = """
SELECT cat_id, cat_name, parent_id
FROM Category
ORDER BY COALESCE(parent_id, cat_id), cat_id
"""

READER_LIST_SQL = """
SELECT reader_id, name
FROM Reader
WHERE status = 1
ORDER BY reader_id
"""

READER_SQL = """
SELECT reader_id, name, sex, phone, email, reg_date, status
FROM Reader
WHERE reader_id = %s
"""

# ---------------------------------------------------------------- 书目列表

BOOK_COUNT_SQL = """
SELECT COUNT(*) AS total
FROM Book b
"""

BOOK_LIST_SQL = """
SELECT b.book_id, b.title, b.author, b.publisher, b.pub_date, b.isbn,
       c.cat_id, c.cat_name,
       COUNT(cp.copy_id) AS copy_total,
       COALESCE(SUM(cp.is_available), 0) AS copy_available
FROM Book b
LEFT JOIN Category c ON c.cat_id = b.cat_id
LEFT JOIN Copy cp ON cp.book_id = b.book_id
"""

BOOK_GROUP_BY_SQL = """
GROUP BY b.book_id, b.title, b.author, b.publisher, b.pub_date, b.isbn,
         c.cat_id, c.cat_name
"""

AVAILABLE_COPY_SQL = """
SELECT book_id, copy_id, location
FROM Copy
WHERE is_available = 1 AND book_id IN ({placeholders})
ORDER BY book_id, copy_id
"""

# ---------------------------------------------------------------- 借阅历史

BORROW_HISTORY_SQL = """
SELECT br.borrow_id, br.borrow_date, br.due_date, br.return_date,
       br.status, br.is_overdue,
       cp.copy_id, cp.asset_no,
       b.title, a.name AS admin_name
FROM Borrow br
JOIN Copy cp ON cp.copy_id = br.copy_id
JOIN Book b ON b.book_id = cp.book_id
LEFT JOIN Admin a ON a.admin_id = br.admin_id
WHERE br.reader_id = %s
ORDER BY br.borrow_date DESC, br.borrow_id DESC
"""

# ---------------------------------------------------------------- 统计报表

TOP_BOOK_SQL = """
SELECT b.book_id, b.title, COUNT(*) AS borrow_count
FROM Borrow br
JOIN Copy cp ON cp.copy_id = br.copy_id
JOIN Book b ON b.book_id = cp.book_id
GROUP BY b.book_id, b.title
ORDER BY borrow_count DESC, b.book_id
LIMIT 10
"""

CATEGORY_STOCK_SQL = """
SELECT c.cat_id, c.cat_name,
       COUNT(DISTINCT b.book_id) AS book_count,
       COUNT(cp.copy_id) AS copy_count
FROM Category c
LEFT JOIN Book b ON b.cat_id = c.cat_id
LEFT JOIN Copy cp ON cp.book_id = b.book_id
GROUP BY c.cat_id, c.cat_name
ORDER BY copy_count DESC, c.cat_id
"""

# 口径：只统计"当前仍未归还且已过期"，不含历史上有过逾期但已归还的记录。
OVERDUE_SQL = """
SELECT br.borrow_id, r.reader_id, r.name AS reader_name,
       b.title, br.due_date,
       DATEDIFF(CURDATE(), br.due_date) AS overdue_days
FROM Borrow br
JOIN Reader r ON r.reader_id = br.reader_id
JOIN Copy cp ON cp.copy_id = br.copy_id
JOIN Book b ON b.book_id = cp.book_id
WHERE br.return_date IS NULL AND br.due_date < CURDATE()
ORDER BY overdue_days DESC, br.borrow_id
"""

MONTHLY_SQL = """
SELECT DATE_FORMAT(br.borrow_date, '%Y-%m') AS month_label,
       COUNT(*) AS borrow_count
FROM Borrow br
GROUP BY DATE_FORMAT(br.borrow_date, '%Y-%m')
ORDER BY month_label
"""


def login_admin(account: str, password: str) -> dict[str, Any] | None:
    """
    校验管理员账号密码。

    *Args:
        account: 登录账号，对应 ``Admin.account``。
        password: 明文密码，仅在 SQL 里交给 MySQL 的 ``SHA2(..., 256)`` 比对。
    *Return:
        命中时返回 ``{"admin_id", "name", "role"}``；账号或密码错误返回 None。
    """
    return query_one(LOGIN_SQL, (account, password))


def list_categories() -> list[dict[str, Any]]:
    """
    取全部分类，父分类排在子分类前，用于筛选下拉框的两级缩进。

    *Args:
        无。
    *Return:
        字典列表，含 ``cat_id`` / ``cat_name`` / ``parent_id``，按父级聚拢排序。
    """
    return query_all(CATEGORY_SQL)


def list_readers() -> list[dict[str, Any]]:
    """
    取可以借书的读者（``status = 1``），用于借书表单的下拉框。

    *Args:
        无。
    *Return:
        字典列表，含 ``reader_id`` / ``name``，按编号升序。
    """
    return query_all(READER_LIST_SQL)


def get_reader(reader_id: str) -> dict[str, Any] | None:
    """
    取一位读者的档案。

    *Args:
        reader_id: 读者编号，对应 ``Reader.reader_id``。
    *Return:
        命中时返回读者字典；编号不存在返回 None。
    """
    return query_one(READER_SQL, (reader_id,))


def _book_filters(title_kw: str, cat_id: str | None) -> tuple[str, list[Any]]:
    """
    拼书目列表的 WHERE 片段。

    *Args:
        title_kw: 书名关键字，空串表示不筛选；通配符由本函数加在参数值里。
        cat_id: 分类编号，None 或空串表示不筛选。
    *Return:
        ``(where_sql, params)``；where_sql 只含 ``%s`` 与固定列名，不含用户数据。
    """
    clauses: list[str] = []
    params: list[Any] = []
    if title_kw:
        clauses.append("b.title LIKE %s")
        params.append(f"%{title_kw}%")
    if cat_id:
        clauses.append("b.cat_id = %s")
        params.append(cat_id)
    if not clauses:
        return "", params
    return "WHERE " + " AND ".join(clauses), params


def count_books(title_kw: str, cat_id: str | None) -> int:
    """
    统计当前筛选条件下的书目条数，用于分页。

    *Args:
        title_kw: 书名关键字，空串表示不筛选。
        cat_id: 分类编号，None 或空串表示不筛选。
    *Return:
        命中条数；无结果时为 0。
    """
    where_sql, params = _book_filters(title_kw, cat_id)
    row = query_one(BOOK_COUNT_SQL + where_sql, tuple(params))
    return int(row["total"]) if row else 0


def list_books(
    title_kw: str, cat_id: str | None, page: int, page_size: int
) -> list[dict[str, Any]]:
    """
    取一页书目，附带馆藏与可借数量。

    *Args:
        title_kw: 书名关键字，空串表示不筛选。
        cat_id: 分类编号，None 表示不筛选。
        page: 页码，从 1 开始。
        page_size: 每页条数，由 ``config.PAGE_SIZE`` 提供。
    *Return:
        字典列表，含 ``copy_total``（馆藏总数）与 ``copy_available``（可借数）；
        越界页返回空列表。
    """
    where_sql, params = _book_filters(title_kw, cat_id)
    sql = (
        BOOK_LIST_SQL
        + where_sql
        + BOOK_GROUP_BY_SQL
        + " ORDER BY b.book_id LIMIT %s OFFSET %s"
    )
    offset = max(page - 1, 0) * page_size
    return query_all(sql, tuple([*params, page_size, offset]))


def available_copies(book_ids: list[str]) -> dict[str, list[dict[str, Any]]]:
    """
    批量取一页书目中每本书的在馆副本，避免逐行查询。

    *Args:
        book_ids: 当前页的 ``book_id`` 列表，为空时直接返回空字典。
    *Return:
        ``{book_id: [{"copy_id", "location"}, ...]}``；没有在馆副本的书不出现在字典里。
    """
    if not book_ids:
        return {}
    placeholders = ", ".join(["%s"] * len(book_ids))
    sql = AVAILABLE_COPY_SQL.format(placeholders=placeholders)
    rows = query_all(sql, tuple(book_ids))
    grouped: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        grouped.setdefault(str(row["book_id"]), []).append(
            {"copy_id": row["copy_id"], "location": row["location"]}
        )
    return grouped


def borrow_history(reader_id: str) -> list[dict[str, Any]]:
    """
    取一位读者的全部借阅记录。

    *Args:
        reader_id: 读者编号，对应 ``Borrow.reader_id``。
    *Return:
        字典列表，按借出日期倒序；含书名、副本条码、经办管理员名，未归还时
        ``return_date`` 为 None。
    """
    return query_all(BORROW_HISTORY_SQL, (reader_id,))


def top_books() -> list[dict[str, Any]]:
    """
    借阅次数前 10 的书。

    *Args:
        无。
    *Return:
        字典列表，含 ``title`` 与 ``borrow_count``，按次数降序、同次数按书名升序。
    """
    return query_all(TOP_BOOK_SQL)


def category_stock() -> list[dict[str, Any]]:
    """
    各分类的书目数与馆藏副本数（不含子分类汇总，父行只统计挂在本级的书）。

    *Args:
        无。
    *Return:
        字典列表，含 ``cat_name`` / ``book_count`` / ``copy_count``，按分类编号升序。
    """
    return query_all(CATEGORY_STOCK_SQL)


def overdue_borrows() -> list[dict[str, Any]]:
    """
    当前逾期未还清单。

    *Args:
        无。
    *Return:
        字典列表，含读者、书名、应还日期与 ``overdue_days``（已逾期天数），
        按逾期天数降序。
    """
    return query_all(OVERDUE_SQL)


def monthly_borrows() -> list[dict[str, Any]]:
    """
    按月统计借阅量。

    *Args:
        无。
    *Return:
        字典列表，含 ``month_label``（``YYYY-MM``）与 ``borrow_count``，按月升序。
    """
    return query_all(MONTHLY_SQL)
