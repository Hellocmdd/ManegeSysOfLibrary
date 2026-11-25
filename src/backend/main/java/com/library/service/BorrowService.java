package com.library.service;

import com.library.dao.BorrowDAO;
import com.library.dao.impl.BorrowDAOImpl;
import com.library.model.BorrowDetail;
import com.library.model.BorrowOutcome;

import java.sql.SQLException;
import java.util.List;
import java.util.Objects;

/**
 * 借阅业务服务：事务边界在数据库存储过程内，Service 只做调用、复查与异常转换。
 */
public class BorrowService {

    private final BorrowDAO borrowDAO;

    public BorrowService() {
        this(new BorrowDAOImpl());
    }

    BorrowService(BorrowDAO borrowDAO) {
        this.borrowDAO = Objects.requireNonNull(borrowDAO, "borrowDAO");
    }

    /**
     * 借书：返回码逐分支映射，非 0 一律视为失败。
     */
    public BorrowOutcome borrow(String readerId, String copyId) {
        try {
            return borrowDAO.borrow(readerId, copyId);
        } catch (SQLException e) {
            throw new ServiceException("借书调用失败：" + e.getMessage(), e);
        }
    }

    /**
     * 还书：过程可能静默更新 0 行，必须复查记录后判定。
     */
    public boolean returnBook(String borrowId, String adminId) {
        try {
            return borrowDAO.returnBook(borrowId, adminId);
        } catch (SQLException e) {
            throw new ServiceException("还书调用失败：" + e.getMessage(), e);
        }
    }

    /**
     * 续借：比较前后 due_date，避免把静默 0 行误判为成功。
     */
    public boolean renewBook(String borrowId) {
        try {
            return borrowDAO.renewBook(borrowId);
        } catch (SQLException e) {
            throw new ServiceException("续借调用失败：" + e.getMessage(), e);
        }
    }

    public List<BorrowDetail> history(String readerId) {
        try {
            return borrowDAO.findHistoryByReader(readerId);
        } catch (SQLException e) {
            throw new ServiceException("查询借阅历史失败：" + e.getMessage(), e);
        }
    }
}
