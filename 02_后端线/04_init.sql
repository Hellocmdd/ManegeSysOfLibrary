-- ====================================================================
-- 图书管理系统 · init.sql（建库建表）
-- 作者：谭博友
-- 数据库：MySQL 8.0 · InnoDB · utf8mb4
-- 依赖：请先看 02_关系模式.md 和 03_数据字典.xlsx（展博 11/28 交付）
-- 执行顺序：按文件顺序跑；如需清空重跑，先执行 DROP 再 CREATE
-- ====================================================================

-- 1. 设置字符集 + 外码检查（InnoDB 才支持外码）
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;   -- 开启外码约束

-- 2. 创建数据库
CREATE DATABASE IF NOT EXISTS library_system
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE library_system;

-- ====================================================================
-- TODO（谭博友）：以下 6 张表的字段、类型、约束请根据 03_数据字典.xlsx 填充
-- 目前只有表名和 PK/FK 骨架，类型占位为 VARCHAR(32)
-- ====================================================================

-- --- 表 1: Reader 读者 ---
CREATE TABLE Reader (
    reader_id  VARCHAR(32) NOT NULL,
    -- TODO 其他字段（姓名、性别、电话、邮箱、注册日期、状态）
    PRIMARY KEY (reader_id)
) ENGINE=InnoDB;

-- --- 表 2: Admin 管理员 ---
CREATE TABLE Admin (
    admin_id  VARCHAR(32) NOT NULL,
    -- TODO 其他字段（姓名、账号、密码、角色）
    PRIMARY KEY (admin_id),
    -- TODO: UNIQUE INDEX idx_account (account)
) ENGINE=InnoDB;

-- --- 表 3: Category 分类（支持多级） ---
CREATE TABLE Category (
    cat_id    VARCHAR(32) NOT NULL,
    -- TODO: cat_name, parent_id
    PRIMARY KEY (cat_id),
    -- TODO: FOREIGN KEY (parent_id) REFERENCES Category(cat_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- --- 表 4: Book 书籍 ---
CREATE TABLE Book (
    book_id   VARCHAR(32) NOT NULL,
    -- TODO: isbn, title, author, publisher, pub_date, descr, cat_id
    PRIMARY KEY (book_id),
    -- TODO: FOREIGN KEY (cat_id) REFERENCES Category(cat_id)
) ENGINE=InnoDB;

-- --- 表 5: Copy 书籍副本 ---
CREATE TABLE Copy (
    copy_id   VARCHAR(32) NOT NULL,
    -- TODO: book_id, asset_no, location, is_available
    PRIMARY KEY (copy_id),
    -- TODO: FOREIGN KEY (book_id) REFERENCES Book(book_id) ON DELETE CASCADE
    -- TODO: UNIQUE INDEX idx_asset_no (asset_no)
) ENGINE=InnoDB;

-- --- 表 6: Borrow 借阅记录 ---
CREATE TABLE Borrow (
    borrow_id VARCHAR(32) NOT NULL,
    -- TODO: reader_id, copy_id, borrow_date, due_date, return_date,
    --       status, is_overdue, admin_id, handle_time
    PRIMARY KEY (borrow_id),
    -- TODO: FOREIGN KEY (reader_id) REFERENCES Reader(reader_id)
    -- TODO: FOREIGN KEY (copy_id)   REFERENCES Copy(copy_id)
    -- TODO: FOREIGN KEY (admin_id)  REFERENCES Admin(admin_id) ON DELETE SET NULL
    -- TODO: INDEX idx_reader_date (reader_id, borrow_date)   -- 加快读者历史查询
    -- TODO: INDEX idx_copy_available (copy_id, return_date) -- 加快在馆判断
) ENGINE=InnoDB;

-- ====================================================================
-- 完成后：
-- 1. 跑一下 06_测试数据.sql 验证建表没问题
-- 2. 跑一下 05_存储过程.sql 验证存储过程能编译
-- 3. 提交给段绪礼，让他跑通后端
-- ====================================================================
