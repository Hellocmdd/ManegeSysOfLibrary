# python-style.md — Python 专项规范

适用于 `src/frontend/` 下所有 `.py` 文件。**类型注解与 docstring 是硬性要求，不是建议**；没有类型注解和 docstring 的函数视为未完成。

## 1. 类型注解

### 1.1 强制范围

- 每个函数、方法的**每个参数**和**返回值**都必须标注。
- 没有返回值标 `-> None`，不要省略。
- 模块级常量、配置字典标注类型。
- 局部变量在类型不明显时标注（`rows: list[dict[str, Any]] = ...`）；一眼能看出的不标。

### 1.2 写法

用 Python 3.9+ 的内置泛型与 3.10+ 的联合类型（本项目环境 Python 3.11）：

```python
from typing import Any, Callable

MAX_BORROW: int = 5
DB_CONFIG: dict[str, Any] = {...}

def query_all(sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
    ...

def query_one(sql: str, params: tuple[Any, ...] = ()) -> dict[str, Any] | None:
    ...

def find_reader(reader_id: str) -> dict[str, Any] | None:
    ...

def is_overdue(due_date: date, today: date) -> bool:
    ...

def build_filters(title: str | None, cat_id: str | None) -> tuple[str, list[Any]]:
    ...
```

- 用 `list[str]` / `dict[str, Any]` / `tuple[bool, str]`，**不用** `typing.List` / `typing.Dict` / `typing.Optional`。
- 参数与返回类型必须显式写出，例如 `def add(a: int, b: int) -> int:`（紧凑写法 `add(a:int,b:int)->int` 也可接受，但**同一仓库只选一种**，不混用）。
- 用 `X | None`，不用 `Optional[X]`；用 `X | Y`，不用 `Union[X, Y]`。
- 可调用对象标 `Callable[[int], str]`，不要留裸 `Callable`。
- 数据库行统一是 `dict[str, Any]`（`cursor(dictionary=True)`），并在 docstring 的 `*Return` 里写清用到的列名。
- `Any` 只允许出现在数据库行、`**kwargs`、配置字典三处。业务函数的入参与返回值**不许用 `Any`**——宁可定义一个 `TypedDict` 或明确的 `dict[str, str]`。
- 不用 `# type: ignore` 掩盖真实类型问题；确需忽略时行尾写原因：`# type: ignore[arg-type]  # 驱动把 int 当 str 收`。

### 1.3 签名与实现一起改

改函数时同步改类型注解与 docstring；不允许签名说 `-> tuple[bool, str]`、实现却 `return None`。

## 2. docstring 格式（项目统一，不得自创风格）

每个函数都必须有 docstring，结构固定为三段：摘要 + `*Args:` + `*Return:`。可选第四段 `*Raises:`。

```python
def borrow_book(reader_id: str, copy_id: str) -> tuple[bool, str]:
    """
    调用存储过程借出一本图书，并把返回码翻译成中文提示。

    *Args:
        reader_id: 读者编号，对应 Reader.reader_id，非空字符串。
        copy_id: 副本编号，对应 Copy.copy_id，必须是在馆副本（is_available=1）。
    *Return:
        (是否成功, 提示文案)。成功为 (True, "借书成功，应还日期 ...")；
        失败为 (False, 具体原因)，原因为空时用 "借书失败，请稍后重试"。
    """
```

规则：

1. docstring 用 `"""` 包裹，**首行是一句话摘要**（动词开头、句号结尾、不超过 40 字），摘要后空一行再写 `*Args:`。
2. `*Args:` 每个参数一行、缩进 4 空格、格式 `参数名: 说明`；**说明写约束不写类型**（类型在签名里）：取值范围、能否为 `None`、来自哪张表的哪列、单位、默认值含义。
3. 没有参数写 `*Args: 无`；没有返回值写 `*Return: 无`。两者都不能省。
4. `*Return:` 写**语义**而不是重复类型：空列表与 `None` 的区别、元组每个位置的含义、失败时的返回值形态。
5. 失败用返回值表达时写 `*Return:`；抛异常时才写 `*Raises:`，格式 `异常类型: 触发条件`。
6. 中文、全角标点；不在 docstring 里写作者、日期、修改记录（版本信息交给 git）。
7. 私有工具函数（`_` 前缀）也照此格式，摘要可以只有一句，但 `*Args` / `*Return` 不能省。
8. 模块顶部要有模块级 docstring：一句话说明该模块职责；`app.py` 里再补一段启动方式。

模块与类：

```python
"""
本模块集中存放前端用到的 SQL 查询与报表语句，所有语句均为参数化写法。
"""


class DbError(Exception):
    """
    数据库访问失败的统一异常。

    *Args:
        无（通过父类 Exception 传入消息）。
    *Return:
        无。
    """
```

## 3. 模块组织与导入

