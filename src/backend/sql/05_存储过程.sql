-- ====================================================================
-- 图书管理系统 · 存储过程
-- 作者：谭博友
-- 依赖：先执行 04_init.sql 建表
-- ====================================================================

USE storageoflibrarysys;

-- --------------------------------------------------------------------
-- 存储过程 1：borrow_book —— 读者借书
-- 输入：p_reader_id 读者编号, p_copy_id 副本编号
-- 输出：返回码（0=成功, -1=副本不在馆, -2=读者已禁用, -3=读者已借满, -4=其他错误）
-- 关键点：用事务保证 ① Copy.is_available=0 和 ② 新建 Borrow 记录 原子性
-- --------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE borrow_book(
    IN  p_reader_id VARCHAR(32),
    IN  p_copy_id   VARCHAR(32),
    OUT p_result    INT
)
BEGIN
    DECLARE v_reader_status INT DEFAULT -1;
    DECLARE v_is_available  INT DEFAULT -1;
    DECLARE v_borrow_count  INT DEFAULT 0;
    DECLARE v_due_date      DATE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = -4;
    END;

    START TRANSACTION;

    -- ① 校验账户状态
    SELECT status INTO v_reader_status FROM Reader WHERE reader_id = p_reader_id;
    IF v_reader_status <> 1 THEN
        SET p_result = -2;
        ROLLBACK;
    ELSE
        -- ② 校验副本在馆
        SELECT is_available INTO v_is_available FROM Copy WHERE copy_id = p_copy_id;
        IF v_is_available <> 1 THEN
            SET p_result = -1;
            ROLLBACK;
        ELSE
            -- ③ 校验读者当前未归还借阅数（上限 5）
            SELECT COUNT(*) INTO v_borrow_count
              FROM Borrow
             WHERE reader_id = p_reader_id AND return_date IS NULL;
            IF v_borrow_count >= 5 THEN
                SET p_result = -3;
                ROLLBACK;
            ELSE
                -- ④ 计算应还日期（借出日 + 30 天）
                SET v_due_date = DATE_ADD(CURDATE(), INTERVAL 30 DAY);

                -- ⑤ 新建借阅记录
                INSERT INTO Borrow(borrow_id, reader_id, copy_id, borrow_date,
                                   due_date, status, is_overdue)
                VALUES (CONCAT('BR_', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'),
                               FLOOR(RAND()*1000)),
                        p_reader_id, p_copy_id, CURDATE(),
                        v_due_date, '在借', 0);

                -- ⑥ 更新副本为不在馆
                UPDATE Copy SET is_available = 0 WHERE copy_id = p_copy_id;

                SET p_result = 0;
                COMMIT;
            END IF;
        END IF;
    END IF;
END //
DELIMITER ;


-- --------------------------------------------------------------------
-- 存储过程 2：return_book —— 归还
-- 输入：p_borrow_id 借阅记录编号, p_admin_id 处理管理员编号
-- --------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE return_book(
    IN p_borrow_id VARCHAR(32),
    IN p_admin_id  VARCHAR(32)
)
BEGIN
    DECLARE v_copy_id VARCHAR(32) DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; END;

    START TRANSACTION;

    -- ① 查出这条借阅对应的副本
    SELECT copy_id INTO v_copy_id FROM Borrow WHERE borrow_id = p_borrow_id;

    -- ② 更新借阅记录（标记已归还）
    UPDATE Borrow
       SET return_date = CURDATE(),
           status     = '已归还',
           admin_id   = p_admin_id,
           handle_time= NOW(),
           is_overdue = (due_date < CURDATE())   -- 归还时顺便标记是否逾期
     WHERE borrow_id = p_borrow_id;

    -- ③ 副本放回书架
    UPDATE Copy SET is_available = 1 WHERE copy_id = v_copy_id;

    COMMIT;
END //
DELIMITER ;


-- --------------------------------------------------------------------
-- 存储过程 3：renew_book —— 续借（延长应还日期 30 天，仅一次）
-- 输入：p_borrow_id 借阅记录编号
-- --------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE renew_book(
    IN p_borrow_id VARCHAR(32)
)
BEGIN
    -- 直接延长 due_date 30 天即可
    -- 注：如果业务要求每本只能续一次，需要在表里加一个 renewed 标记字段
    UPDATE Borrow
       SET due_date  = DATE_ADD(due_date, INTERVAL 30 DAY),
           status    = '在借',
           is_overdue= 0
     WHERE borrow_id = p_borrow_id
       AND return_date IS NULL;   -- 只能续未归还的
END //
DELIMITER ;
