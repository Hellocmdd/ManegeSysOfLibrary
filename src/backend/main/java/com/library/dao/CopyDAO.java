package com.library.dao;

import com.library.model.Copy;

import java.sql.SQLException;
import java.util.List;

/**
 * 副本数据访问接口。
 */
public interface CopyDAO {

    List<Copy> findAvailableByBook(String bookId) throws SQLException;
}
