package com.library.model;

import java.time.LocalDate;

/**
 * Book 表对应的书目实体；一本书对应多条 Copy。
 */
public record Book(
        String bookId,
        String isbn,
        String title,
        String author,
        String publisher,
        LocalDate pubDate,
        String descr,
        String catId) {
}
