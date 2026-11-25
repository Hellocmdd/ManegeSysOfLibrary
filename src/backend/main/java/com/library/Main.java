package com.library;

import com.library.util.ConnectionCheck;

import java.util.Scanner;

/**
 * 命令行入口。仅负责菜单交互；数据库检测委托给 ConnectionCheck，不执行 SQL。
 */
public class Main {

    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {
            while (true) {
                printMenu();
                System.out.print("请选择：");
                String choice = scanner.nextLine().trim();
                if ("0".equals(choice)) {
                    System.out.println("已退出。");
                    return;
                }
                switch (choice) {
                    case "1" -> System.out.println("读者列表功能待实现。");
                    case "2" -> System.out.println("借阅事务功能待实现。");
                    case "3" -> ConnectionCheck.check();
                    default -> System.out.println("无效选择，请重新输入。");
                }
            }
        }
    }

    private static void printMenu() {
        System.out.println();
        System.out.println("===== 图书管理系统（Java/JDBC） =====");
        System.out.println("1. 查看读者列表");
        System.out.println("2. 借阅图书");
        System.out.println("3. 测试数据库连接");
        System.out.println("0. 退出");
    }
}
