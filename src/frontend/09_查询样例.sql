-- =============================================================
-- 09_查询样例.sql —— 前端页面用到的 SQL 与统计报表查询
-- 与 queries.py 中的常量一一对应；改这里要同步改 queries.py。
-- 数据库：library_system（MySQL 8.0，InnoDB）
-- =============================================================

USE library_system;

-- -------------------------------------------------------------
-- 1. 管理员登录校验（密码以 SHA256 存储，明文只在参数里出现）
-- -------------------------------------------------------------
SELECT admin_id, name, role
FROM Admin
WHERE account = 'admin' AND pwd = SHA2('123456', 256);

-- -------------------------------------------------------------
-- 2. 书目列表：附带馆藏总数与可借数（LEFT JOIN 保证零副本的书也显示）
-- -------------------------------------------------------------
SELECT b.book_id, b.title, b.author, b.publisher, b.pub_date, b.isbn,
       c.cat_id, c.cat_name,
       COUNT(cp.copy_id)         AS copy_total,
       SUM(cp.is_available)      AS copy_available
FROM Book b
LEFT JOIN Category c ON c.cat_id = b.cat_id
LEFT JOIN Copy cp ON cp.book_id = b.book_id
GROUP BY b.book_id, b.title, b.author, b.publisher, b.pub_date, b.isbn,
         c.cat_id, c.cat_name
ORDER BY b.book_id;

-- 2.1 按书名模糊 + 分类筛选（前端把 % 放在参数值里，不拼进 SQL）
SELECT b.book_id, b.title, COUNT(cp.copy_id) AS copy_total
FROM Book b
LEFT JOIN Copy cp ON cp.book_id = b.book_id
WHERE b.title LIKE '%数据库%' AND b.cat_id = 'CAT0101'
GROUP BY b.book_id, b.title
ORDER BY b.book_id;

-- 2.2 当前页可借副本（先取到 book_id 列表，再用 IN 一次查完，避免逐行查询）
SELECT book_id, copy_id, location
FROM Copy
WHERE is_available = 1 AND book_id IN ('B001', 'B002', 'B003')
ORDER BY book_id, copy_id;

-- -------------------------------------------------------------
-- 3. 读者借阅历史（含书名、副本条码、经办管理员）
-- -------------------------------------------------------------
SELECT br.borrow_id, br.borrow_date, br.due_date, br.return_date,
       br.status, br.is_overdue,
       cp.copy_id, cp.asset_no,
       b.title, a.name AS admin_name
FROM Borrow br
JOIN Copy cp ON cp.copy_id = br.copy_id
JOIN Book b ON b.book_id = cp.book_id
LEFT JOIN Admin a ON a.admin_id = br.admin_id
WHERE br.reader_id = 'R001'
ORDER BY br.borrow_date DESC, br.borrow_id DESC;

-- -------------------------------------------------------------
-- 4. 报表一：借阅次数 TOP 10（含已归还记录）
-- -------------------------------------------------------------
SELECT b.book_id, b.title, COUNT(*) AS borrow_count
FROM Borrow br
JOIN Copy cp ON cp.copy_id = br.copy_id
JOIN Book b ON b.book_id = cp.book_id
GROUP BY b.book_id, b.title
ORDER BY borrow_count DESC, b.title
LIMIT 10;

-- -------------------------------------------------------------
-- 5. 报表二：各分类书目数与馆藏副本数
-- 口径：只统计挂在本分类下的书，父分类不含子分类汇总
-- -------------------------------------------------------------
SELECT c.cat_id, c.cat_name,
       COUNT(DISTINCT b.book_id) AS book_count,
       COUNT(cp.copy_id)         AS copy_count
FROM Category c
LEFT JOIN Book b ON b.cat_id = c.cat_id
LEFT JOIN Copy cp ON cp.book_id = b.book_id
GROUP BY c.cat_id, c.cat_name
ORDER BY c.cat_id;

-- -------------------------------------------------------------
-- 6. 报表三：当前逾期清单
-- 口径：只统计"尚未归还且已过应还日期"，不含已归还的历史逾期
-- -------------------------------------------------------------
SELECT br.borrow_id, r.reader_id, r.name AS reader_name,
       b.title, br.due_date,
       DATEDIFF(CURDATE(), br.due_date) AS overdue_days
FROM Borrow br
JOIN Reader r ON r.reader_id = br.reader_id
JOIN Copy cp ON cp.copy_id = br.copy_id
JOIN Book b ON b.book_id = cp.book_id
WHERE br.return_date IS NULL AND br.due_date < CURDATE()
ORDER BY overdue_days DESC, br.borrow_id;

-- 对照：若只按 is_overdue = 1 过滤，会把已归还的历史逾期也算进来
SELECT borrow_id, status, return_date
FROM Borrow
WHERE is_overdue = 1;

-- -------------------------------------------------------------
-- 7. 报表四：每月借阅量
-- -------------------------------------------------------------
SELECT DATE_FORMAT(br.borrow_date, '%Y-%m') AS month_label,
       COUNT(*) AS borrow_count
FROM Borrow br
GROUP BY DATE_FORMAT(br.borrow_date, '%Y-%m')
ORDER BY month_label;

-- -------------------------------------------------------------
-- 8. 借还续借：前端调用存储过程的写法（注意 borrow_book 有 OUT 参数）
-- -------------------------------------------------------------
-- 借书：0 成功 / -1 不在馆 / -2 读者禁用 / -3 已借满 5 本 / -4 其他错误
CALL borrow_book('R001', 'C005', @p_result);
SELECT @p_result;

-- 还书：无返回码，前端以 Borrow.status 是否变为"已归还"为准
CALL return_book('BR001', 'A001');

-- 续借：无返回码，应还日期顺延 30 天，前端以 due_date 是否变化为准
CALL renew_book('BR004');

-- -------------------------------------------------------------
-- 9. 数据自检（演示前跑一遍，确认反范式字段与主数据一致）
-- -------------------------------------------------------------
-- 9.1 在借记录数应不超过 5
SELECT reader_id, COUNT(*) AS current_borrows
FROM Borrow
WHERE return_date IS NULL
GROUP BY reader_id
ORDER BY current_borrows DESC;

-- 9.2 在借记录对应的副本必须标记为"已借出"（is_available = 0）
SELECT br.borrow_id, cp.copy_id, cp.is_available
FROM Borrow br
JOIN Copy cp ON cp.copy_id = br.copy_id
WHERE br.return_date IS NULL AND cp.is_available <> 0;

-- 9.3 已归还记录对应的副本必须标记为"在馆"（is_available = 1）
SELECT br.borrow_id, cp.copy_id, cp.is_available
FROM Borrow br
JOIN Copy cp ON cp.copy_id = br.copy_id
WHERE br.return_date IS NOT NULL AND cp.is_available <> 1;
