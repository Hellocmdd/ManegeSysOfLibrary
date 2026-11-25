package com.library.model;

import java.time.LocalDate;

/**
 * Reader 表对应的读者实体（reader_id 为 VARCHAR 主键）。
 */
public record Reader(
        String readerId,
        String name,
        String sex,
        String phone,
        String email,
        LocalDate regDate,
        int status) {
}
