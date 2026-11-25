# conventions/ — 通用规范索引

存放跨任务的通用规范：代码风格、Python 专项、SQL 专项、页面样式、注释、文档、数据库契约、git 工作流与提交确认协议。与根目录的场景型提示词（`review` / `test-writer` / `docs-writer` / `release`）不同，本目录是所有任务共享的约束，按主题拆分、独立维护。

## 文件与触发时机

| 文件 | 什么时候读 | 什么时候不读 |
| --- | --- | --- |
| `code-style.md` | 写代码、改代码、审查代码 | 纯文档任务 |
| `python-style.md` | 任何 `.py` 文件 | 只改 SQL 或模板 |
| `sql-style.md` | 写查询、改报表、调存储过程 | 只改 CSS |
| `web-style.md` | 写 Jinja2 模板、HTML、CSS、少量 JS | 只改 Python |
| `comment-style.md` | 写注释、补 docstring、清 TODO | 不涉及注释的配置改动 |
| `docs-style.md` | 写任何 Markdown 或报告章节 | 纯代码任务 |
| `db-contract.md` | 碰表、字段、存储过程、报表口径 | 不碰数据库的界面调整 |
| `git-workflow.md` | 任何 git 写操作前（branch/commit/merge） | 只读 git 命令 |
| `commit-push-confirm.md` | commit / push / merge / 删除分支之前 | 无例外，写操作一律先读 |

## 与 AGENT.md 的关系

- `AGENT.md` 定义角色、任务类型、硬约束 N1–N14 与默认工作流。
- 本目录是主提示词的外挂规范库，只被引用、不被复制；`AGENT.md` 不重复这里的细则。
- 本目录与 `AGENT.md` 冲突时，以更严格的一侧为准，并回头修正另一处。

## 内容边界

- 只写"怎么做才合规"，不写具体功能的实现方案。
- 不写成员姓名、固定分工；归属用"设计线 / 后端线 / 前端线"表达。
- 项目事实（表字段、存储过程签名、状态值、统计口径）以 `src/backend/sql/*.sql` 为准；`db-contract.md` 只记录**前端视角的契约与已知差异**，不复制整份建表脚本。

## 修改规则

1. 新增规范主题时新建独立 `.md`，并在本 README 与 `../README.md` 登记，不塞进现有文件。
2. 后端线改了表结构或存储过程后，必须同步 `db-contract.md` 的"已知差异"与 `AGENT.md` 第二节的事实；两者不一致视为缺陷。
3. 修改后自检：是否与 `src/backend/sql/*.sql` 冲突？是否与 N1–N14 冲突？是否引入人名或固定分工？
4. 规范的增删属协作流程变更，改动说明写进 PR 描述。
