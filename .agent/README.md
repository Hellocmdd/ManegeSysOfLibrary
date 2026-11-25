# .agent — 开发期 AI 协作提示词

## 这个目录是什么

存放开发期调用 AI 助手时使用的系统提示词与规范，**随仓库提交、全组共享**，任何成员修改后其他人拉取即生效。

- 本目录**不属于项目产出**：不参与运行、不被 Python 引用、不进最终报告与交付 ZIP 的说明里。
- 本目录**不要加进 `.gitignore`**。团队共享是前提，忽略它会让各人的 AI 行为不一致。
- 本目录只写"怎么协助开发"，不写"业务怎么实现"；表结构、存储过程与统计口径的事实放在 `02_后端线/*.sql` 与 `conventions/db-contract.md`。
- 本目录**不写成员姓名和固定分工**，统一用"设计线 / 后端线 / 前端线"表达归属。

## 文件索引

| 文件 | 用途 | 何时加载 |
| --- | --- | --- |
| `AGENT.md` | 主提示词：角色、项目速览、任务类型、硬约束 N1–N14、工作流、自检 | 每次会话的底座 |
| `review.md` | 代码与 SQL 审查：顺序、输出格式、必跑命令 | 提交前自查、Review 前预审 |
| `test-writer.md` | 测试：F1–F9 矩阵、断言要求、手工验证清单 | 写测试、补测试、跑测试 |
| `docs-writer.md` | 文档：README、接口说明、查询样例、截图归档的骨架 | 写、改文档 |
| `release.md` | 交付：环境冻结、打包、截图、ZIP 检查 | 12/04 前的最终交付 |
| `conventions/code-style.md` | 通用代码风格、目录与命名、错误处理、依赖边界 | 写、改、审查代码 |
| `conventions/python-style.md` | Python 专项：类型注解、docstring、Flask 分层、数据库访问、配置与密钥 | 所有 Python 任务 |
| `conventions/sql-style.md` | SQL 专项：参数化、连接与游标、报表口径、结果校验 | 所有查询与报表任务 |
| `conventions/web-style.md` | Jinja2 模板、HTML/CSS、表单与转义、页面状态 | 写页面 |
| `conventions/comment-style.md` | 注释与 docstring：必需位置、格式、TODO/FIXME | 写注释、补 docstring |
| `conventions/docs-style.md` | 文档通用规范：职责、结构、语言与事实 | 任何文档任务 |
| `conventions/db-contract.md` | 前端依赖的数据库契约：表、过程、状态值、报表口径、已知差异 | 涉及查询、报表、联调时 |
| `conventions/git-workflow.md` | 分支、提交信息、PR 与 Review | 任何 git 写操作前 |
| `conventions/commit-push-confirm.md` | commit/push/merge 的确认协议 | git 写操作前无条件必读 |
| `java-jdbc/README.md` | Java 21 + JDBC 后端工程规范：编码、设计、Git 示例与 AI 记录 | 编写/审查 `src/backend/` 时 |

## 两类提示词

- **场景型**（根目录）：`review` / `test-writer` / `docs-writer` / `release`，对应具体任务，按需叠加。
- **规范型**（`conventions/`）：跨任务的通用约束，按主题拆分，独立维护。

`AGENT.md` 是底座，其余文件与它叠加使用；规范型文件不重复角色与流程。

## Java/JDBC 后端规范

`java-jdbc/` 子目录补充 `src/backend/` 下 Java 21 + JDBC 工程的约定，不替代根目录提示词与 `conventions/`。其中表结构清单是开发骨架；若与 `02_后端线/*.sql` 或 `conventions/db-contract.md` 的事实不一致，应向组内报告差异，不自行择一执行。

## 使用方式

1. 会话开始时把 `AGENT.md` 作为系统提示词。
2. 任务命中某个场景时，再叠加对应场景文件。
3. 写代码、写注释、写 SQL、写文档、做 git 写操作时，按 `AGENT.md` 第四节索引加载，不预读全部。
4. 只读 git 命令（`status`/`log`/`diff`）无需加载规范。

## 修改规则

1. **不写死分工**：不写成员姓名、学号、账号，也不写"A 负责 X / B 负责 Y"。
2. **不标注权威来源**：不建"某文档最高权威"的排序，规则直接写成规则本身；发现提示词与 `.sql` 或文档不一致时，要求 AI 报告差异，不自行择一执行。
3. 新增**协作场景**：在根目录建独立 `.md`，并在本 README 登记。
4. 新增**通用规范**：在 `conventions/` 下建独立 `.md`，并在本 README 与 `conventions/README.md` 双重登记。
5. 新增 **Java/JDBC 子规范**：在 `java-jdbc/` 下维护，并在本 README 文件索引保留入口。
6. 修改后自检：是否与 `02_后端线/*.sql` 的事实冲突？是否与硬约束 N1–N14 冲突？是否出现具体人名或固定分工？
7. 目录随仓库提交；改动后由修改者在 PR 描述里写明"改了哪条规则、为什么"。
