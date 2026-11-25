package com.library.dao.impl;

import com.library.dao.CopyDAO;
import com.library.model.Copy;
import com.library.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 副本查询实现。
 */
public class CopyDAOImpl implements CopyDAO {

    @Override
    public List<Copy> findAvailableByBook(String bookId) throws SQLException {
        String sql = "SELECT copy_id, book_id, asset_no, location, is_available "
                + "FROM Copy WHERE book_id = ? AND is_available = 1 ORDER BY copy_id";
        List<Copy> copies = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    copies.add(new Copy(
                            rs.getString("copy_id"),
                            rs.getString("book_id"),
                            rs.getString("asset_no"),
                            rs.getString("location"),
                            rs.getInt("is_available")));
                }
            }
        }
        return copies;
    }
}
