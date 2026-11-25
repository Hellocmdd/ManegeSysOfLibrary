package com.library.service;

import com.library.dao.BookDAO;
import com.library.dao.CategoryDAO;
import com.library.dao.CopyDAO;
import com.library.dao.ReaderDAO;
import com.library.dao.impl.BookDAOImpl;
import com.library.dao.impl.CategoryDAOImpl;
import com.library.dao.impl.CopyDAOImpl;
import com.library.dao.impl.ReaderDAOImpl;
import com.library.model.BookSummary;
import com.library.model.Category;
import com.library.model.Copy;
import com.library.model.Reader;

import java.sql.SQLException;
import java.util.List;

/**
 * 书目与基础资料查询服务。
 */
public class CatalogService {

    private final ReaderDAO readerDAO;
    private final CategoryDAO categoryDAO;
    private final BookDAO bookDAO;
    private final CopyDAO copyDAO;

    public CatalogService() {
        this(new ReaderDAOImpl(), new CategoryDAOImpl(), new BookDAOImpl(), new CopyDAOImpl());
    }

    CatalogService(ReaderDAO readerDAO, CategoryDAO categoryDAO, BookDAO bookDAO, CopyDAO copyDAO) {
        this.readerDAO = readerDAO;
        this.categoryDAO = categoryDAO;
        this.bookDAO = bookDAO;
        this.copyDAO = copyDAO;
    }

    public List<Reader> readers() {
        try {
            return readerDAO.findAll();
        } catch (SQLException e) {
            throw new ServiceException("查询读者列表失败：" + e.getMessage(), e);
        }
    }

    public List<Category> categories() {
        try {
            return categoryDAO.findAll();
        } catch (SQLException e) {
            throw new ServiceException("查询分类列表失败：" + e.getMessage(), e);
        }
    }

    public List<BookSummary> searchBooks(String titleKeyword, String catId) {
        try {
            return bookDAO.search(titleKeyword, catId);
        } catch (SQLException e) {
            throw new ServiceException("查询书目失败：" + e.getMessage(), e);
        }
    }

    public List<Copy> availableCopies(String bookId) {
        try {
            return copyDAO.findAvailableByBook(bookId);
        } catch (SQLException e) {
            throw new ServiceException("查询可借副本失败：" + e.getMessage(), e);
        }
    }
}
