package com.library.model;

/**
 * Copy 表对应的馆藏副本实体；isAvailable 为 1 在馆 / 0 借出。
 */
public record Copy(
        String copyId,
        String bookId,
        String assetNo,
        String location,
        int isAvailable) {
}
