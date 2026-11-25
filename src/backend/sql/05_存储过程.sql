-- ====================================================================
-- 图书管理系统 · 存储过程
-- 作者：谭博友
-- 依赖：先执行 04_init.sql 建表
-- 注意：借/还/续借的业务规则以本文件为准；Java 侧只做封装调用。
-- ====================================================================

SET NAMES utf8mb4;
USE storageoflibrarysys;

-- --------------------------------------------------------------------
-- 存储过程 1：borrow_book —— 读者借书
-- 输入：p_reader_id 读者编号, p_copy_id 副本编号
-- 输出：返回码（0=成功, -1=副本不存在或不在馆, -2=读者不存在或被禁用,
--             -3=读者已借满 5 本, -4=其他错误，过程内已 ROLLBACK）
-- 关键点：用事务 + 行锁保证 ① 读者状态/在借数校验 ② Copy.is_available=0
--         ③ 新建 Borrow 记录 三者原子且并发安全。
-- --------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE borrow_book(
    IN  p_reader_id VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN  p_copy_id   VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
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

    -- ① 校验读者状态（行锁，避免并发禁用与借书交叉）
    SELECT status INTO v_reader_status
      FROM Reader
     WHERE reader_id = p_reader_id
       FOR UPDATE;
    IF v_reader_status <> 1 THEN
        SET p_result = -2;
        ROLLBACK;
    ELSE
        -- ② 校验副本在馆（行锁，避免两个读者同时借同一副本）
        SELECT is_available INTO v_is_available
          FROM Copy
         WHERE copy_id = p_copy_id
           FOR UPDATE;
        IF v_is_available <> 1 THEN
            SET p_result = -1;
            ROLLBACK;
        ELSE
            -- ③ 校验读者当前未归还借阅数（上限 5）
            SELECT COUNT(*) INTO v_borrow_count
              FROM Borrow
             WHERE reader_id = p_reader_id
               AND return_date IS NULL;
            IF v_borrow_count >= 5 THEN
                SET p_result = -3;
                ROLLBACK;
            ELSE
                -- ④ 计算应还日期（借出日 + 30 天）
                SET v_due_date = DATE_ADD(CURDATE(), INTERVAL 30 DAY);

                -- ⑤ 新建借阅记录（UUID 去横线后截取，32 位内且并发不碰撞）
                INSERT INTO Borrow(borrow_id, reader_id, copy_id, borrow_date,
                                   due_date, status, is_overdue)
                VALUES (CONCAT('BR', SUBSTRING(REPLACE(UUID(), '-', ''), 1, 30)),
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
-- 说明：无返回码。记录不存在或已归还时更新 0 行，且不会误置副本状态；
--       调用方应复查 status / return_date 后再提示成功。
-- --------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE return_book(
    IN p_borrow_id VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN p_admin_id  VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
    DECLARE v_copy_id VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL;
    DECLARE v_rows    INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_copy_id = NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- ① 锁定仍未归还的借阅记录；已归还/不存在的记录不会取到副本
    SELECT copy_id INTO v_copy_id
      FROM Borrow
     WHERE borrow_id = p_borrow_id
       AND return_date IS NULL
       FOR UPDATE;

    -- ② 更新借阅记录（标记已归还）
    UPDATE Borrow
       SET return_date = CURDATE(),
           status      = '已归还',
           admin_id    = p_admin_id,
           handle_time = NOW(),
           is_overdue  = (due_date < CURDATE())   -- 归还时记录当时是否超期
     WHERE borrow_id = p_borrow_id
       AND return_date IS NULL;
    SET v_rows = ROW_COUNT();

    -- ③ 仅当本过程真的归还了记录，才把副本放回书架
    IF v_rows = 1 AND v_copy_id IS NOT NULL THEN
        UPDATE Copy SET is_available = 1 WHERE copy_id = v_copy_id;
    END IF;

    COMMIT;
END //
DELIMITER ;


-- --------------------------------------------------------------------
-- 存储过程 3：renew_book —— 续借（应还日期顺延 30 天）
-- 输入：p_borrow_id 借阅记录编号
-- 说明：无返回码。仅对 return_date IS NULL 的记录生效；
--       当前表结构没有"续借次数"字段，因此不限制续借次数。
-- --------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE renew_book(
    IN p_borrow_id VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
    DECLARE v_borrow_id VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_borrow_id = NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- 锁定仍未归还的借阅记录，避免并发续借互相覆盖
    SELECT borrow_id INTO v_borrow_id
      FROM Borrow
     WHERE borrow_id = p_borrow_id
       AND return_date IS NULL
       FOR UPDATE;

    IF v_borrow_id IS NOT NULL THEN
        UPDATE Borrow
           SET due_date   = DATE_ADD(due_date, INTERVAL 30 DAY),
               status     = '在借',
               is_overdue = 0
         WHERE borrow_id = p_borrow_id
           AND return_date IS NULL;
    END IF;

    COMMIT;
END //
DELIMITER ;
