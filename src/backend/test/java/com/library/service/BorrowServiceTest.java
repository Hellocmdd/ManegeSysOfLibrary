package com.library.service;

import com.library.dao.BorrowDAO;
import com.library.model.BorrowDetail;
import com.library.model.BorrowOutcome;
import org.junit.jupiter.api.Test;

import java.sql.SQLException;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 借阅服务单元测试：用假 DAO 验证结果透传与异常转换，不依赖真实数据库。
 */
class BorrowServiceTest {

    @Test
    void borrowPassesOutcomeThrough() {
        BorrowOutcome expected = BorrowOutcome.fromCode(-3);
        FakeBorrowDAO dao = new FakeBorrowDAO();
        dao.borrowOutcome = expected;

        assertEquals(expected, new BorrowService(dao).borrow("R001", "C001"));
    }

    @Test
    void borrowWrapsSqlException() {
        FakeBorrowDAO dao = new FakeBorrowDAO();
        dao.failure = new SQLException("connection lost");

        ServiceException ex = assertThrows(ServiceException.class,
                () -> new BorrowService(dao).borrow("R001", "C001"));
        assertTrue(ex.getMessage().contains("借书调用失败"));
    }

    @Test
    void returnBookTreatsSilentZeroRowsAsFailure() {
        FakeBorrowDAO dao = new FakeBorrowDAO();
        dao.returnResult = false;

        assertFalse(new BorrowService(dao).returnBook("BR001", "AD001"));
    }

    @Test
    void renewBookReturnsTrueWhenDueDateMoved() {
        FakeBorrowDAO dao = new FakeBorrowDAO();
        dao.renewResult = true;

        assertTrue(new BorrowService(dao).renewBook("BR001"));
    }

    @Test
    void historyWrapsSqlException() {
        FakeBorrowDAO dao = new FakeBorrowDAO();
        dao.failure = new SQLException("query failed");

        ServiceException ex = assertThrows(ServiceException.class,
                () -> new BorrowService(dao).history("R001"));
        assertTrue(ex.getMessage().contains("查询借阅历史失败"));
    }

    private static class FakeBorrowDAO implements BorrowDAO {

        private BorrowOutcome borrowOutcome;
        private boolean returnResult;
        private boolean renewResult;
        private SQLException failure;

        @Override
        public BorrowOutcome borrow(String readerId, String copyId) throws SQLException {
            if (failure != null) {
                throw failure;
            }
            return borrowOutcome;
        }

        @Override
        public boolean returnBook(String borrowId, String adminId) throws SQLException {
            if (failure != null) {
                throw failure;
            }
            return returnResult;
        }

        @Override
        public boolean renewBook(String borrowId) throws SQLException {
            if (failure != null) {
                throw failure;
            }
            return renewResult;
        }

        @Override
        public BorrowDetail findById(String borrowId) throws SQLException {
            if (failure != null) {
                throw failure;
            }
            return null;
        }

        @Override
        public List<BorrowDetail> findHistoryByReader(String readerId) throws SQLException {
            if (failure != null) {
                throw failure;
            }
            return List.of();
        }
    }
}
