package com.library.service;

import com.library.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Logger;

/**
 * 借阅业务服务：事务边界位于 Service 层。
 */
public class BorrowService {

    private static final Logger LOG = Logger.getLogger(BorrowService.class.getName());

    /**
     * 执行借书事务：校验读者状态、占用副本、写入借阅记录。
     *
     * @return 成功返回 true；校验失败或异常回滚后返回 false
     */
    public boolean borrowBook(int readerId, int copyId) {
        Connection conn = null;
        boolean oldAutoCommit = false;
        try {
            conn = DBUtil.getConnection();
            oldAutoCommit = conn.getAutoCommit();
            conn.setAutoCommit(false);

            if (!isReaderActive(conn, readerId)) {
                conn.rollback();
                return false;
            }

            String updateCopy = "UPDATE book_copy SET status = 'BORROWED' "
                    + "WHERE copy_id = ? AND status = 'AVAILABLE'";
            try (PreparedStatement ps = conn.prepareStatement(updateCopy)) {
                ps.setInt(1, copyId);
                if (ps.executeUpdate() != 1) {
                    conn.rollback();
                    return false;
                }
            }

            String insertRecord = "INSERT INTO borrow_record "
                    + "(reader_id, copy_id, borrow_date, due_date, status) "
                    + "VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'BORROWED')";
            try (PreparedStatement ps = conn.prepareStatement(insertRecord)) {
                ps.setInt(1, readerId);
                ps.setInt(2, copyId);
                ps.executeUpdate();
            }

            conn.commit();
            return true;
        } catch (SQLException e) {
            LOG.severe("借阅事务失败: " + e.getMessage());
            rollbackQuietly(conn);
            return false;
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(oldAutoCommit);
                } catch (SQLException e) {
                    LOG.warning("恢复 autoCommit 失败: " + e.getMessage());
                }
                DBUtil.close(conn);
            }
        }
    }

    private boolean isReaderActive(Connection conn, int readerId) throws SQLException {
        String sql = "SELECT status FROM reader WHERE reader_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, readerId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && "ACTIVE".equals(rs.getString("status"));
            }
        }
    }

    private void rollbackQuietly(Connection conn) {
        if (conn == null) {
            return;
        }
        try {
            conn.rollback();
        } catch (SQLException e) {
            LOG.severe("事务回滚失败: " + e.getMessage());
        }
    }
}
