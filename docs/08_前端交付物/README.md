# 图书管理系统 · 前端交付物

> 本文由 `src/frontend/README.md` 迁移至 `docs/08_前端交付物/`；运行时代码仍在 `src/frontend/`，框架、语言与功能不变。
> 负责人：段绪礼 · v1.1 · 2026-11-25

## 1. 技术选型

| 项目 | 选择 | 说明 |
| --- | --- | --- |
| 语言 | Python 3.10 | 一键脚本优先 `py -3.10`，找不到再退 `py -3.11` / `py -3`；3.10 是本机 Flask/PyMySQL 已验证的版本 |
| Web 框架 | Flask 3.x | 轻量，路由与模板够用 |
| 数据库驱动 | **PyMySQL** | 纯 Python、免编译；`cursor.nextset()` 能正确接住存储过程的多个结果集，适合 `CALL` + `OUT` 参数 |
| 模板 | Jinja2 | Flask 自带 |
| 样式 | 原生 CSS | 不引 CDN，断网也能演示 |
| ORM | **不用** | 直接写 SQL，课程要求 SQL 功底可见 |

不使用 `mysql-connector-python`：两个驱动都能用，但同时装会重复维护，统一用 PyMySQL。

## 2. 目录结构

```
src/frontend/
├── start.bat / start.sh      一键启动：建 venv、装依赖、生成根目录 .env、跑服务
├── .env                      可选覆盖（无模板，配置统一在仓库根目录）
├── app.py                    Flask 入口：路由、登录态、错误页
├── config.py                 连接参数与常量，密码只从环境变量读取
├── db.py                     连接生命周期、参数化查询、存储过程调用
├── queries.py                页面与报表用到的 SQL
├── requirements.txt          运行依赖
├── templates/
│   ├── base.html             顶栏、flash 提示、页脚
│   ├── login.html            管理员登录
│   ├── book_list.html        书目查询（筛选、分页、借书按钮）
│   ├── reader_history.html   读者档案 + 借阅历史（还书、续借）
│   ├── reports.html          四张统计报表
│   └── error.html            数据库/404 错误页
└── static/
    └── style.css             全站样式，含窄屏适配
```

> 非运行时交付物已迁至本目录：`README.md`、`08_前端页面截图/`、`09_查询样例.sql`。

> 相对 v1.0 增加了 `db.py` 与 `queries.py`：单文件 `app.py` 会超过 400 行，按 `.agent/conventions/code-style.md` 拆分，SQL 集中到一处便于与 `09_查询样例.sql` 对照。

## 3. 启动方式

### 3.1 一键启动（推荐）

- Windows：双击 `src/frontend/start.bat`
- Linux / macOS / WSL：在 `src/frontend/` 执行 `./start.sh`

脚本会依次：

1. 建 `.venv` 虚拟环境（已存在则跳过；优先 `py -3.10`，再退 `py -3.11`、`py -3`）；
2. 检查依赖，缺 Flask/PyMySQL 时按 `requirements.txt` 安装（清华源 → 阿里云 → PyPI → **阿里云 HTTP**，最后一级用于旧 pip 遇到 TLS 被本地代理打断的情况）；
3. 没有仓库根目录 `.env` 时按根目录 `.env.example` 复制一份；
4. 自检数据库连通性（`db.check_connection()`），连不上只告警不中断，页面会显示错误页；
5. 启动服务并提示浏览器打开 `http://127.0.0.1:5000`。

数据库密码等 `DB_*` 和 Flask 配置统一在**仓库根目录 `.env`** 配置；前端 `.env` 仅作可选覆盖，不提供单独模板。关闭窗口或按 `Ctrl+C` 停止服务。

### 3.2 手动启动（macOS / Linux，或想自己控制环境）

