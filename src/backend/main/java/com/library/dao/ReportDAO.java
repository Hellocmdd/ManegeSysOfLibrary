package com.library.dao;

import com.library.model.BookRank;
import com.library.model.BorrowDetail;
import com.library.model.CategoryStat;
import com.library.model.MonthlyCount;

import java.sql.SQLException;
import java.util.List;

/**
 * 统计报表查询接口；口径与 db-contract 一致。
 */
public interface ReportDAO {

    List<BorrowDetail> findCurrentOverdue() throws SQLException;

    List<BookRank> findTopBooks(int limit) throws SQLException;

    List<CategoryStat> findCategoryStats() throws SQLException;

    List<MonthlyCount> findMonthlyBorrowCounts() throws SQLException;
}
