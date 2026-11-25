package com.library.util;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Java/JDBC 连通性自检工具。仅读取元数据，不修改数据库。
 */
public final class ConnectionCheck {

    private ConnectionCheck() {
    }

    public static void main(String[] args) {
        if (!check()) {
            System.exit(1);
        }
    }

    /**
     * 测试数据库连接并打印脱敏的连接信息。
     *
     * @return 连接成功返回 true，否则返回 false
     */
    public static boolean check() {
        System.out.println("正在测试 Java/JDBC 连接...");
        try (Connection conn = DBUtil.getConnection()) {
            DatabaseMetaData meta = conn.getMetaData();
            System.out.println("连接成功");
            System.out.println("驱动: " + meta.getDriverName() + " " + meta.getDriverVersion());
            System.out.println("数据库产品: " + meta.getDatabaseProductName()
                    + " " + meta.getDatabaseProductVersion());
            System.out.println("当前库: " + conn.getCatalog());
            System.out.println("登录用户: " + meta.getUserName());
            try (Statement st = conn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT VERSION() AS server_version")) {
                if (rs.next()) {
                    System.out.println("SELECT VERSION(): " + rs.getString("server_version"));
                }
            }
            return true;
        } catch (SQLException e) {
            System.err.println("连接失败: " + e.getMessage());
            return false;
        }
    }
}
