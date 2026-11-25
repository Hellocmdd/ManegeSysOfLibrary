-- ====================================================================
-- 图书管理系统 · Java/JDBC 配套查询脚本
-- 定位：六张表、字段名、状态枚举与 src/backend/sql/04_init.sql 完全一致。
-- 要求：所有查询按 ORDER BY 输出确定性结果；状态/逾期口径见 .agent/conventions/db-contract.md。
-- ====================================================================

SET NAMES utf8mb4;
USE storageoflibrarysys;

-- 1. 单表条件查询：状态正常的读者
SELECT reader_id, name, sex, phone, email, reg_date, status
  FROM Reader
 WHERE status = 1
 ORDER BY reader_id;

-- 2. 单表条件查询：当前在馆可借的副本（按书目分组展示）
SELECT b.book_id, b.title, cp.copy_id, cp.asset_no, cp.location
  FROM Book b
  JOIN Copy cp ON cp.book_id = b.book_id
 WHERE cp.is_available = 1
 ORDER BY b.book_id, cp.copy_id;

-- 3. 多表关联查询：借阅详情（借阅 + 读者 + 副本 + 书目 + 经办管理员）
SELECT br.borrow_id, r.name AS reader_name, b.title, cp.asset_no,
       br.borrow_date, br.due_date, br.return_date, br.status,
       a.name AS admin_name
  FROM Borrow br
  JOIN Reader r   ON r.reader_id = br.reader_id
  JOIN Copy cp    ON cp.copy_id = br.copy_id
  JOIN Book b     ON b.book_id = cp.book_id
  LEFT JOIN Admin a ON a.admin_id = br.admin_id
 ORDER BY br.borrow_date DESC, br.borrow_id;

-- 4. 多表关联查询：所有读者及其借阅记录（含无借阅读者，左连接）
SELECT r.reader_id, r.name, br.borrow_id, br.status AS borrow_status,
       br.borrow_date, br.due_date
  FROM Reader r
  LEFT JOIN Borrow br ON br.reader_id = r.reader_id
 ORDER BY r.reader_id, br.borrow_date DESC, br.borrow_id;

-- 5. 分组统计：各分类馆藏量（空分类显示 0，不含子分类汇总）
SELECT c.cat_id, c.cat_name,
       COUNT(DISTINCT b.book_id) AS book_count,
       COUNT(cp.copy_id)         AS copy_count
  FROM Category c
  LEFT JOIN Book b     ON b.cat_id = c.cat_id
  LEFT JOIN Copy cp    ON cp.book_id = b.book_id
 GROUP BY c.cat_id, c.cat_name
 ORDER BY copy_count DESC, c.cat_id;

-- 6. 嵌套查询（IN）：借阅过计算机类图书的读者
SELECT reader_id, name
  FROM Reader
 WHERE reader_id IN (
     SELECT br.reader_id
       FROM Borrow br
       JOIN Copy cp ON cp.copy_id = br.copy_id
       JOIN Book b  ON b.book_id = cp.book_id
       JOIN Category c ON c.cat_id = b.cat_id
      WHERE c.cat_name LIKE '%计算机%'
 )
 ORDER BY reader_id;

-- 7. 嵌套查询（EXISTS）：当前有逾期未还记录的读者
SELECT r.reader_id, r.name
  FROM Reader r
 WHERE EXISTS (
     SELECT 1
       FROM Borrow br
      WHERE br.reader_id = r.reader_id
        AND br.return_date IS NULL
        AND br.due_date < CURDATE()
 )
 ORDER BY r.reader_id;

-- 8. 复杂业务查询：热门图书 TOP10（并列时追加 book_id 保证稳定）
SELECT b.book_id, b.title, COUNT(br.borrow_id) AS borrow_count
  FROM Book b
  JOIN Copy cp ON cp.book_id = b.book_id
  LEFT JOIN Borrow br ON br.copy_id = cp.copy_id
 GROUP BY b.book_id, b.title
 ORDER BY borrow_count DESC, b.book_id
 LIMIT 10;

-- 9. 分组统计：每月借阅量（分组与排序使用同一表达式）
SELECT DATE_FORMAT(borrow_date, '%Y-%m') AS month_label,
       COUNT(*) AS borrow_count
  FROM Borrow
 GROUP BY DATE_FORMAT(borrow_date, '%Y-%m')
 ORDER BY DATE_FORMAT(borrow_date, '%Y-%m');

-- 10. 报表口径：当前逾期清单（return_date IS NULL 且已过应还日）
SELECT br.borrow_id, r.name AS reader_name, b.title, cp.asset_no,
       br.due_date, DATEDIFF(CURDATE(), br.due_date) AS overdue_days
  FROM Borrow br
  JOIN Reader r ON r.reader_id = br.reader_id
  JOIN Copy cp  ON cp.copy_id = br.copy_id
  JOIN Book b   ON b.book_id = cp.book_id
 WHERE br.return_date IS NULL
   AND br.due_date < CURDATE()
 ORDER BY overdue_days DESC, br.borrow_id;

-- 11. 一致性自检：同一副本是否出现多条未归还借阅（正常应为 0 行）
SELECT copy_id, COUNT(*) AS active_borrow_count
  FROM Borrow
 WHERE return_date IS NULL
 GROUP BY copy_id
HAVING COUNT(*) > 1
 ORDER BY copy_id;
