# 编码原则

## 1. 通用约定

- 目标版本：Java 21，`pom.xml` 中固定 `maven.compiler.release=21`；本机 JDK 21 已就绪。
- 编码：UTF-8；换行：LF；文件末尾保留一个空行。
- 缩进：4 个空格，不使用 Tab；单行长度建议不超过 120 字符。
- 命名：
  - 包：全小写，根包 `com.library`。
  - 类 / 接口：`UpperCamelCase`，DAO 接口以 `DAO` 结尾，实现类以 `DAOImpl` 结尾，Service 以 `Service` 结尾。
  - 方法 / 变量：`lowerCamelCase`；常量：`UPPER_SNAKE_CASE`。
  - 数据库表 / 字段：`snake_case`；SQL 关键字大写。
- 注释：公共类与公共方法写 Javadoc，说明业务意图；注释解释“为什么”，不重复代码；禁止保留注释掉的废弃代码。

## 2. 分层职责

以下目录均相对于 `src/backend/main/java/com/library/`。

| 层 | 目录 | 职责 | 禁止事项 |
| --- | --- | --- | --- |
| 入口 | `com.library.Main` | 命令行菜单、输入读取、结果展示 | 不写 SQL，不直接访问 `Connection` |
| 业务 | `service/` | 业务流程编排与事务边界 | 不拼装最终 SQL，不处理控制台输出 |
| 数据访问 | `dao/`、`dao/impl/` | SQL 执行与 `ResultSet` 映射 | 不写业务规则，不管理事务提交/回滚 |
| 连接工具 | `util/DBUtil.java` | 读取配置、建立/关闭连接 | 不写 SQL |
| 模型 | `model/` | 数据表对应的 Java 对象 | 不包含数据库访问逻辑 |

依赖方向只允许：`Main → Service → DAO → DBUtil`；`model` 可被各层引用。

## 3. JDBC 与 SQL

- 必须使用 `PreparedStatement`，禁止用字符串拼接用户输入值。
- 必须使用 try-with-resources 关闭 `Connection`、`PreparedStatement`、`ResultSet`。
- 生产查询禁止 `SELECT *`，必须显式列出字段。
- SQL 文件放在 `src/backend/sql/java/`，按 `create_tables.sql`、`insert_data.sql`、`query.sql` 组织。
- 所有 SQL 必须在远程 MySQL 9.7.2 实例中实际执行并核验结果，禁止仅凭语法推断。
- 数据库连接参数来自环境变量或本地 `.env`；禁止在源码中写入主机、账号或密码。

## 4. 异常与事务

- `SQLException` 必须捕获并补充上下文信息后向上抛出或转换，不允许空 catch。
- 多步写操作必须在 Service 层显式开启事务：失败时 `rollback()`，成功时 `commit()`，最后恢复 `autoCommit` 状态。
- 借阅、归还、预约等核心业务必须使用事务，保证相关数据一致。
- 控制台向用户展示友好提示；详细堆栈通过 `java.util.logging` 记录，不用 `System.out` 打印异常堆栈。

## 5. 测试要求

- 至少设计 10 个测试用例，覆盖正常流程、边界情况和异常情况，包含至少 1 个事务回滚用例。
- 测试记录写入 `docs/06_测试与优化/功能测试报告.md`，字段包括：编号、输入、预期结果、实际结果、是否通过、问题修复情况。
- 提交前必须运行 `mvn test`；仅当远程数据库可达时才运行集成测试。

## 6. 提交前检查

- [ ] `mvn test` 通过
- [ ] 新增 SQL 已在远程数据库执行验证
- [ ] 无硬编码密码或真实数据
- [ ] AI 生成内容已按 [AI_USAGE.md](AI_USAGE.md) 记录
- [ ] 提交信息符合 [GIT_CONVENTIONS.md](GIT_CONVENTIONS.md)
