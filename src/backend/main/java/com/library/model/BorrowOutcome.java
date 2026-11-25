package com.library.model;

/**
 * borrow_book 过程返回码到用户提示的映射结果。
 */
public record BorrowOutcome(int code, String message, boolean success) {

    /**
     * 按 db-contract 约定的返回码生成提示；非 0 一律视为失败。
     */
    public static BorrowOutcome fromCode(int code) {
        return switch (code) {
            case 0 -> new BorrowOutcome(0, "借书成功，应还日期为 30 天后。", true);
            case -1 -> new BorrowOutcome(-1, "该副本当前不在馆，请换一本。", false);
            case -2 -> new BorrowOutcome(-2, "该读者已禁用或不存在，无法借书。", false);
            case -3 -> new BorrowOutcome(-3, "已借满 5 本，请先归还。", false);
            case -4 -> new BorrowOutcome(-4, "借书失败，事务已回滚，请稍后重试。", false);
            default -> new BorrowOutcome(code, "借书失败，未知返回码：" + code + "。", false);
        };
    }
}
