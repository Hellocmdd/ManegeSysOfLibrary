package com.library.dao.impl;

import com.library.dao.ReaderDAO;
import com.library.model.Reader;
import com.library.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 读者数据访问实现：显式列名、参数化查询，不管理业务事务。
 */
public class ReaderDAOImpl implements ReaderDAO {

    private static final String SELECT_COLUMNS =
            "reader_id, name, sex, phone, email, reg_date, status";

    @Override
    public List<Reader> findAll() throws SQLException {
        String sql = "SELECT " + SELECT_COLUMNS + " FROM Reader ORDER BY reader_id";
        List<Reader> readers = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                readers.add(mapRow(rs));
            }
        }
        return readers;
    }

    @Override
    public Reader findById(String readerId) throws SQLException {
        String sql = "SELECT " + SELECT_COLUMNS + " FROM Reader WHERE reader_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, readerId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    private Reader mapRow(ResultSet rs) throws SQLException {
        return new Reader(
                rs.getString("reader_id"),
                rs.getString("name"),
                rs.getString("sex"),
                rs.getString("phone"),
                rs.getString("email"),
                rs.getDate("reg_date").toLocalDate(),
                rs.getInt("status"));
    }
}
