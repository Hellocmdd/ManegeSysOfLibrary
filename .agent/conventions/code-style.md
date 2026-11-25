# code-style.md — 通用代码风格与实现约束

适用：`src/frontend/` 下的 Python、Jinja2 模板、CSS 与少量 JS。Python 细则见 `python-style.md`，SQL 见 `sql-style.md`，模板与页面见 `web-style.md`，注释见 `comment-style.md`。

## 1. 目录与文件

- 只改 `src/frontend/`。`docs/`、`src/backend/sql/` 是只读输入。
- 不新建顶层目录，不改 `docs/00_分工与进度.md` 第四节的目录结构与文件编号（`04_`、`05_`、`06_`、`08_`、`09_` 都由该文件规定）。
- 默认文件集合：`app.py`、`config.py`、`requirements.txt`、`templates/`、`static/style.css`、`08_前端页面截图/`、`09_查询样例.sql`。
- `app.py` 超过约 400 行再考虑拆分（`db.py` / `queries.py` / `reports.py`）；拆分前先确认，并在 `docs/08_前端交付物/README.md` 的目录结构中补登记，不偷偷加文件。
- UTF-8 无 BOM；缩进 4 空格，不用 Tab。**不要在功能提交里顺手改整文件的换行符**，否则 diff 无法审阅。
- 一个模板只负责一个页面；共用区块抽 `base.html` 的 `block`，不复制整段 HTML。

## 2. 命名

| 元素 | 规则 | 示例 |
| --- | --- | --- |
| 模块 | 小写下划线 | `app.py`、`config.py` |
| 函数 / 变量 | 小写下划线 | `query_books`、`reader_id` |
| 类 | 大驼峰 | `BookRow`（少用，优先 `dict`） |
| 常量 | 全大写下划线 | `MAX_BORROW = 5`、`PAGE_SIZE = 20` |
| 布尔 | `is_` / `has_` / `can_` 开头 | `is_available`、`has_overdue` |
| 私有 | 单下划线前缀 | `_build_where` |
| 模板 | 小写下划线 + `.html` | `book_list.html`、`reader_history.html` |
| 路由函数 | 与模板同名（去掉 `.html`） | `def book_list()` 对应 `book_list.html` |

- 字段名与数据库列名保持一致（`copy_id` 不写成 `copyId`），避免在 Python 与 SQL 之间来回改名。
- 不用 `data`、`info`、`temp`、`flag` 这类空泛命名；不用拼音缩写（`jysh` 这类）。
- 存储过程返回码用常量表表达，不散落魔法数字：

```python
BORROW_OK = 0
BORROW_MSG: dict[int, str] = {
    -1: "该副本当前不在馆",
    -2: "读者已被禁用，无法借书",
    -3: "已借满 5 本，请先归还",
    -4: "借书失败，事务已回滚",
}
```

## 3. 函数

- 一个函数只做一件事；超过约 40 行或嵌套超过 3 层就抽函数或提前 `return`。
- 参数超过 4 个时优先用具名参数或传 `dict`，不在调用处靠位置猜含义。
- 不在函数里 `import`；模块顶部统一导入。
- 可复用的查询抽成函数，不在两个路由里复制同一段 SQL。
- 不在循环里逐行查数据库（N+1）；用 `JOIN` 或 `IN` 一次查完。

## 4. 错误处理

- 数据库异常、参数缺失、记录不存在，都要有明确分支与用户可见提示；不吞异常（空 `except`）、不 `print` traceback 给用户。
- `except Exception` 只在路由边界捕获一次，用于 `flash()` + 记日志 + 回退页面；业务层不写宽泛捕获。
- 用户输入先校验（空串、长度、数字范围），再进 SQL；校验失败直接返回提示，不走到 `execute()`。
- 找不到记录时返回空列表或 `None` 并让页面显示"暂无数据"，不用异常控制正常流程。
- 存储过程"静默更新 0 行"（`return_book` / `renew_book` 找不到记录）必须复查状态后再判断成功，不能只看有没有抛异常。

## 5. 输出与日志

- 页面文案用中文；错误提示说清"哪个操作失败、下一步怎么做"，不写 `Error 500`、不暴露 SQL 语句与表结构。
- 调试信息用 `app.logger`，不用 `print`；提交前清掉调试输出。
- 不把数据库连接串、密码、完整 SQL 参数打印到日志。
- 金额、日期、数量等展示格式固定（`YYYY-MM-DD`），同一页面内保持一致。

## 6. 依赖边界

- 运行依赖只有 Flask 与 **PyMySQL**（`requirements.txt` 里就是这两行）；换驱动要先说明理由并改本文件，不要两个驱动同时装。
- `requirements.txt` 保持纯 ASCII：Windows 上 pip 按系统 locale（GBK）解码该文件，UTF-8 中文注释会直接抛 `UnicodeDecodeError`。
- 不用 ORM（SQLAlchemy 等）、不用 pandas 做统计、不引前端框架与 CDN 资源；统计交给 SQL。
- 新增依赖要说明用途、版本与离线可用性，等确认后再加。
- `requirements.txt` 写实际使用的包与版本范围，交付前用 `pip freeze` 核对；不把整个全局环境的包倒进去。

## 7. 确定性

- 每条列表与报表查询都有 `ORDER BY`；分页用 `LIMIT/OFFSET` 且排序键唯一或追加主键兜底。
- 不依赖 `dict` 插入顺序展示报表列；列顺序在模板里写死。
- 统计口径（含不含已归还、含不含子分类）写在页面上，不靠注释解释。
- 日期用数据库的 `CURDATE()` / `NOW()` 或统一取一次传入，不在一个页面里多次取"今天"。

## 8. 禁止事项（硬性）

- 禁止把用户输入拼进 SQL（f-string、`%`、`+`、`.format()` 全部禁止）。
- 禁止把密码、密钥、真实连接串写进代码、模板、README 或截图。
- 禁止在模板里写业务 SQL；SQL 只出现在 Python 的查询函数与 `09_查询样例.sql`。
- 禁止用 `|safe` 渲染用户输入；禁止把 `render_template_string` 用在用户可控内容上。
- 禁止注释掉的死代码入库；要么删，要么留 `TODO(<模块>): <恢复条件>`。
- 禁止为了"页面能显示"而改表结构、改测试数据或写死假数据。
- 禁止复制粘贴同一段 SQL 到多个页面；抽函数或加参数。
