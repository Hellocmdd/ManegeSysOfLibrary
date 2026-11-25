# sql-style.md — SQL 专项规范

适用：Python 里的查询语句、`docs/08_前端交付物/09_查询样例.sql`、报表统计。**只写 SELECT**；DDL 与业务 DML 属后端线，前端不得代劳。

## 1. 参数化

- 应用代码里所有可变值走占位符 `%s`，一条语句一个 `params` 元组/列表；`LIKE` 的通配符放参数值里。
- 拼接仅允许"结构性片段"（固定的 `ORDER BY` 白名单项、固定的 `WHERE` 子句组合），且必须由代码里的常量表控制，绝不接收用户原始字符串。
- 排序字段用映射表转换，禁止直接拼 `sort` 参数：

```python
ORDER_BY: dict[str, str] = {
    "title": "b.title",
    "pub_date": "b.pub_date",
    "borrow_count": "borrow_count DESC",
}
order_clause = ORDER_BY.get(sort_key, "b.title")   # 白名单外的值一律回落默认
```

- 数字类参数先 `int()` 转换并校验范围，再入参。

## 2. 语句写法

- 不用 `SELECT *`：列名写全，模板里按列名取值，表结构变动时问题能立刻暴露。
- 显式 `JOIN ... ON`，不用逗号连接 + `WHERE` 关联。
- 表用别名（`br`、`b`、`c`、`r`、`a`）并全语句统一；别名不用单字母以外的随意缩写。
- 每条面向页面的查询都有 `ORDER BY`，排序键不唯一时追加主键兜底（`ORDER BY borrow_date DESC, borrow_id DESC`）。
- 分页用 `LIMIT %s OFFSET %s`；总数与当页数据分两条语句，参数一致。
- 时间范围用闭开区间：`borrow_date >= %s AND borrow_date < %s`，避免 `BETWEEN` 在 DATETIME 上丢边界。
- 不用 `NOT IN` 接子查询（含 `NULL` 时结果为空），用 `NOT EXISTS` 或 `LEFT JOIN ... IS NULL`。
- 字符串比较走列排序规则，不在 SQL 里做 `LOWER()` 的隐式全表扫描；需要不区分大小写时说明原因。

## 3. 聚合与口径

- `COUNT` 与 `LEFT JOIN` 同时出现时，必须确认不会重复计数：多表 JOIN 后按书目统计要用 `COUNT(DISTINCT b.book_id)`，按副本统计用 `COUNT(c.copy_id)`。
- 《馆藏量》按**副本数**（`Copy`）计，不是书目数（`Book`）；页面标题与注释都要写清口径。
- 分类统计若要求"含子分类"，用 MySQL 8 的递归 CTE（`WITH RECURSIVE`）或后端提供的视图；不假设只有两级。
- 逾期清单口径固定为**当前未归还且已过应还日期**：

```sql
WHERE br.return_date IS NULL AND br.due_date < CURDATE()
```

  `Borrow.is_overdue = 1` 包含"曾逾期但已归还"的历史记录（测试数据里 BR005、BR015 就是这种），直接用它当"当前逾期"会多算。若页面要展示"逾期历史"，就换标题并单独查询，两种口径不混用。
- `Reader.status = 0` 是禁用；统计读者数时说明是否含禁用读者。
- 日期维度用 `DATE_FORMAT(borrow_date, '%Y-%m')`，并按同一表达式分组与排序，避免 `ONLY_FULL_GROUP_BY` 报错。
- 统计结果为空时返回 `0` 或空列表均可，但页面必须能显示"0 / 暂无数据"，不得因空结果报错。

## 4. 存储过程调用

- 签名以 `src/backend/sql/05_存储过程.sql` 为准，**不照抄 `docs/08_前端交付物/README.md` 里的旧写法**：

| 过程 | 真实调用 | 结果获取 |
| --- | --- | --- |
| `borrow_book` | `CALL borrow_book(%s, %s, @p_result)` | 消费结果集后 `SELECT @p_result` |
| `return_book` | `CALL return_book(%s, %s)` | 复查 `Borrow` 行（`status`、`return_date`） |
| `renew_book` | `CALL renew_book(%s)` | 复查 `Borrow.due_date` 是否变大 |

- 返回码 `0/-1/-2/-3/-4` 必须逐分支给中文提示，未知码归入 `-4` 的文案，不能只判断"不等于 0"。
- 过程内部已有事务与 `EXIT HANDLER`，调用方不要再包 `START TRANSACTION`。

## 5. 验证

- 新写或修改的每条查询，必须在真实库上跑一次，并把结果条数与关键数字写进提交说明或 PR 描述。
- 对照 `06_测试数据.sql` 的基线自检：热门 TOP10 的榜首、逾期清单的条数、某分类的馆藏量，都能手工数出来核对。
- 分页语句要验证"最后一页不满 / 超出总页数返回空列表"两种情况。
- 慢查询（`EXPLAIN` 出现 `ALL` 且表大）先看能否加索引，加索引属后端线，前端只反馈。

## 6. 已知阻塞

- `src/backend/sql/04_init.sql` 目前只建了主键列，其余字段是 `-- TODO`；在补齐之前，任何按完整字段写的查询都会报"未知列"。
- 遇到这种情况，按 `N1` 处理：**停手并反馈**，不自己改 `04_init.sql`、不自己建表、不改 `06_测试数据.sql` 迁就。

## 7. 禁止事项（硬性）

- 禁止字符串拼接用户输入。
- 禁止前端写 `CREATE / ALTER / DROP / TRUNCATE / INSERT / UPDATE / DELETE`（存储过程与测试数据由后端线维护）。
- 禁止用 `SELECT *`、禁止无 `ORDER BY` 的列表查询。
- 禁止在 SQL 注释里写"临时""先这样"而不留 `TODO(前端):`。
- 禁止为了绕开字段缺失而写死假数据或注释掉 `WHERE` 条件。
