# 图书管理系统 · 数据库大作业

> **小组**：张展博（建模）· 谭博友（后端）· 段绪礼（前端）
> **数据库**：MySQL 9.7.2（远程实例；任务书要求 8.4 LTS，差异见 [环境说明](docs/环境说明.md)）· InnoDB · utf8mb4
> **代码托管**：GitHub（`git@github.com:Hellocmdd/ManegeSysOfLibrary.git`）
> **截止**：2026-12-04

图书管理系统数据库设计与实现。项目按「数据库设计 → 后端实现 → 前端应用」三条主线推进，最终交付数据库脚本、应用源码、截图、查询样例与小组报告。

## 小组成员与分工

| 成员   | 角色        | 主线         | 核心职责                                                              |
| ------ | ----------- | ------------ | --------------------------------------------------------------------- |
| 张展博 | 建模 & 文档 | 数据库设计线 | 概念建模（ER 图）→ 逻辑设计（关系模式）→ 物理设计（数据字典）       |
| 谭博友 | 后端 & SQL  | 实现线       | MySQL 建库建表 → 借还续存储过程 → 示例数据 → Java/JDBC 命令行程序 |
| 段绪礼 | 前端 & 报表 | 应用线       | Flask 页面 + 各类查询/统计/报表                                       |

详细任务、排期与依赖见 [docs/00_分工与进度.md](docs/00_分工与进度.md)。该文件是唯一有效的分工与进度登记文档；如有差异，以它与课程任务书为准并向组内报告。

## 技术选型

- **数据库**：MySQL 9.7.2（远程实例），存储引擎 InnoDB，字符集 utf8mb4
- **后端**：Java 21 + JDBC（MySQL Connector/J），命令行程序，采用 `util/dao/service/Main` 分层；按课程任务书实现，不引入 Web 框架
- **前端**：已迁移到 `src/frontend/` 的 Flask + Jinja2 实现，本次不改动其框架与语言
- **设计工具**：draw.io（ER 图）、Excel（数据字典）
- **工程规范**：[.agent/README.md](.agent/README.md) 与 [.agent/java-jdbc/README.md](.agent/java-jdbc/README.md)

## 目录结构

```text
ManegeSysOfLibrary/
├── .agent/                    ← AI 协作提示词与 Java/JDBC 规范
├── .env.example               ← 前后端共用的唯一环境变量模板
├── pom.xml                    ← Maven 依赖与构建配置
├── src/
│   ├── backend/
│   │   ├── main/java/com/library/   ← Java/JDBC 源码
│   │   ├── test/java/               ← Java 测试
│   │   └── sql/                     ← 后端线 SQL 与 Java 配套脚本
│   └── frontend/                ← Flask + Jinja2 前端运行时代码
│       ├── app.py / config.py / db.py / queries.py
│       ├── requirements.txt
│       ├── start.bat / start.sh
│       └── templates/ / static/
├── docs/                      ← 设计线成果与交付模板
│   ├── 00_分工与进度.md
│   ├── 环境说明.md
│   ├── 01_项目需求分析/
│   │   └── 需求分析报告.md   ← 数据库设计的前置依据
│   ├── 02_数据库概念设计/
│   │   ├── 01_ER图.mmd
│   │   └── ER图/
│   ├── 03_数据库逻辑设计/
│   │   ├── 02_关系模式.md
│   │   ├── 03.1_范式检查说明.md
│   │   ├── 03_数据字典.xlsx
│   │   └── tools/gen_datadict.py
│   ├── 05_JDBC应用编程/
│   ├── 06_测试与优化/
│   ├── 07_AI辅助过程/
│   └── 08_前端交付物/
│       ├── README.md
│       ├── 08_前端页面截图/
│       └── 09_查询样例.sql
├── README.md                  ← 本文件
└── LICENSE                    ← Apache License 2.0
```

> 设计线成果与前端交付文档在 `docs/`，后端线 SQL 与 Java 工程在 `src/backend/`，前端运行时代码在 `src/frontend/`；三者技术选型与既有实现保持不变。

## 快速开始

### 一键启动

| 平台                | 命令                     | 行为                                                               |
| ------------------- | ------------------------ | ------------------------------------------------------------------ |
| Windows             | 双击根目录 `start.bat` | 分别打开后端与前端窗口                                             |
| Linux / macOS / WSL | `./start.sh`           | 前端后台运行，日志写入 `logs/frontend.log`；后端命令行保持在前台 |

单独启动：

- 后端：`src/backend/start.bat` / `src/backend/start.sh`
- 前端：`src/frontend/start.bat` / `src/frontend/start.sh`

### 后端（Java/JDBC）

1. 复制根目录 `.env.example` 为根目录 `.env`，填写数据库与 Flask 配置；密码只写本地 `.env`，不要提交。
2. 导入数据库脚本：按 `src/backend/sql/04_init.sql` → `05_存储过程.sql` → `06_测试数据.sql` 顺序执行；`src/backend/sql/java/` 下三份脚本是与权威脚本同口径的配套副本。当前远程库已授予 `REFERENCES`，三步脚本已实际执行通过。
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
cd src/frontend
pip install -r requirements.txt
python app.py                    # 浏览器访问 http://127.0.0.1:5000
```

## 测试

```bash
# Java 后端
mvn test

# 前端与前后端契约（不需要远程数据库）
src/frontend/.venv/bin/python -m pytest -q -m "not integration"

# 真实数据库冒烟（需能连上远程 MySQL）
RUN_DB_INTEGRATION=1 src/frontend/.venv/bin/python -m pytest -q -m integration

# Java 真库集成测试（同样由 RUN_DB_INTEGRATION 门控，默认跳过）
RUN_DB_INTEGRATION=1 mvn test
```

CI 配置在 `.github/workflows/ci.yml`，包含 Java、前端测试和前后端契约三个作业；真实数据库冒烟默认不在 CI 中运行。

## 许可

本项目采用 [Apache License 2.0](LICENSE)。
