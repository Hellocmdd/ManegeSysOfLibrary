# Git 提交规范

## 1. 分支规范

- `main`：默认分支，只接收经过检查的合并，不直接提交。
- 功能分支：`feat/<scope>-<简短描述>`，例如 `feat/jdbc-borrow-service`。
- 修复分支：`fix/<scope>-<简短描述>`，例如 `fix/sql-foreign-key`。
- 文档分支：`docs/<简短描述>`，例如 `docs/agent-conventions`。
- 测试分支：`test/<简短描述>`；杂项分支：`chore/<简短描述>`。

分支名使用小写英文、数字和连字符，不写中文和空格。

## 2. 提交信息格式

采用 Conventional Commits：

```text
<type>(<scope>): <subject>

<body>

<footer>
```

- `type`：`feat`、`fix`、`docs`、`test`、`refactor`、`chore`、`style`、`perf`、`build`。
- `scope`：如 `sql`、`jdbc`、`reader`、`borrow`、`agent`、`docs`。
- `subject`：简短祈使句，不超过 50 字符，中文或英文均可；不加句号。
- `body`：说明“为什么”和关键实现，不重复标题。
- `footer`：可写 `Refs: #编号` 或 `BREAKING CHANGE: ...`。

示例：

```text
feat(jdbc): 实现借阅事务与回滚
fix(sql): 修正副本状态约束
docs(agent): 补充编码与设计规范
test(borrow): 增加重复借阅异常用例
```

## 3. 提交粒度与内容

- 一次提交只包含一个逻辑变更；代码、SQL、文档混改时应拆分。
- 不提交 `.env`、`target/`、`*.class`、日志、临时文件、数据库密码。
- 不提交未经理解的 AI 生成结果；AI 辅助记录按 [AI_USAGE.md](AI_USAGE.md) 归档。
- 提交前必须运行 `mvn test`，并确保新增 SQL 已在远程数据库验证。

## 4. 合并流程

1. 从最新的 `main` 创建功能分支。
2. 完成开发并通过提交前检查。
3. 发起 Pull Request，写明变更内容、测试情况与关联交付物。
4. 至少一名组员检查后合并；合并后删除功能分支。

> 当前仓库仅有 `main` 分支。本规范只约定流程，不自动修改本地 Git 配置或分支状态。
