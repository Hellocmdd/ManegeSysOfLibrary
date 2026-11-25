package com.library.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Borrow 表对应的借阅记录实体；状态使用中文原值。
 */
public record Borrow(
        String borrowId,
        String readerId,
        String copyId,
        LocalDate borrowDate,
        LocalDate dueDate,
        LocalDate returnDate,
        String status,
        int isOverdue,
        String adminId,
        LocalDateTime handleTime) {
}
