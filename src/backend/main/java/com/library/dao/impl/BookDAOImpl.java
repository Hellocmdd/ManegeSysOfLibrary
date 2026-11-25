package com.library.dao.impl;

import com.library.dao.BookDAO;
import com.library.model.BookSummary;
import com.library.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 书目查询实现：Book LEFT JOIN Category LEFT JOIN Copy，保留零副本的书目。
 */
public class BookDAOImpl implements BookDAO {

    static final String SEARCH_SQL_PREFIX =
            "SELECT b.book_id, b.isbn, b.title, b.author, b.publisher, c.cat_name, "
                    + "COUNT(cp.copy_id) AS copy_total, "
                    + "COALESCE(SUM(cp.is_available), 0) AS copy_available "
                    + "FROM Book b "
                    + "LEFT JOIN Category c ON c.cat_id = b.cat_id "
                    + "LEFT JOIN Copy cp ON cp.book_id = b.book_id ";

    @Override
    public List<BookSummary> search(String titleKeyword, String catId) throws SQLException {
        StringBuilder sql = new StringBuilder(SEARCH_SQL_PREFIX);
        List<Object> params = new ArrayList<>();
        boolean hasTitle = titleKeyword != null && !titleKeyword.isBlank();
        boolean hasCat = catId != null && !catId.isBlank();
        if (hasTitle || hasCat) {
            sql.append("WHERE ");
            List<String> conditions = new ArrayList<>();
            if (hasTitle) {
                conditions.add("b.title LIKE ?");
                params.add("%" + titleKeyword.trim() + "%");
            }
            if (hasCat) {
                conditions.add("b.cat_id = ?");
                params.add(catId.trim());
            }
            sql.append(String.join(" AND ", conditions)).append(' ');
        }
        sql.append("GROUP BY b.book_id, b.isbn, b.title, b.author, b.publisher, c.cat_name ")
                .append("ORDER BY b.book_id");

        List<BookSummary> books = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    books.add(new BookSummary(
                            rs.getString("book_id"),
                            rs.getString("isbn"),
                            rs.getString("title"),
                            rs.getString("author"),
                            rs.getString("publisher"),
                            rs.getString("cat_name"),
                            rs.getInt("copy_total"),
                            rs.getInt("copy_available")));
                }
            }
        }
        return books;
    }
}
