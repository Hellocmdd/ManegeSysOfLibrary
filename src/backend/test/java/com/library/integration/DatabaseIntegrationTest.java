package com.library.integration;

import com.library.util.DBUtil;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 真实 MySQL 集成测试。仅当 RUN_DB_INTEGRATION=1 时运行；
 * 执行前需按顺序跑完 04_init.sql、05_存储过程.sql、06_测试数据.sql。
 */
@EnabledIfEnvironmentVariable(named = "RUN_DB_INTEGRATION", matches = "1")
class DatabaseIntegrationTest {

    private static final String TEST_BORROW_ID = "BRTEST-RET";
    private static final String TEST_RENEW_ID = "BRTEST-REN";

    @BeforeEach
    void cleanBefore() throws SQLException {
        cleanup();
    }

    @AfterEach
    void cleanAfter() throws SQLException {
        cleanup();
    }

    @Test
    void baselineMatchesDocumentedCounts() throws SQLException {
        assertEquals(10, count("SELECT COUNT(*) FROM Admin"));
        assertEquals(11, count("SELECT COUNT(*) FROM Category"));
        assertEquals(10, count("SELECT COUNT(*) FROM Reader"));
        assertEquals(20, count("SELECT COUNT(*) FROM Book"));
        assertEquals(30, count("SELECT COUNT(*) FROM Copy"));
        assertEquals(15, count("SELECT COUNT(*) FROM Borrow"));
        assertEquals(2, count("SELECT COUNT(*) FROM Borrow "
                + "WHERE return_date IS NULL AND due_date < CURDATE()"));
        assertEquals(4, count("SELECT COUNT(*) FROM Borrow WHERE is_overdue = 1"));
    }

    @Test
    void borrowBookSuccessCreatesRecordAndOccupiesCopy() throws SQLException {
        int code = callBorrow("R006", "C023");
        assertEquals(0, code);

        assertEquals(1, count("SELECT COUNT(*) FROM Borrow "
                + "WHERE copy_id = 'C023' AND return_date IS NULL"));
        assertEquals(1, count("SELECT COUNT(*) FROM Copy "
                + "WHERE copy_id = 'C023' AND is_available = 0"));
        LocalDate dueDate = queryDate("SELECT due_date FROM Borrow "
                + "WHERE copy_id = 'C023' AND return_date IS NULL");
        LocalDate expected = LocalDate.now().plusDays(30);
        assertFalse(dueDate.isBefore(expected.minusDays(1)));
        assertFalse(dueDate.isAfter(expected.plusDays(1)));
    }

    @Test
    void borrowBookRejectsUnavailableCopyWithMinusOne() throws SQLException {
        assertEquals(-1, callBorrow("R006", "C004"));
        assertEquals(0, count("SELECT COUNT(*) FROM Copy "
                + "WHERE copy_id = 'C004' AND is_available = 1"));
    }

    @Test
    void borrowBookRejectsDisabledReaderWithMinusTwo() throws SQLException {
        assertEquals(-2, callBorrow("R009", "C003"));
        assertEquals(1, count("SELECT COUNT(*) FROM Copy "
                + "WHERE copy_id = 'C003' AND is_available = 1"));
    }

    @Test
    void borrowBookRollsBackWhenReaderHasFiveActiveLoans() throws SQLException {
        for (int i = 1; i <= 5; i++) {
            execute("INSERT INTO Borrow (borrow_id, reader_id, copy_id, borrow_date, due_date, "
                            + "return_date, status, is_overdue) "
                            + "VALUES (?, 'R010', ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), "
                            + "NULL, '在借', 0)",
                    "BRTEST-LIM-" + i, String.format("C%03d", 23 + i));
        }

        assertEquals(-3, callBorrow("R010", "C030"));
        assertEquals(0, count("SELECT COUNT(*) FROM Borrow "
                + "WHERE copy_id = 'C030' AND return_date IS NULL"));
        assertEquals(1, count("SELECT COUNT(*) FROM Copy "
                + "WHERE copy_id = 'C030' AND is_available = 1"));
    }

