package com.library.dao;

import com.library.model.BorrowDetail;
import com.library.model.BorrowOutcome;

import java.sql.SQLException;
import java.util.List;

/**
 * 借阅数据访问接口；写操作封装三个权威存储过程。
 */
public interface BorrowDAO {

    BorrowOutcome borrow(String readerId, String copyId) throws SQLException;

    boolean returnBook(String borrowId, String adminId) throws SQLException;

    boolean renewBook(String borrowId) throws SQLException;

    BorrowDetail findById(String borrowId) throws SQLException;

    List<BorrowDetail> findHistoryByReader(String readerId) throws SQLException;
}
