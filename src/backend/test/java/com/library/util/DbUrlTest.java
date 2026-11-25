package com.library.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 连接 URL 构造的单元测试（不建立真实连接）。
 */
class DbUrlTest {

    @Test
    void defaultUrlUsesSharedDatabase() {
        String url = DBUtil.buildUrl("127.0.0.1", "3306", "storageoflibrarysys");
        assertTrue(url.startsWith("jdbc:mysql://127.0.0.1:3306/storageoflibrarysys"));
    }

    @Test
    void urlCarriesEncodingAndTimezone() {
        String url = DBUtil.buildUrl("db.example", "3307", "storageoflibrarysys");
        assertTrue(url.contains("characterEncoding=utf8"));
        assertTrue(url.contains("serverTimezone=Asia/Shanghai"));
        assertTrue(url.contains(":3307/"));
    }
}
