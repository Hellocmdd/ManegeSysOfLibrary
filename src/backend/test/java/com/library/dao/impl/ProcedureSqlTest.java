package com.library.dao.impl;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 校验 Java 侧只按权威签名调用存储过程，且报表排序稳定。
 */
class ProcedureSqlTest {

    @Test
    void borrowProcedureKeepsOutParameter() {
        assertEquals("{CALL borrow_book(?, ?, ?)}", BorrowDAOImpl.BORROW_SQL);
        assertEquals(3, BorrowDAOImpl.BORROW_SQL.chars().filter(c -> c == '?').count());
    }

    @Test
    void returnProcedureKeepsTwoParameters() {
        assertEquals("{CALL return_book(?, ?)}", BorrowDAOImpl.RETURN_SQL);
    }

    @Test
    void renewProcedureKeepsOneParameter() {
        assertEquals("{CALL renew_book(?)}", BorrowDAOImpl.RENEW_SQL);
    }

    @Test
    void procedureCallsDoNotInterpolateValues() {
        assertFalse(BorrowDAOImpl.BORROW_SQL.contains("%s"));
        assertFalse(BorrowDAOImpl.RETURN_SQL.contains("+"));
        assertTrue(BorrowDAOImpl.BORROW_SQL.startsWith("{CALL "));
    }

    @Test
    void topBooksHasStableTieBreaker() {
        assertTrue(ReportDAOImpl.TOP_BOOKS_SQL.contains("ORDER BY borrow_count DESC, b.book_id"));
        assertTrue(ReportDAOImpl.TOP_BOOKS_SQL.contains("LIMIT ?"));
    }
}