```bash
cd src/frontend
py -3.10 -m venv .venv         # Linux/macOS 用 python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Windows 手动激活写 `.venv\Scripts\activate`。

### 3.3 配置项

配置来源优先级：**系统环境变量 > `src/frontend/.env`（可选覆盖）> 仓库根目录 `.env` > 代码默认值**，代码里不写密码。

唯一模板是**仓库根目录 `.env.example`**；前端 `.env` 为可选覆盖，不提供单独模板。前端直接读取以下变量：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `DB_HOST` | `127.0.0.1` | MySQL 主机 |
| `DB_PORT` | `3306` | MySQL 端口 |
| `DB_NAME` | `storageoflibrarysys` | 数据库名 |
| `DB_USER` | `root` | MySQL 用户名（连组长远程库时填 `Manager`） |
| `DB_PASSWORD` | 空 | MySQL 密码，只写进本地 `.env` |
| `DB_SSL` | `1` | 是否强制 TLS；远程库要求 `--ssl-mode=REQUIRED`，本机 MySQL 未开 TLS 时设 `0` |
| `DB_TIME_ZONE` | `+08:00` | 连接后执行 `SET time_zone`，保证 `CURDATE()` 按东八区算借期与逾期 |
| `FLASK_SECRET_KEY` | 演示用默认值 | 会话签名密钥 |
| `FLASK_HOST` | `127.0.0.1` | 监听地址 |
| `FLASK_PORT` | `5000` | 监听端口 |
| `PAGE_SIZE` | `10` | 每页书目条数 |

`.env` 已被 `.gitignore` 忽略，根目录 `.env.example` 是唯一模板；也可以在终端临时覆盖：

```powershell
$env:DB_PASSWORD = "你的 MySQL 密码"
```

## 4. 数据库连接：远程 Tailscale 或本地 Docker

### 4.1 连接组长的远程库（推荐，当前测试数据所在）

远程地址 `100.123.95.127:3306` 属于 Tailscale 内网（`100.64.0.0/10`），不是公网地址，**必须先加入同一个 tailnet**，单靠账号密码连不上。

1. 安装 Tailscale：`winget install Tailscale.Tailscale`；已装过就跳过。
2. **不要用组长的 GitHub 账号登录**。让组长在 Tailscale 后台对这台机器做 Share（或邀请你自己的账号加入他的 tailnet），然后用自己的账号登录。
3. 验证是否真的进网（要管理员 PowerShell，否则读不到 `tailscaled` 管道）：
   ```powershell
   tailscale status          # 应能看到自己这台机器，且状态不是 offline
   tailscale ip -4           # 应输出 100.x.y.z
   tailscale ping 100.123.95.127
   ```
   托盘菜单里看到 "Connected" 但不显示 100.x 地址，说明只是完成了身份登录，还没加入任何 tailnet。
4. **让 Clash 放过内网段**：Clash 的 TUN/fake-ip 会把 `100.64.0.0/10` 也接走，表现为"连得上但立刻被断开"。在 Clash 规则里把 `100.64.0.0/10`（或 `100.123.95.127`）设为 `DIRECT`，或直接退出 Clash。
5. 先用官方客户端自查，确认是库的问题还是网络的问题：
   ```powershell
   & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -h 100.123.95.127 -P 3306 -u Manager -p --ssl-mode=REQUIRED
   ```
6. 在仓库根目录 `.env` 填远程参数（模板见 `.env.example` 的"远程库走 Tailscale"段）：
   ```
   DB_HOST=100.123.95.127
   DB_PORT=3306
   DB_NAME=storageoflibrarysys
   DB_USER=Manager
   DB_PASSWORD=<组长给的口令>
   DB_SSL=1
   DB_TIME_ZONE=+08:00
   ```
7. 双击 `src/frontend/start.bat`，看到 `[3/4] checking database connection` 没有告警即可。

常见错误对照：

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `2013 Lost connection ... reading initial communication packet` | 没进 tailnet，或 Clash 接管了 `100.64.0.0/10` | 回到第 3、4 步 |
| `2003 Can't connect to MySQL server` | Tailscale 未登录 / 地址或端口写错 | `tailscale status` 自检 |
| `RuntimeError: cryptography is required for sha2_password` | MySQL 9 的默认认证插件需要额外包 | `pip install cryptography` |

> 凭据只在群里临时传递，不要写进代码、文档或 Issue；建议请组长把口令轮换一次，并给前端单独建只读 + 存储过程执行权限的账号。

### 4.2 本地 Docker MySQL（不依赖别人，可离线演示）

```bash
docker compose up -d          # 仓库根目录，端口 3307，避开本机已装的 MySQL80
# 容器首次启动会自动按 04_init.sql → 05_存储过程.sql → 06_测试数据.sql 初始化
```

