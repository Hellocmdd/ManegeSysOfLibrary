package com.library.service;

import com.library.dao.ReportDAO;
import com.library.dao.impl.ReportDAOImpl;
import com.library.model.BookRank;
import com.library.model.BorrowDetail;
import com.library.model.CategoryStat;
import com.library.model.MonthlyCount;

import java.sql.SQLException;
import java.util.List;

/**
 * 四张统计报表服务；报表口径在 ReportDAO 的 SQL 中固定。
 */
public class ReportService {

    private static final int TOP_LIMIT = 10;

    private final ReportDAO reportDAO;

    public ReportService() {
        this(new ReportDAOImpl());
    }

    ReportService(ReportDAO reportDAO) {
        this.reportDAO = reportDAO;
    }

    public List<BorrowDetail> currentOverdue() {
        try {
            return reportDAO.findCurrentOverdue();
        } catch (SQLException e) {
            throw new ServiceException("查询当前逾期清单失败：" + e.getMessage(), e);
        }
    }

    public List<BookRank> topBooks() {
        try {
            return reportDAO.findTopBooks(TOP_LIMIT);
        } catch (SQLException e) {
            throw new ServiceException("查询热门图书失败：" + e.getMessage(), e);
        }
    }

    public List<CategoryStat> categoryStats() {
        try {
            return reportDAO.findCategoryStats();
        } catch (SQLException e) {
            throw new ServiceException("查询分类馆藏量失败：" + e.getMessage(), e);
        }
    }

    public List<MonthlyCount> monthlyBorrowCounts() {
        try {
            return reportDAO.findMonthlyBorrowCounts();
        } catch (SQLException e) {
            throw new ServiceException("查询每月借阅量失败：" + e.getMessage(), e);
        }
    }
}
