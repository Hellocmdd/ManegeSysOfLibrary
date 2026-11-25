-- 示例测试数据（最小种子）
-- 要求：最终每张核心表不少于 10 条记录，且关联数据满足参照完整性。

USE library_management;

INSERT INTO category (category_name, description) VALUES
    ('计算机', '计算机科学与技术类图书'),
    ('文学', '文学与小说类图书');

INSERT INTO reader (name, phone, status) VALUES
    ('张三', '13800000001', 'ACTIVE'),
    ('李四', '13800000002', 'ACTIVE');

INSERT INTO book (isbn, title, author, category_id, publish_year) VALUES
    ('9780000000001', '数据库系统概念', 'Silberschatz', 1, 2020),
    ('9780000000002', '围城', '钱钟书', 2, 1991);

INSERT INTO book_copy (book_id, barcode, location, status) VALUES
    (1, 'BCK-000001', 'A区-01', 'AVAILABLE'),
    (1, 'BCK-000002', 'A区-02', 'AVAILABLE'),
    (2, 'BCK-000003', 'B区-01', 'AVAILABLE');

INSERT INTO borrow_record (reader_id, copy_id, borrow_date, due_date, status) VALUES
    (1, 1, '2026-11-01', '2026-12-01', 'BORROWED');

INSERT INTO reservation (reader_id, book_id, reserve_date, status) VALUES
    (2, 2, '2026-11-20', 'PENDING');

-- TODO: 按任务书要求将 reader/book/book_copy/borrow_record/reservation/category 各补足至不少于 10 条。
