package com.library.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * borrow_book 返回码映射的单元测试（不需要数据库）。
 */
class BorrowOutcomeTest {

    @Test
    void zeroMeansSuccess() {
        BorrowOutcome outcome = BorrowOutcome.fromCode(0);
        assertTrue(outcome.success());
        assertTrue(outcome.message().contains("借书成功"));
    }

    @Test
    void minusOneMeansCopyUnavailable() {
        BorrowOutcome outcome = BorrowOutcome.fromCode(-1);
        assertFalse(outcome.success());
        assertTrue(outcome.message().contains("不在馆"));
    }

    @Test
    void minusTwoMeansReaderDisabled() {
        BorrowOutcome outcome = BorrowOutcome.fromCode(-2);
        assertFalse(outcome.success());
        assertTrue(outcome.message().contains("禁用"));
    }

    @Test
    void minusThreeMeansBorrowLimit() {
        BorrowOutcome outcome = BorrowOutcome.fromCode(-3);
        assertFalse(outcome.success());
        assertTrue(outcome.message().contains("5 本"));
    }

    @Test
    void minusFourMeansRolledBack() {
        BorrowOutcome outcome = BorrowOutcome.fromCode(-4);
        assertFalse(outcome.success());
        assertTrue(outcome.message().contains("回滚"));
    }

    @Test
    void unknownCodeIsNotSuccess() {
        BorrowOutcome outcome = BorrowOutcome.fromCode(99);
        assertFalse(outcome.success());
        assertTrue(outcome.message().contains("未知返回码"));
    }
}
