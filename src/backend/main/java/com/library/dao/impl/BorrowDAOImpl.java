package com.library.dao.impl;

import com.library.dao.BorrowDAO;
import com.library.model.BorrowDetail;
import com.library.model.BorrowOutcome;
import com.library.util.DBUtil;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * 借阅数据访问实现：借/还/续只调用权威存储过程，不在 Java 里重写业务 SQL。
 */
public class BorrowDAOImpl implements BorrowDAO {

    static final String BORROW_SQL = "{CALL borrow_book(?, ?, ?)}";
    static final String RETURN_SQL = "{CALL return_book(?, ?)}";
    static final String RENEW_SQL = "{CALL renew_book(?)}";

    private static final String DETAIL_COLUMNS =
            "br.borrow_id, r.name AS reader_name, b.title, cp.asset_no, "
                    + "br.borrow_date, br.due_date, br.return_date, br.status, br.is_overdue, "
                    + "a.name AS admin_name ";
    private static final String DETAIL_FROM =
            "FROM Borrow br "
                    + "JOIN Reader r ON r.reader_id = br.reader_id "
                    + "JOIN Copy cp ON cp.copy_id = br.copy_id "
                    + "JOIN Book b ON b.book_id = cp.book_id "
                    + "LEFT JOIN Admin a ON a.admin_id = br.admin_id ";

    @Override
    public BorrowOutcome borrow(String readerId, String copyId) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             CallableStatement cs = conn.prepareCall(BORROW_SQL)) {
            cs.setString(1, readerId);
            cs.setString(2, copyId);
            cs.registerOutParameter(3, Types.INTEGER);
            cs.execute();
            return BorrowOutcome.fromCode(cs.getInt(3));
        }
    }

    @Override
    public boolean returnBook(String borrowId, String adminId) throws SQLException {
        try (Connection conn = DBUtil.getConnection();
             CallableStatement cs = conn.prepareCall(RETURN_SQL)) {
            cs.setString(1, borrowId);
            cs.setString(2, adminId);
            cs.execute();
        }
        BorrowDetail after = findById(borrowId);
        return after != null && after.returnDate() != null && "已归还".equals(after.status());
    }

    @Override
    public boolean renewBook(String borrowId) throws SQLException {
        BorrowDetail before = findById(borrowId);
        if (before == null || before.returnDate() != null) {
            return false;
        }
        try (Connection conn = DBUtil.getConnection();
             CallableStatement cs = conn.prepareCall(RENEW_SQL)) {
            cs.setString(1, borrowId);
            cs.execute();
        }
        BorrowDetail after = findById(borrowId);
        return after != null && after.dueDate().isAfter(before.dueDate())
                && "在借".equals(after.status());
    }

    @Override
    public BorrowDetail findById(String borrowId) throws SQLException {
        String sql = "SELECT " + DETAIL_COLUMNS + DETAIL_FROM
                + "WHERE br.borrow_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, borrowId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    @Override
    public List<BorrowDetail> findHistoryByReader(String readerId) throws SQLException {
        String sql = "SELECT " + DETAIL_COLUMNS + DETAIL_FROM
                + "WHERE br.reader_id = ? "
                + "ORDER BY br.borrow_date DESC, br.borrow_id";
        List<BorrowDetail> details = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, readerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    details.add(mapRow(rs));
                }
            }
        }
        return details;
    }

    private static LocalDate toLocalDate(ResultSet rs, String column) throws SQLException {
        Date date = rs.getDate(column);
        return date == null ? null : date.toLocalDate();
    }

    private static BorrowDetail mapRow(ResultSet rs) throws SQLException {
        return new BorrowDetail(
                rs.getString("borrow_id"),
                rs.getString("reader_name"),
                rs.getString("title"),
                rs.getString("asset_no"),
                toLocalDate(rs, "borrow_date"),
                toLocalDate(rs, "due_date"),
                toLocalDate(rs, "return_date"),
                rs.getString("status"),
                rs.getInt("is_overdue"),
                rs.getString("admin_name"));
    }
}
