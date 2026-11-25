package com.library;

import com.library.model.BookRank;
import com.library.model.BookSummary;
import com.library.model.BorrowDetail;
import com.library.model.BorrowOutcome;
import com.library.model.Category;
import com.library.model.CategoryStat;
import com.library.model.Copy;
import com.library.model.MonthlyCount;
import com.library.model.Reader;
import com.library.service.BorrowService;
import com.library.service.CatalogService;
import com.library.service.ReportService;
import com.library.service.ServiceException;
import com.library.util.ConnectionCheck;

import java.time.LocalDate;
import java.util.List;
import java.util.Scanner;
import java.util.logging.Logger;

/**
 * 命令行入口：只负责菜单交互与结果展示，不写 SQL、不直接访问 Connection。
 */
public class Main {

    private static final Logger LOG = Logger.getLogger(Main.class.getName());

    private final Scanner scanner;
    private final CatalogService catalogService;
    private final BorrowService borrowService;
    private final ReportService reportService;

    private Main(Scanner scanner) {
        this.scanner = scanner;
        this.catalogService = new CatalogService();
        this.borrowService = new BorrowService();
        this.reportService = new ReportService();
    }

    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {
            new Main(scanner).run();
        }
    }

    private void run() {
        while (true) {
            printMenu();
            System.out.print("请选择：");
            String choice = scanner.nextLine().trim();
            if ("0".equals(choice)) {
                System.out.println("已退出。");
                return;
            }
            try {
                dispatch(choice);
            } catch (ServiceException e) {
                LOG.warning(e.getMessage());
                System.out.println("操作失败：" + e.getMessage());
            }
        }
    }

    private void dispatch(String choice) {
        switch (choice) {
            case "1" -> printReaders(catalogService.readers());
            case "2" -> printCategories(catalogService.categories());
            case "3" -> printBooks(catalogService.searchBooks(prompt("书名关键字（直接回车为全部）："),
                    prompt("分类编号（直接回车为全部）：")));
            case "4" -> printCopies(catalogService.availableCopies(prompt("书籍编号：")));
            case "5" -> printBorrowDetails(borrowService.history(prompt("读者编号：")));
            case "6" -> borrow();
            case "7" -> returnBook();
            case "8" -> renewBook();
            case "9" -> {
                System.out.println("当前逾期 = 未归还 且 已过应还日期（is_overdue 是历史标记，不等于当前逾期）");
                printBorrowDetails(reportService.currentOverdue());
            }
            case "10" -> printTopBooks(reportService.topBooks());
            case "11" -> printCategoryStats(reportService.categoryStats());
            case "12" -> printMonthly(reportService.monthlyBorrowCounts());
            case "13" -> ConnectionCheck.check();
            default -> System.out.println("无效选择，请重新输入。");
        }
    }

    private void borrow() {
        BorrowOutcome outcome = borrowService.borrow(prompt("读者编号："), prompt("副本编号："));
        System.out.println(outcome.message());
    }

    private void returnBook() {
        String borrowId = prompt("借阅记录编号：");
        boolean ok = borrowService.returnBook(borrowId, blankToNull(prompt("经办管理员编号（可空）：")));
        System.out.println(ok ? "还书成功。" : "还书失败：记录不存在或已归还，请复查编号。");
    }

    private void renewBook() {
        boolean ok = borrowService.renewBook(prompt("借阅记录编号："));
        System.out.println(ok ? "续借成功，应还日期顺延 30 天。" : "续借失败：记录不存在或已归还。");
    }

    private String prompt(String message) {
        System.out.print(message);
        return scanner.nextLine().trim();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }

    private static String date(LocalDate value) {
        return value == null ? "—" : value.toString();
    }

    private static void printMenu() {
        System.out.println();
        System.out.println("===== 图书管理系统（Java/JDBC） =====");
        System.out.println("1. 查看读者列表        2. 查看分类列表        3. 查询图书");
        System.out.println("4. 查看可借副本        5. 借阅历史            6. 借书");
        System.out.println("7. 还书                8. 续借                9. 当前逾期清单");
        System.out.println("10. 热门图书 TOP10     11. 各分类馆藏量       12. 每月借阅量");
        System.out.println("13. 测试数据库连接     0. 退出");
    }

    private static void printReaders(List<Reader> rows) {
        System.out.println("读者编号 | 姓名   | 性别 | 电话         | 注册日期   | 状态(1正常/0禁用)");
        rows.forEach(r -> System.out.printf("%s | %-6s | %s | %-12s | %s | %d%n",
                r.readerId(), r.name(), r.sex(), r.phone(), date(r.regDate()), r.status()));
    }

    private static void printCategories(List<Category> rows) {
        System.out.println("分类编号 | 分类名称       | 父分类编号");
        rows.forEach(c -> System.out.printf("%s | %-14s | %s%n",
                c.catId(), c.catName(), c.parentId() == null ? "—" : c.parentId()));
    }

    private static void printBooks(List<BookSummary> rows) {
        System.out.println("书号 | 书名                       | 作者       | 分类         | 副本/可借");
        rows.forEach(b -> System.out.printf("%s | %-24s | %-10s | %-12s | %d/%d%n",
                b.bookId(), b.title(), b.author(), b.catName(), b.copyTotal(), b.copyAvailable()));
    }

    private static void printCopies(List<Copy> rows) {
        System.out.println("副本编号 | 馆藏编号 | 存放位置");
        rows.forEach(c -> System.out.printf("%s | %s | %s%n",
                c.copyId(), c.assetNo(), c.location()));
    }

    private static void printBorrowDetails(List<BorrowDetail> rows) {
        System.out.println("借阅编号 | 读者   | 书名                 | 副本    | 借出       | 应还       "
                + "| 归还       | 状态   | 曾逾期");
        rows.forEach(b -> System.out.printf("%s | %-6s | %-20s | %s | %s | %s | %s | %s | %d%n",
                b.borrowId(), b.readerName(), b.title(), b.assetNo(), date(b.borrowDate()),
                date(b.dueDate()), date(b.returnDate()), b.status(), b.isOverdue()));
    }

    private static void printTopBooks(List<BookRank> rows) {
        System.out.println("排名 | 书号 | 书名                       | 借阅次数");
        for (int i = 0; i < rows.size(); i++) {
            BookRank row = rows.get(i);
            System.out.printf("%d | %s | %-24s | %d%n",
                    i + 1, row.bookId(), row.title(), row.borrowCount());
        }
    }

    private static void printCategoryStats(List<CategoryStat> rows) {
        System.out.println("分类编号 | 分类名称       | 书目数 | 副本数（不含子分类汇总）");
        rows.forEach(c -> System.out.printf("%s | %-14s | %d | %d%n",
                c.catId(), c.catName(), c.bookCount(), c.copyCount()));
    }

    private static void printMonthly(List<MonthlyCount> rows) {
        System.out.println("月份   | 借阅量");
        rows.forEach(m -> System.out.printf("%s | %d%n", m.month(), m.borrowCount()));
    }
}
