package com.library.dao;

import com.library.model.Reader;

import java.sql.SQLException;
import java.util.List;

/**
 * 读者数据访问接口；只做 SQL 执行与结果映射。
 */
public interface ReaderDAO {

    List<Reader> findAll() throws SQLException;

    Reader findById(String readerId) throws SQLException;
}
