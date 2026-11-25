-- ====================================================================
-- 图书管理系统 · init.sql（建库建表）
-- 作者：谭博友 / 张展博（字段类型按 03_数据字典.xlsx 填充）
-- 数据库：MySQL 8.0 · InnoDB · utf8mb4
-- 执行顺序：按文件顺序跑
--   source 04_init.sql;      ← 本文件
--   source 05_存储过程.sql;
--   source 06_测试数据.sql;
-- ====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;

DROP DATABASE IF EXISTS library_system;
CREATE DATABASE library_system
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE library_system;

-- ====================================================================
-- 表 1: Reader 读者
-- ====================================================================
CREATE TABLE Reader (
    reader_id  VARCHAR(32)  NOT NULL  COMMENT '读者编号，唯一主键，如 R001',
    name       VARCHAR(50)  NOT NULL  COMMENT '真实姓名',
    sex        ENUM('男','女') NOT NULL DEFAULT '男' COMMENT '性别',
    phone      VARCHAR(20)  YES       DEFAULT NULL COMMENT '联系电话',
    email      VARCHAR(100) YES       DEFAULT NULL COMMENT '邮箱',
    reg_date   DATE         NOT NULL  COMMENT '注册日期',
    status     TINYINT(1)   NOT NULL  DEFAULT 1 COMMENT '账户状态：1正常/0禁用',
    PRIMARY KEY (reader_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='读者表';

-- ====================================================================
-- 表 2: Admin 管理员（公司职员）
-- ====================================================================
CREATE TABLE Admin (
    admin_id  VARCHAR(32)  NOT NULL  COMMENT '管理员编号，唯一主键',
    name      VARCHAR(50)  NOT NULL  COMMENT '真实姓名',
    account   VARCHAR(50)  NOT NULL  COMMENT '登录账号',
    pwd       VARCHAR(255) NOT NULL  COMMENT '密码，SHA256 哈希存储（绝对禁止明文）',
    role      ENUM('普通','超级') NOT NULL DEFAULT '普通' COMMENT '角色',
    PRIMARY KEY (admin_id),
    UNIQUE INDEX idx_admin_account (account)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员表';

-- ====================================================================
-- 表 3: Category 分类（支持多级父子关系）
-- ====================================================================
CREATE TABLE Category (
    cat_id    VARCHAR(32)  NOT NULL  COMMENT '分类编号',
    cat_name  VARCHAR(50)  NOT NULL  COMMENT '分类名称，如 计算机',
    parent_id VARCHAR(32)  YES       DEFAULT NULL COMMENT '父分类编号，根节点为 NULL（自引用外码）',
    PRIMARY KEY (cat_id),
    INDEX idx_parent_id (parent_id),
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_id)
        REFERENCES Category(cat_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分类表（支持多级）';

-- ====================================================================
-- 表 4: Book 书籍（书名等共享信息，不含副本）
-- ====================================================================
CREATE TABLE Book (
    book_id   VARCHAR(32)  NOT NULL  COMMENT '书籍编号',
    isbn      VARCHAR(20)  YES       DEFAULT NULL COMMENT 'ISBN 国际标准书号',
    title     VARCHAR(200) NOT NULL  COMMENT '书名',
    author    VARCHAR(100) YES       DEFAULT NULL COMMENT '作者，可多作者逗号分隔',
    publisher VARCHAR(100) YES       DEFAULT NULL COMMENT '出版社',
    pub_date  DATE         YES       DEFAULT NULL COMMENT '出版日期',
    descr     TEXT         YES       DEFAULT NULL COMMENT '简介/目录，长文本',
    cat_id    VARCHAR(32)  YES       DEFAULT NULL COMMENT '所属分类编号 → Category.cat_id',
    PRIMARY KEY (book_id),
    INDEX idx_book_title (title),
    INDEX idx_book_cat   (cat_id),
    CONSTRAINT fk_book_category FOREIGN KEY (cat_id)
        REFERENCES Category(cat_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='书籍表（不含副本）';

-- ====================================================================
-- 表 5: Copy 书籍副本（实际借还的对象）
-- ====================================================================
CREATE TABLE Copy (
    copy_id       VARCHAR(32) NOT NULL  COMMENT '副本编号',
    book_id       VARCHAR(32) NOT NULL  COMMENT '所属书籍编号 → Book.book_id',
    asset_no      VARCHAR(32) NOT NULL  COMMENT '馆藏编号，贴在书脊上的标签号',
    location      VARCHAR(100) YES       DEFAULT NULL COMMENT '存放位置，如 二楼A区-01架',
    is_available  TINYINT(1)  NOT NULL  DEFAULT 1 COMMENT '是否在馆：1在馆/0借出（应用层+事务维护）',
    PRIMARY KEY (copy_id),
    UNIQUE INDEX idx_copy_asset_no (asset_no),
    INDEX idx_copy_book_id  (book_id),
    CONSTRAINT fk_copy_book FOREIGN KEY (book_id)
        REFERENCES Book(book_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='书籍副本表';

-- ====================================================================
-- 表 6: Borrow 借阅记录
-- ====================================================================
CREATE TABLE Borrow (
    borrow_id   VARCHAR(32) NOT NULL  COMMENT '借阅记录编号',
    reader_id   VARCHAR(32) NOT NULL  COMMENT '读者编号 → Reader.reader_id',
    copy_id     VARCHAR(32) NOT NULL  COMMENT '借出的副本编号 → Copy.copy_id',
    borrow_date DATE        NOT NULL  COMMENT '借出日期',
    due_date    DATE        NOT NULL  COMMENT '应还日期（借出+30天）',
    return_date DATE        YES       DEFAULT NULL COMMENT '实际归还日期，NULL=尚未归还',
    status      VARCHAR(10) NOT NULL  COMMENT '状态：在借/已归还/已逾期（冗余，方便前端筛选）',
    is_overdue  TINYINT(1)  NOT NULL  DEFAULT 0 COMMENT '是否逾期：1逾期/0未逾期（冗余，触发器每日维护）',
    admin_id    VARCHAR(32) YES       DEFAULT NULL COMMENT '处理归还的管理员编号，NULL=尚未归还',
    handle_time DATETIME    YES       DEFAULT NULL COMMENT '处理时间（管理员处理归还时刻）',
    PRIMARY KEY (borrow_id),
    INDEX idx_borrow_reader_date (reader_id, borrow_date DESC),  -- 读者历史借阅
    INDEX idx_borrow_copy        (copy_id, return_date),        -- 副本在馆判断
    INDEX idx_borrow_status      (status),                      -- 按状态筛选
    CONSTRAINT fk_borrow_reader FOREIGN KEY (reader_id)
        REFERENCES Reader(reader_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_borrow_copy FOREIGN KEY (copy_id)
        REFERENCES Copy(copy_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_borrow_admin FOREIGN KEY (admin_id)
        REFERENCES Admin(admin_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='借阅记录表';

-- ====================================================================
-- 执行验证
-- ====================================================================
SELECT '建库完成！当前共有 ' AS info, COUNT(*) AS table_count
  FROM information_schema.tables
 WHERE table_schema = DATABASE();
