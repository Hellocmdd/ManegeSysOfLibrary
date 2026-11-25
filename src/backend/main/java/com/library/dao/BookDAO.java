package com.library.dao;

import com.library.model.BookSummary;

import java.sql.SQLException;
import java.util.List;

/**
 * 书目查询接口；返回带副本数量的汇总视图。
 */
public interface BookDAO {

    List<BookSummary> search(String titleKeyword, String catId) throws SQLException;
}
