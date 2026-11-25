# 图书管理系统 · 前端应用线 README

> 前端实现已按前后端分离结构迁移到 `src/frontend/`；框架、语言与功能保持不变。
> 负责人：段绪礼 · v1.1 · 2026-11-25（骨架已可运行，等待后端线补齐 `04_init.sql`）

## 1. 技术选型

| 项目 | 选择 | 说明 |
| --- | --- | --- |
| 语言 | Python 3.11 | 与后端线、设计线保持一致 |
| Web 框架 | Flask 3.x | 轻量，路由与模板够用 |
| 数据库驱动 | **PyMySQL** | 纯 Python、免编译；`cursor.nextset()` 能正确接住存储过程的多个结果集，适合 `CALL` + `OUT` 参数 |
| 模板 | Jinja2 | Flask 自带 |
| 样式 | 原生 CSS | 不引 CDN，断网也能演示 |
| ORM | **不用** | 直接写 SQL，课程要求 SQL 功底可见 |

不使用 `mysql-connector-python`：两个驱动都能用，但同时装会重复维护，统一用 PyMySQL。

## 2. 目录结构

```
src/frontend/
├── start.bat                 一键启动：建 venv、装依赖、生成 .env、跑服务
├── .env.example              连接参数模板，首次运行由 start.bat 复制成 .env
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
├── static/
│   └── style.css             全站样式，含窄屏适配
├── 08_前端页面截图/           交付截图（见该目录 README）
└── 09_查询样例.sql            页面 SQL 与报表 SQL 汇总，供报告引用
```

> 相对 v1.0 增加了 `db.py` 与 `queries.py`：单文件 `app.py` 会超过 400 行，按 `.agent/conventions/code-style.md` 拆分，SQL 集中到一处便于与 `09_查询样例.sql` 对照。

## 3. 启动方式

### 3.1 一键启动（Windows，推荐）

双击 `src/frontend/start.bat`，它会依次：

1. 用 `py -3.11` 在 `src/frontend/.venv` 建虚拟环境（已存在则跳过）；
2. 检查依赖，缺 Flask/PyMySQL 时按 `requirements.txt` 安装；
3. 没有 `.env` 时按 `.env.example` 复制一份；
4. 启动服务并提示浏览器打开 `http://127.0.0.1:5000`。

数据库有密码时，第一次运行结束后编辑 `.env` 填 `DB_PASSWORD`，再双击一次即可。关闭窗口或按 `Ctrl+C` 停止服务。

### 3.2 手动启动（macOS / Linux，或想自己控制环境）

```bash
cd src/frontend
py -3.11 -m venv .venv          # Linux/macOS 用 python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Windows 手动激活写 `.venv\Scripts\activate`。

### 3.3 配置项

配置来源优先级：**系统环境变量 > `src/frontend/.env` > 代码默认值**，代码里不写密码。

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `DB_HOST` | `127.0.0.1` | MySQL 地址 |
| `DB_PORT` | `3306` | 端口；改用 Docker 的 MySQL 时填 `3307` |
| `DB_USER` | `root` | 账号 |
| `DB_PASSWORD` | 空 | 密码，只从环境变量或 `.env` 读取 |
| `DB_NAME` | `library_system` | 库名，与设计线一致 |
| `FLASK_SECRET_KEY` | 演示用默认值 | 会话签名密钥 |
| `PAGE_SIZE` | `10` | 每页书目条数 |

`.env` 已被 `.gitignore` 忽略，`.env.example` 进仓库作为模板；也可以在终端临时覆盖：

```powershell
$env:DB_PASSWORD = "你的 MySQL 密码"
```

## 4. 首次运行的前提：数据库

```bash
# 后端线按 src/backend/sql 的顺序执行：04_init.sql → 05_存储过程.sql → 06_测试数据.sql
# 然后回到前端：python app.py 或双击 start.bat
```

`04_init.sql` 目前仍是骨架（表里只有主键列），此时页面会显示错误页并提示"数据库字段尚未就绪"，这是预期行为，等后端线补齐字段即可。

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
| ① 借阅 TOP 10 | 按书名分组 `COUNT(*)` 降序 | 含已归还记录 |
| ② 各分类馆藏量 | `Category LEFT JOIN Book LEFT JOIN Copy` | 父分类不含子分类汇总；`COUNT(DISTINCT b.book_id)` 防副本行放大 |
| ③ 当前逾期清单 | `return_date IS NULL AND due_date < CURDATE()` | **不用 `is_overdue = 1`**：那个字段在归还后仍保留 1，会把历史逾期算进来 |
| ④ 每月借阅量 | `DATE_FORMAT(borrow_date, '%Y-%m')` 分组 | 含已归还记录 |

完整 SQL 见 `09_查询样例.sql`，页面输出的数字必须来自实际查询，不能写死。

## 8. 已知限制

1. `src/backend/sql/04_init.sql` 未补齐字段前，所有查询都会报"未知列"，页面走错误页。
2. `renew_book` 没有"只能续借一次"的标记，当前允许重复续借；如需要限制必须改存储过程（后端线范围）。
3. 借阅历史页一次取全部记录，没有分页；测试数据量（15 条）下无影响。
4. 报表②的父分类口径、报表③的逾期口径需向老师确认后同步到本文件与 `09_查询样例.sql`。

## 9. 交付物（12/04 前）

- [x] `app.py` + 模板 + CSS 可运行
- [x] `start.bat` 一键启动（建 venv、装依赖、生成 .env）
- [x] 四张统计报表可用
- [x] `09_查询样例.sql` 汇总页面 SQL
- [ ] `08_前端页面截图/` 放 4 张关键截图（等数据库可用后补）
- [x] README 更新技术选型、路由与口径说明
