package com.library.model;

/**
 * Category 表对应的分类实体；parentId 为 NULL 表示根节点。
 */
public record Category(
        String catId,
        String catName,
        String parentId) {
}
