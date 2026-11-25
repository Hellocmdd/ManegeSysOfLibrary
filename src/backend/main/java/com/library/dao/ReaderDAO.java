package com.library.dao;

import com.library.model.Reader;

import java.sql.SQLException;
import java.util.List;

/**
 * 读者数据访问接口。
 */
public interface ReaderDAO {

    List<Reader> findAll() throws SQLException;

    Reader findById(int readerId) throws SQLException;

    int insert(Reader reader) throws SQLException;
}
