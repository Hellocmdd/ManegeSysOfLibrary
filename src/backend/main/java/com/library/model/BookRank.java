package com.library.model;

/**
 * 热门图书 TOP10 的一行结果。
 */
public record BookRank(String bookId, String title, int borrowCount) {
}
