-- 查询脚本：覆盖课程任务书要求的 8 类查询
-- 所有查询必须在远程 MySQL 9.7.2 中实际执行并核验结果。

USE storageoflibrarysys;

-- 1. 单表条件查询：查询状态正常的读者
SELECT reader_id, name, phone, status
FROM reader
WHERE status = 'ACTIVE'
ORDER BY reader_id;

-- 2. 单表条件查询：查询 2020 年以后出版的图书
SELECT book_id, title, author, publish_year
FROM book
WHERE publish_year >= 2020
ORDER BY publish_year DESC;

-- 3. 多表关联查询：借阅详情（借阅记录 + 读者 + 副本 + 书目）
SELECT br.borrow_id, r.name AS reader_name, b.title, bc.barcode,
       br.borrow_date, br.due_date, br.status
FROM borrow_record br
INNER JOIN reader r ON r.reader_id = br.reader_id
INNER JOIN book_copy bc ON bc.copy_id = br.copy_id
INNER JOIN book b ON b.book_id = bc.book_id
ORDER BY br.borrow_date DESC;

-- 4. 多表关联查询：列出所有读者及其借阅情况（含无借阅读者）
SELECT r.reader_id, r.name, br.borrow_id, br.status AS borrow_status
FROM reader r
LEFT JOIN borrow_record br ON br.reader_id = r.reader_id
ORDER BY r.reader_id;

-- 5. 分组统计查询：各分类馆藏副本数量
SELECT c.category_name, COUNT(bc.copy_id) AS copy_count
FROM category c
LEFT JOIN book b ON b.category_id = c.category_id
LEFT JOIN book_copy bc ON bc.book_id = b.book_id
GROUP BY c.category_id, c.category_name
ORDER BY copy_count DESC;

-- 6. 嵌套查询（IN）：查询借阅过计算机类图书的读者
SELECT DISTINCT r.reader_id, r.name
FROM reader r
WHERE r.reader_id IN (
    SELECT br.reader_id
    FROM borrow_record br
    INNER JOIN book_copy bc ON bc.copy_id = br.copy_id
    INNER JOIN book b ON b.book_id = bc.book_id
    INNER JOIN category c ON c.category_id = b.category_id
    WHERE c.category_name = '计算机'
);

-- 7. 嵌套查询（EXISTS）：查询存在逾期记录的读者
SELECT r.reader_id, r.name
FROM reader r
WHERE EXISTS (
    SELECT 1
    FROM borrow_record br
    WHERE br.reader_id = r.reader_id
      AND br.status = 'OVERDUE'
);

-- 8. 复杂业务查询：热门图书 TOP10（按借阅次数统计）
SELECT b.book_id, b.title, COUNT(br.borrow_id) AS borrow_count
FROM book b
INNER JOIN book_copy bc ON bc.book_id = b.book_id
LEFT JOIN borrow_record br ON br.copy_id = bc.copy_id
GROUP BY b.book_id, b.title
ORDER BY borrow_count DESC
LIMIT 10;
