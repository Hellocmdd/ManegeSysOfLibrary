package com.library.model;

/**
 * 书目查询视图：Book + Category + Copy 汇总。
 */
public record BookSummary(
        String bookId,
        String isbn,
        String title,
        String author,
        String publisher,
        String catName,
        int copyTotal,
        int copyAvailable) {
}
