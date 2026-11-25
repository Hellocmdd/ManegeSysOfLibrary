package com.library.dao.impl;

import com.library.dao.CategoryDAO;
import com.library.model.Category;
import com.library.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 分类数据访问实现。
 */
public class CategoryDAOImpl implements CategoryDAO {

    @Override
    public List<Category> findAll() throws SQLException {
        String sql = "SELECT cat_id, cat_name, parent_id FROM Category ORDER BY cat_id";
        List<Category> categories = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                categories.add(new Category(
                        rs.getString("cat_id"),
                        rs.getString("cat_name"),
                        rs.getString("parent_id")));
            }
        }
        return categories;
    }
}
