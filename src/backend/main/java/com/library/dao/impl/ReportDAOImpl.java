package com.library.dao.impl;

import com.library.dao.ReportDAO;
import com.library.model.BookRank;
import com.library.model.BorrowDetail;
import com.library.model.CategoryStat;
import com.library.model.MonthlyCount;
import com.library.util.DBUtil;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * 统计报表查询实现：口径与 .agent/conventions/db-contract.md 一致。
 */
public class ReportDAOImpl implements ReportDAO {

    static final String TOP_BOOKS_SQL =
            "SELECT b.book_id, b.title, COUNT(br.borrow_id) AS borrow_count "
                    + "FROM Book b "
                    + "JOIN Copy cp ON cp.book_id = b.book_id "
                    + "LEFT JOIN Borrow br ON br.copy_id = cp.copy_id "
                    + "GROUP BY b.book_id, b.title "
                    + "ORDER BY borrow_count DESC, b.book_id "
                    + "LIMIT ?";

    @Override
    public List<BorrowDetail> findCurrentOverdue() throws SQLException {
        String sql = "SELECT br.borrow_id, r.name AS reader_name, b.title, cp.asset_no, "
                + "br.borrow_date, br.due_date, br.return_date, br.status, br.is_overdue, "
                + "a.name AS admin_name "
                + "FROM Borrow br "
                + "JOIN Reader r ON r.reader_id = br.reader_id "
                + "JOIN Copy cp ON cp.copy_id = br.copy_id "
                + "JOIN Book b ON b.book_id = cp.book_id "
                + "LEFT JOIN Admin a ON a.admin_id = br.admin_id "
                + "WHERE br.return_date IS NULL AND br.due_date < CURDATE() "
                + "ORDER BY br.due_date, br.borrow_id";
        List<BorrowDetail> rows = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(new BorrowDetail(
                        rs.getString("borrow_id"),
                        rs.getString("reader_name"),
                        rs.getString("title"),
                        rs.getString("asset_no"),
                        localDate(rs, "borrow_date"),
                        localDate(rs, "due_date"),
                        localDate(rs, "return_date"),
                        rs.getString("status"),
                        rs.getInt("is_overdue"),
                        rs.getString("admin_name")));
            }
        }
        return rows;
    }

    @Override
    public List<BookRank> findTopBooks(int limit) throws SQLException {
        List<BookRank> rows = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(TOP_BOOKS_SQL)) {
            ps.setInt(1, Math.max(1, limit));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(new BookRank(
                            rs.getString("book_id"),
                            rs.getString("title"),
                            rs.getInt("borrow_count")));
                }
            }
        }
        return rows;
    }

    @Override
    public List<CategoryStat> findCategoryStats() throws SQLException {
        String sql = "SELECT c.cat_id, c.cat_name, "
                + "COUNT(DISTINCT b.book_id) AS book_count, "
                + "COUNT(cp.copy_id) AS copy_count "
                + "FROM Category c "
                + "LEFT JOIN Book b ON b.cat_id = c.cat_id "
                + "LEFT JOIN Copy cp ON cp.book_id = b.book_id "
                + "GROUP BY c.cat_id, c.cat_name "
                + "ORDER BY copy_count DESC, c.cat_id";
        List<CategoryStat> rows = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(new CategoryStat(
                        rs.getString("cat_id"),
                        rs.getString("cat_name"),
                        rs.getInt("book_count"),
                        rs.getInt("copy_count")));
            }
        }
        return rows;
    }

    @Override
    public List<MonthlyCount> findMonthlyBorrowCounts() throws SQLException {
        String sql = "SELECT DATE_FORMAT(borrow_date, '%Y-%m') AS month_label, "
                + "COUNT(*) AS borrow_count "
                + "FROM Borrow "
                + "GROUP BY DATE_FORMAT(borrow_date, '%Y-%m') "
                + "ORDER BY DATE_FORMAT(borrow_date, '%Y-%m')";
        List<MonthlyCount> rows = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(new MonthlyCount(rs.getString("month_label"), rs.getInt("borrow_count")));
            }
        }
        return rows;
    }

    private static LocalDate localDate(ResultSet rs, String column) throws SQLException {
        Date date = rs.getDate(column);
        return date == null ? null : date.toLocalDate();
    }
}
