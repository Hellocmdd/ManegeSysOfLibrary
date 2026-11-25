package com.library.util;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import java.util.logging.Logger;

/**
 * 数据库连接工具：优先读取环境变量，其次从仓库根目录向上查找 .env。
 */
public final class DBUtil {

    private static final Logger LOG = Logger.getLogger(DBUtil.class.getName());
    private static final Properties CONFIG = loadConfig();

    private DBUtil() {
    }

    public static Connection getConnection() throws SQLException {
        String host = get("DB_HOST", "127.0.0.1");
        String port = get("DB_PORT", "3306");
        String database = get("DB_NAME", "storageoflibrarysys");
        return DriverManager.getConnection(
                buildUrl(host, port, database), get("DB_USER", ""), get("DB_PASSWORD", ""));
    }

    static String buildUrl(String host, String port, String database) {
        return String.format(
                "jdbc:mysql://%s:%s/%s?useUnicode=true&characterEncoding=utf8"
                        + "&connectionCollation=utf8mb4_unicode_ci&serverTimezone=Asia/Shanghai",
                host, port, database);
    }

    public static void close(AutoCloseable closeable) {
        if (closeable == null) {
            return;
        }
        try {
            closeable.close();
        } catch (Exception e) {
            LOG.warning("关闭资源失败: " + e.getMessage());
        }
    }

    private static String get(String key, String defaultValue) {
        String fromEnv = System.getenv(key);
        if (fromEnv != null && !fromEnv.isBlank()) {
            return fromEnv;
        }
        String fromFile = CONFIG.getProperty(key);
        if (fromFile != null && !fromFile.isBlank()) {
            return fromFile;
        }
        return defaultValue;
    }

    private static Properties loadConfig() {
        Properties properties = new Properties();
        Path envFile = findEnvFile();
        if (envFile == null) {
            LOG.warning("未找到 .env，将仅使用环境变量与默认值");
            return properties;
        }
        try (InputStream in = Files.newInputStream(envFile)) {
            properties.load(in);
        } catch (IOException e) {
            LOG.warning("无法读取 .env，将仅使用环境变量: " + e.getMessage());
        }
        return properties;
    }

    private static Path findEnvFile() {
        Path dir = Path.of("").toAbsolutePath();
        for (int i = 0; i < 8 && dir != null; i++) {
            Path candidate = dir.resolve(".env");
            if (Files.isRegularFile(candidate)) {
                return candidate;
            }
            dir = dir.getParent();
        }
        return null;
    }
}