    @Test
    void returnBookIsIdempotentForAlreadyReturnedRecord() throws SQLException {
        seedBorrow(TEST_BORROW_ID, "R010", "C024", LocalDate.now().plusDays(10));

        callReturn(TEST_BORROW_ID, "AD001");
        assertEquals(1, count("SELECT COUNT(*) FROM Borrow "
                + "WHERE borrow_id = ? AND return_date IS NOT NULL AND status = '已归还' "
                + "AND admin_id = 'AD001'", TEST_BORROW_ID));
        assertEquals(1, count("SELECT COUNT(*) FROM Copy "
                + "WHERE copy_id = 'C024' AND is_available = 1"));
        Timestamp firstHandleTime = queryTimestamp(
                "SELECT handle_time FROM Borrow WHERE borrow_id = ?", TEST_BORROW_ID);
        assertNotNull(firstHandleTime);

        callReturn(TEST_BORROW_ID, "AD002");
        Timestamp secondHandleTime = queryTimestamp(
                "SELECT handle_time FROM Borrow WHERE borrow_id = ?", TEST_BORROW_ID);
        assertEquals(firstHandleTime, secondHandleTime);
        assertEquals(1, count("SELECT COUNT(*) FROM Copy "
                + "WHERE copy_id = 'C024' AND is_available = 1"));
    }

    @Test
    void renewBookAdvancesDueDateAndIgnoresReturnedRecord() throws SQLException {
        LocalDate oldDueDate = LocalDate.now().plusDays(10);
        seedBorrow(TEST_RENEW_ID, "R010", "C025", oldDueDate);

        callRenew(TEST_RENEW_ID);
        LocalDate renewed = queryDate("SELECT due_date FROM Borrow WHERE borrow_id = ?", TEST_RENEW_ID);
        assertFalse(renewed.isBefore(oldDueDate.plusDays(29)));
        assertFalse(renewed.isAfter(oldDueDate.plusDays(31)));
        assertEquals(1, count("SELECT COUNT(*) FROM Borrow "
                + "WHERE borrow_id = ? AND status = '在借'", TEST_RENEW_ID));

        LocalDate baselineDueDate = queryDate("SELECT due_date FROM Borrow WHERE borrow_id = 'BR002'");
        callRenew("BR002");
        assertEquals(baselineDueDate,
                queryDate("SELECT due_date FROM Borrow WHERE borrow_id = 'BR002'"));
    }

    private static void cleanup() throws SQLException {
        execute("DELETE FROM Borrow WHERE borrow_id IN (?, ?, 'BRTEST-LIM-1', 'BRTEST-LIM-2', "
                        + "'BRTEST-LIM-3', 'BRTEST-LIM-4', 'BRTEST-LIM-5')",
                TEST_BORROW_ID, TEST_RENEW_ID);
        execute("DELETE FROM Borrow WHERE copy_id = 'C023' AND return_date IS NULL");
        execute("UPDATE Copy SET is_available = 1 "
                + "WHERE copy_id IN ('C023', 'C024', 'C025', 'C026', 'C027', 'C028', 'C029', 'C030')");
    }

    private static void seedBorrow(String borrowId, String readerId, String copyId, LocalDate dueDate)
            throws SQLException {
        execute("INSERT INTO Borrow (borrow_id, reader_id, copy_id, borrow_date, due_date, "
                        + "return_date, status, is_overdue) "
                        + "VALUES (?, ?, ?, CURDATE(), ?, NULL, '在借', 0)",
                borrowId, readerId, copyId, Date.valueOf(dueDate));
    }

    private static int callBorrow(String readerId, String copyId) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             CallableStatement cs = conn.prepareCall("{CALL borrow_book(?, ?, ?)}")) {
            cs.setString(1, readerId);
            cs.setString(2, copyId);
            cs.registerOutParameter(3, Types.INTEGER);
            cs.execute();
            return cs.getInt(3);
        }
    }

    private static void callReturn(String borrowId, String adminId) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             CallableStatement cs = conn.prepareCall("{CALL return_book(?, ?)}")) {
            cs.setString(1, borrowId);
            cs.setString(2, adminId);
            cs.execute();
        }
    }

    private static void callRenew(String borrowId) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             CallableStatement cs = conn.prepareCall("{CALL renew_book(?)}")) {
            cs.setString(1, borrowId);
            cs.execute();
        }
    }

    private static int count(String sql, Object... params) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private static LocalDate queryDate(String sql, Object... params) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next(), "no row for query: " + sql);
                return rs.getDate(1).toLocalDate();
            }
        }
    }

    private static Timestamp queryTimestamp(String sql, Object... params) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next(), "no row for query: " + sql);
                return rs.getTimestamp(1);
            }
        }
    }

    private static void execute(String sql, Object... params) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            ps.executeUpdate();
        }
    }
}