- 导入顺序：标准库 → 第三方 → 本项目；组间空一行。不用 `from x import *`。
- 只导入用到的名字；`import mysql.connector` 后在调用处写全名或用 `from mysql.connector import Error`。
- 避免循环导入：查询函数放 `queries.py`，只依赖 `db.py`，不反向依赖 `app.py`。
- 不在函数内部 `import`（除非为可选的开发依赖，且要注释原因）。

## 4. Flask 路由

```python
@app.get("/books")
def book_list() -> str:
    """
    图书列表页，支持按书名模糊查询与按分类过滤。

    *Args:
        无（入参来自 request.args：title、cat_id，均可为空）。
    *Return:
        渲染后的 HTML 字符串。
    """
```

- 用 `@app.get` / `@app.post` 明确方法，不用裸 `@app.route` 兜底所有方法。
- 模板里一律 `url_for("book_list")`，不写死 `/books`。
- 表单提交成功后 `redirect(url_for(...))`（PRG 模式），避免刷新重复提交借还书。**借书、还书禁止用 GET**。
- 路由函数只做：取参 → 校验 → 调查询/存储过程 → 渲染；SQL 与业务分支不写在路由里。
- 登录校验用统一装饰器 `@login_required`，不每个路由复制 `if "admin_id" not in session`。
- 首屏与关键列表的查询结果为空时，页面显示"暂无数据"占位，不 500。

## 5. 数据库访问

- 每个请求一个连接：`g.db` 在 `before_request` 建立、`teardown_appcontext` 关闭；**不用模块级全局连接**（会串事务、断线后全站失效）。
- 用 `cursor(dictionary=True)` 让行是 `dict`，模板里按列名取值；取完 `cursor.close()`。
- 全部参数化：`cursor.execute(sql, params)`，占位符用驱动对应的 `%s`。
- `LIKE` 的 `%` 放在参数值里：`params.append(f"%{kw}%")`，SQL 里写 `LIKE %s`。
- 调用带 OUT 参数的存储过程，必须按三步走：

```python
cursor.execute("CALL borrow_book(%s, %s, @p_result)", (reader_id, copy_id))
while cursor.nextset():   # 消费掉过程产生的空结果集，否则下一条语句报 "Unread result found"
    pass
cursor.execute("SELECT @p_result AS result")
row = cursor.fetchone()
result_code = int(row["result"]) if row else -4
```

- 只查一次 `@p_result`，不要把 `CALL` 与 `SELECT @p_result` 合并成一条多语句执行（驱动默认不开 `multi_statements`）。
- `return_book` / `renew_book` 没有返回码：执行后用 `SELECT status, return_date, due_date FROM Borrow WHERE borrow_id=%s` 复查，按复查结果决定提示；不要用 `cursor.rowcount` 判断（`CALL` 的 rowcount 不可靠）。
- 事务：默认 autocommit 关闭时，写操作后显式 `conn.commit()`；异常时 `conn.rollback()`。存储过程内部已开事务，前端不再包一层手工事务。
- 连接参数从 `config.py` 读，不在调用处写死 host/port。
- 捕获 `mysql.connector.Error`（或 `pymysql.err.OperationalError` 等），转换成 `DbError` 并带上错误码，不把原始 SQL 抛给页面。

## 6. 配置与密钥

```python
import os

DB_CONFIG: dict[str, Any] = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),
    "database": os.getenv("DB_NAME", "library"),
    "charset": "utf8mb4",
}
SECRET_KEY: str = os.getenv("FLASK_SECRET_KEY", "dev-only-change-me")
```

- 密码、密钥只能来自环境变量或 `config_secret.py`（`.gitignore` 已忽略）；**`config.py` 里不得出现真实密码**，README 里的示例密码 `123456` 不得照抄进代码。
- 启动时校验必需配置（`DB_PASSWORD` 为空则打印明确提示并退出），不要带着空密码进查询再报莫名其妙的错。
- 提交的入口默认 `debug=False`；本地调试用 `FLASK_DEBUG=1` 或 `app.run(debug=...)` 显式打开，调试开关不进交付版本。

## 7. 测试与验证

- 测试放 `src/frontend/tests/`，文件名 `test_*.py`，用 `pytest`；测试依赖写进 `requirements-dev.txt`，不混进运行依赖。
- 覆盖顺序按 `test-writer.md` 的 F1–F9 矩阵；数据库相关用例只读或自带清理，不污染 `06_测试数据.sql` 的基线。
- 手工验证过的结论要写清"跑了什么、看到什么数字"，不能只写"已验证"。

## 8. 禁止事项（硬性）

- 禁止无类型注解、无 docstring 的函数入库。
- 禁止 f-string / `%` / `+` / `.format()` 拼接 SQL。
- 禁止模块级全局连接、全局游标。
- 禁止在业务代码里写提示词、写 `TODO` 之外的自然语言指令。
- 禁止 `print` 做日志、禁止 `except: pass`、禁止把 traceback 渲染到页面。
- 禁止在 Python 里做本该 SQL 完成的统计（分组、聚合、排序、分页）。
