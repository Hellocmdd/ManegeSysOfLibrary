package com.library.model;

/**
 * Admin 表对应的管理员实体；pwd 只保存 SHA256 哈希，不保存明文。
 */
public record Admin(
        String adminId,
        String name,
        String account,
        String pwd,
        String role) {
}
