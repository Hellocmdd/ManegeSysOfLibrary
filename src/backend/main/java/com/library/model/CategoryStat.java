package com.library.model;

/**
 * 分类馆藏统计的一行结果；不含子分类汇总。
 */
public record CategoryStat(String catId, String catName, int bookCount, int copyCount) {
}
