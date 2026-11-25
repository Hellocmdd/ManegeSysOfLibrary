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
 * 读者数据访问实现：只负责 SQL 执行与结果映射，不管理业务事务。
 */
public class ReaderDAOImpl implements ReaderDAO {

    @Override
    public List<Reader> findAll() throws SQLException {
        String sql = "SELECT reader_id, name, phone, status FROM reader ORDER BY reader_id";
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
    public Reader findById(int readerId) throws SQLException {
        String sql = "SELECT reader_id, name, phone, status FROM reader WHERE reader_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, readerId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    @Override
    public int insert(Reader reader) throws SQLException {
        String sql = "INSERT INTO reader (name, phone, status) VALUES (?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, reader.getName());
            ps.setString(2, reader.getPhone());
            ps.setString(3, reader.getStatus());
            return ps.executeUpdate();
        }
    }

    private Reader mapRow(ResultSet rs) throws SQLException {
        return new Reader(
                rs.getInt("reader_id"),
                rs.getString("name"),
                rs.getString("phone"),
                rs.getString("status"));
    }
}
