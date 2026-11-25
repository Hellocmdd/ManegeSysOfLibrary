-- 图书管理系统建库建表脚本
-- 目标：远程 MySQL 9.7.2，引擎 InnoDB，字符集 utf8mb4
-- 注意：执行前请确认账号具备 CREATE DATABASE 权限。

CREATE DATABASE IF NOT EXISTS storageoflibrarysys
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE storageoflibrarysys;

CREATE TABLE IF NOT EXISTS reader (
    reader_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name        VARCHAR(50)  NOT NULL,
    phone       VARCHAR(20)  NOT NULL,
    status      ENUM('ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (reader_id),
    UNIQUE KEY uk_reader_phone (phone)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS category (
    category_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50)  NOT NULL,
    description   VARCHAR(200) DEFAULT NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uk_category_name (category_name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS book (
    book_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    isbn          VARCHAR(32)  NOT NULL,
    title         VARCHAR(200) NOT NULL,
    author        VARCHAR(100) NOT NULL,
    category_id   INT UNSIGNED NOT NULL,
    publish_year  SMALLINT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (book_id),
    UNIQUE KEY uk_book_isbn (isbn),
    KEY idx_book_category (category_id),
    KEY idx_book_title (title),
    CONSTRAINT fk_book_category FOREIGN KEY (category_id)
        REFERENCES category (category_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS book_copy (
    copy_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    book_id   INT UNSIGNED NOT NULL,
    barcode   VARCHAR(64)  NOT NULL,
    location  VARCHAR(50)  NOT NULL,
    status    ENUM('AVAILABLE', 'BORROWED', 'RESERVED', 'LOST') NOT NULL DEFAULT 'AVAILABLE',
    PRIMARY KEY (copy_id),
    UNIQUE KEY uk_copy_barcode (barcode),
    KEY idx_copy_book (book_id),
    KEY idx_copy_status (status),
    CONSTRAINT fk_copy_book FOREIGN KEY (book_id)
        REFERENCES book (book_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS borrow_record (
    borrow_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    reader_id   INT UNSIGNED NOT NULL,
    copy_id     INT UNSIGNED NOT NULL,
    borrow_date DATE         NOT NULL,
    due_date    DATE         NOT NULL,
    return_date DATE         DEFAULT NULL,
    status      ENUM('BORROWED', 'RETURNED', 'OVERDUE') NOT NULL DEFAULT 'BORROWED',
    PRIMARY KEY (borrow_id),
    KEY idx_borrow_reader (reader_id),
    KEY idx_borrow_copy (copy_id),
    KEY idx_borrow_status (status),
    CONSTRAINT chk_borrow_dates CHECK (due_date >= borrow_date),
    CONSTRAINT fk_borrow_reader FOREIGN KEY (reader_id)
        REFERENCES reader (reader_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_borrow_copy FOREIGN KEY (copy_id)
        REFERENCES book_copy (copy_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reservation (
    reservation_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    reader_id      INT UNSIGNED NOT NULL,
    book_id        INT UNSIGNED NOT NULL,
    reserve_date   DATE         NOT NULL,
    status         ENUM('PENDING', 'FULFILLED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    PRIMARY KEY (reservation_id),
    KEY idx_reservation_reader (reader_id),
    KEY idx_reservation_book (book_id),
    CONSTRAINT fk_reservation_reader FOREIGN KEY (reader_id)
        REFERENCES reader (reader_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id)
        REFERENCES book (book_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
