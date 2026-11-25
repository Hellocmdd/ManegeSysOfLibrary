# 图书管理系统 · 数据库大作业

图书管理系统数据库设计与实现。项目按「数据库设计 → 后端实现 → 前端应用」三条主线推进，最终交付数据库脚本、应用源码、截图、查询样例与小组报告。

## 小组成员与分工

| 成员   | 角色        | 主线         | 核心职责                                                        |
| ------ | ----------- | ------------ | --------------------------------------------------------------- |
| 张展博 | 建模 & 文档 | 数据库设计线 | 概念建模（ER 图）→ 逻辑设计（关系模式）→ 物理设计（数据字典） |
| 谭博友 | 后端 & SQL  | 实现线       | MySQL 建库建表 → 存储过程/触发器 → 示例数据 → 接口           |
| 段绪礼 | 前端 & 报表 | 应用线       | Web 界面 / Python 控制台 + 各类查询/统计/报表                   |

详细任务、排期与依赖见 [分工与进度文档](docs/00_分工与进度.md)。

## 技术选型

- **数据库**：MySQL 9.7.2（远程实例；任务书要求 8.4 LTS，当前环境差异已记录），存储引擎 InnoDB
- **后端**：Java 21 + JDBC（MySQL Connector/J），命令行程序，采用 `util/dao/service/Main` 分层；按课程任务书实现，不引入 Web 框架
- **前端**：Web（HTML/JS）或 Python tkinter / 命令行，方案待选型
- **设计工具**：draw.io（ER 图）、Excel（数据字典）
- **工程规范**：见 [.agent/README.md](.agent/README.md)

## 目录结构

```
ManegeSysOfLibrary/
├── .agent/                    ← 编码/设计/Git/AI 规范
├── .env.example               ← 远程数据库连接配置模板（密码不入库）
├── pom.xml                    ← Maven 依赖与构建配置
├── src/
│   ├── backend/               ← Java/JDBC 源码（util/dao/service/Main）
│   └── frontend/              ← 前端目录（框架/语言沿用原计划，本次不改动）
├── README.md                  ← 本文件
├── LICENSE                    ← Apache License 2.0
└── docs/                      ← 分工文档与各阶段交付物
    ├── 00_分工与进度.md
    ├── 01_ER图.png
    ├── 02_关系模式.md
    ├── 03_数据字典.xlsx
    ├── 03.1_范式检查说明.md
    ├── 04_init.sql
    ├── 05_存储过程与触发器.sql
    ├── 06_测试数据.sql
    ├── 07_后端接口文档.md（可选）
    ├── 08_前端页面截图/
    ├── 09_查询样例.sql
    └── 10_最终小组报告.docx
```

> 后端交付物另按课程任务书的提交目录规范整理在 `docs/01_项目需求分析/` 至 `docs/07_AI辅助过程/` 中；原有前端相关目录与文件保持不动。

> 当前仅 `00_分工与进度.md` 已完成，其余为按排期规划的交付物，尚未生成。

## 快速开始

待实现线交付后，可按以下顺序初始化本地环境：

1. 在远程 MySQL 9.7.2 实例中建库并授权账号，复制 `.env.example` 为本地 `.env` 填写 host、port、库名和用户名；密码只写本地 `.env`，不要提交。
2. 执行 `docs/04_数据库实现/create_tables.sql` 建库建表。
3. 执行 `docs/04_数据库实现/insert_data.sql` 导入示例数据。
4. 在项目根目录运行 `mvn exec:java -Dexec.mainClass=com.library.util.ConnectionCheck` 测试 JDBC 连接；运行 `mvn test` 执行测试，或运行 `mvn exec:java -Dexec.mainClass=com.library.Main` 启动 Java 命令行程序。首次运行会下载 Maven 依赖。
5. 运行应用线提供的 `app.py` 或打开 `index.html`（前端方案保持原计划，不在本次后端准备范围内）。

具体账号、端口与版本信息见 [环境说明](docs/环境说明.md)。

## 许可

本项目采用 [Apache License 2.0](LICENSE)。
