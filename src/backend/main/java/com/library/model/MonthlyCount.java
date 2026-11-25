package com.library.model;

/**
 * 每月借阅量的一行结果。
 */
public record MonthlyCount(String month, int borrowCount) {
}
