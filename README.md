# 图书管理系统 · 数据库大作业

> **小组**：张展博（建模）· 谭博友（后端）· 段绪礼（前端）
> **数据库**：MySQL 9.7.2（远程实例；任务书要求 8.4 LTS，差异见 [环境说明](docs/环境说明.md)）· InnoDB · utf8mb4
> **代码托管**：GitHub（`git@github.com:Hellocmdd/ManegeSysOfLibrary.git`）
> **截止**：2026-12-04

图书管理系统数据库设计与实现。项目按「数据库设计 → 后端实现 → 前端应用」三条主线推进，最终交付数据库脚本、应用源码、截图、查询样例与小组报告。

## 小组成员与分工

| 成员   | 角色        | 主线         | 核心职责                                                        |
| ------ | ----------- | ------------ | --------------------------------------------------------------- |
| 张展博 | 建模 & 文档 | 数据库设计线 | 概念建模（ER 图）→ 逻辑设计（关系模式）→ 物理设计（数据字典） |
| 谭博友 | 后端 & SQL  | 实现线       | MySQL 建库建表 → 存储过程/触发器 → 示例数据 → Java/JDBC 命令行程序 |
| 段绪礼 | 前端 & 报表 | 应用线       | Flask 页面 + 各类查询/统计/报表                                  |

详细任务、排期与依赖见 [docs/00_分工与进度.md](docs/00_分工与进度.md)。根目录下 `00_分工与进度.md` 为早期版本；两者有差异时，以 `docs/00_分工与进度.md` 与课程任务书为准并向组内报告。

## 技术选型

- **数据库**：MySQL 9.7.2（远程实例），存储引擎 InnoDB，字符集 utf8mb4
- **后端**：Java 21 + JDBC（MySQL Connector/J），命令行程序，采用 `util/dao/service/Main` 分层；按课程任务书实现，不引入 Web 框架
- **前端**：沿用现有 `03_前端线/` 的 Flask + Jinja2 实现，本次不改动其框架与语言；`src/frontend/` 为前后端分离目录占位
- **设计工具**：draw.io（ER 图）、Excel（数据字典）
- **工程规范**：[.agent/README.md](.agent/README.md) 与 [.agent/java-jdbc/README.md](.agent/java-jdbc/README.md)

## 目录结构

```text
ManegeSysOfLibrary/
├── .agent/                    ← AI 协作提示词与 Java/JDBC 规范
├── .env.example               ← 远程数据库连接配置模板（密码不入库）
├── pom.xml                    ← Maven 依赖与构建配置
├── src/
│   ├── backend/               ← Java/JDBC 源码（util/dao/service/Main）
│   └── frontend/              ← 前端目录占位（框架/语言沿用原计划）
├── 00_分工与进度.md            ← 早期分工文档
├── 01_项目线/                  ← 现有 ER 图、关系模式、数据字典等
├── 02_后端线/                  ← 现有建表/存储过程/测试数据 SQL
├── 03_前端线/                  ← 现有 Flask 前端实现
├── docs/                      ← 本次新增的规范、环境说明与交付模板
│   ├── 00_分工与进度.md
│   ├── 环境说明.md
│   ├── 01_项目需求分析/
│   ├── 02_数据库概念设计/
│   ├── 03_数据库逻辑设计/
│   ├── 04_数据库实现/
│   ├── 05_JDBC应用编程/
│   ├── 06_测试与优化/
│   └── 07_AI辅助过程/
├── tools/
├── README.md                  ← 本文件
└── LICENSE                    ← Apache License 2.0
```

> `02_后端线/*.sql` 由设计线维护，是现有数据库事实来源；`docs/04_数据库实现/` 是 Java/JDBC 工程配套脚本骨架，后续需与 `02_后端线/` 对齐。前端相关目录与文件保持原计划不动。

## 快速开始

### 后端（Java/JDBC）

1. 复制 `.env.example` 为本地 `.env`，填写 host、port、库名、用户名与密码；密码只写本地 `.env`，不要提交。
2. 导入数据库脚本：现有脚本在 `02_后端线/04_init.sql`、`05_存储过程.sql`、`06_测试数据.sql`；Java 配套骨架在 `docs/04_数据库实现/`。
3. 测试 JDBC 连接：

```bash
mvn -q exec:java -Dexec.mainClass=com.library.util.ConnectionCheck
```

4. 运行测试或命令行程序：

```bash
mvn test
mvn -q exec:java -Dexec.mainClass=com.library.Main
```

首次运行会下载 Maven 依赖。具体版本与连接信息见 [环境说明](docs/环境说明.md)。

### 前端（沿用现有实现）

```bash
pip install flask mysql-connector-python
python 03_前端线/app.py        # 浏览器访问 http://localhost:5000
```

## 同步机制

每周二、周五晚 8:00 腾讯会议 15 分钟，**禁止跳过**。详情见 `00_分工与进度.md` 第四节。

## 提交方式

最终打包为 zip，以 **张展博+2024302111213.zip** 命名提交给老师。

## 许可

本项目采用 [Apache License 2.0](LICENSE)。
