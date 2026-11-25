# Java/JDBC 后端工程规范

本子目录补充 `src/backend/` 下 Java 21 + JDBC 工程的约定，不替代 `.agent/AGENT.md` 与 `.agent/conventions/*`。

## 与其他约定的关系

- Git 流程以 `.agent/conventions/git-workflow.md` 与 `.agent/conventions/commit-push-confirm.md` 为准；本目录 `GIT_CONVENTIONS.md` 只提供 Java 项目的提交示例。
- 表结构、存储过程、状态值与报表口径以 `src/backend/sql/04_init.sql`、`05_存储过程.sql` 和 `.agent/conventions/db-contract.md` 为准；本目录 `DESIGN_GUIDELINES.md` 已同步为同一口径，若仍出现冲突，以 SQL 为准并向组内报告。
- 前端实现已迁移到 `src/frontend/`，仍沿用 Flask + Jinja2；本次不改动其框架与语言。

## 文档索引

- [CODING_STANDARDS.md](CODING_STANDARDS.md)：Java 21 编码原则、分层、JDBC 与事务
- [DESIGN_GUIDELINES.md](DESIGN_GUIDELINES.md)：数据库与应用分层设计准则
- [GIT_CONVENTIONS.md](GIT_CONVENTIONS.md)：Java 项目提交信息示例
- [AI_USAGE.md](AI_USAGE.md)：AI 辅助验证与记录模板

## 适用范围

本目录规范覆盖数据库设计与 Java/JDBC 命令行后端，不覆盖现有 Flask 前端实现。修改后请在 PR 描述里写明改动条目与原因。
