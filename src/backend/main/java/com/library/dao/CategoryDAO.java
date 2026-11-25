package com.library.dao;

import com.library.model.Category;

import java.sql.SQLException;
import java.util.List;

/**
 * 分类数据访问接口。
 */
public interface CategoryDAO {

    List<Category> findAll() throws SQLException;
}