对应把 `.env` 的 `DB_HOST=127.0.0.1`、`DB_PORT=3307`、`DB_USER=library`、`DB_PASSWORD=<本地口令>`，`MYSQL_ROOT_PASSWORD` 也填上。若本机 MySQL 没开 TLS，把 `DB_SSL` 设为 `0`。

### 4.3 数据库结构与数据

`04_init.sql` 已按数据字典补齐六张表的字段、约束与外键；按 `04_init.sql → 05_存储过程.sql → 06_测试数据.sql` 顺序执行成功后，页面即可按真实数据查询。远程库已授予 `REFERENCES`，三步脚本已实际执行通过。

## 5. 页面与路由

| 页面 | 路由 | 方法 | 依赖 |
| --- | --- | --- | --- |
| 登录 | `/login` | GET / POST | `Admin` 表，`pwd = SHA2(?, 256)` |
| 退出 | `/logout` | GET | 清空会话 |
| 书目查询 | `/books` | GET | 书名模糊、分类筛选、分页、可借副本 |
| 借书 | `/borrow` | POST | `CALL borrow_book(reader_id, copy_id, @p_result)` |
| 还书 | `/borrow/<borrow_id>/return` | POST | `CALL return_book(borrow_id, admin_id)` |
| 续借 | `/borrow/<borrow_id>/renew` | POST | `CALL renew_book(borrow_id)` |
| 读者历史 | `/readers/<reader_id>` | GET | 档案 + 借阅记录，可直接还书/续借 |
| 统计报表 | `/reports` | GET | 四张报表一次取齐 |

登录态存在 Flask 会话里，未登录访问任何页面都会跳回 `/login`。管理员身份只用于登录与"经办人"字段，读者不需要登录，由管理员在页面上选择读者代为借还。

## 6. 存储过程返回码处理

`borrow_book` 的 OUT 参数必须显式接：

```sql
CALL borrow_book(%s, %s, @p_result);
SELECT @p_result;   -- 0 成功 / -1 不在馆 / -2 读者禁用 / -3 已借满 5 本 / -4 其他错误
```

- 前端把返回码映射成中文提示（`app.BORROW_MESSAGES`），不再自己判断副本状态；
- `return_book` 与 `renew_book` 没有返回码，且对"记录不存在/已归还"只更新 0 行不报错，因此 `db.py` 在调用后复查 `Borrow.status`、`due_date` 是否真的变化，用返回值告诉页面成功与否。

## 7. 四张报表与口径

| 报表 | 判定条件 | 说明 |
| --- | --- | --- |
| ① 借阅 TOP 10 | 按书名分组 `COUNT(*)` 降序，并列时追加 `book_id` | 含已归还记录，排序结果稳定 |
| ② 各分类馆藏量 | `Category LEFT JOIN Book LEFT JOIN Copy` | 父分类不含子分类汇总；`COUNT(DISTINCT b.book_id)` 防副本行放大 |
| ③ 当前逾期清单 | `return_date IS NULL AND due_date < CURDATE()` | **不用 `is_overdue = 1`**：那个字段在归还后仍保留 1，会把历史逾期算进来 |
| ④ 每月借阅量 | `DATE_FORMAT(borrow_date, '%Y-%m')` 分组 | 含已归还记录 |

完整 SQL 见 `09_查询样例.sql`，页面输出的数字必须来自实际查询，不能写死。

## 8. 已知限制

1. `04_init.sql` 表结构已补齐；远程库三步脚本已执行通过，真库集成测试也已通过。
2. `renew_book` 没有"只能续借一次"的标记，按当前权威口径允许重复续借；若需限制必须新增字段并改存储过程（后端线范围）。
3. 借阅历史页一次取全部记录，没有分页；测试数据量（15 条）下无影响。
4. 报表②口径已明确为**不含子分类汇总**，报表③口径已明确为**当前未归还且已过应还日期**，已同步到本文件与 `09_查询样例.sql`；若老师另有要求再调整。

## 9. 交付物（12/04 前）

- [x] `app.py` + 模板 + CSS 可运行
- [x] `start.bat` 一键启动（建 venv、装依赖、生成 .env）
- [x] 四张统计报表可用
- [x] `09_查询样例.sql` 汇总页面 SQL
- [ ] `08_前端页面截图/` 放 4 张关键截图（等数据库可用后补）
- [x] README 更新技术选型、路由与口径说明
