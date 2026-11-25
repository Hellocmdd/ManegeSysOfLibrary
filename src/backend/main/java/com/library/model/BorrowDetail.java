package com.library.model;

import java.time.LocalDate;

/**
 * 借阅详情视图：Borrow + Reader + Copy + Book + Admin。
 */
public record BorrowDetail(
        String borrowId,
        String readerName,
        String title,
        String assetNo,
        LocalDate borrowDate,
        LocalDate dueDate,
        LocalDate returnDate,
        String status,
        int isOverdue,
        String adminName) {
}
