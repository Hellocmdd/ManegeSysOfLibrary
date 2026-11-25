# db-contract.md — 前端依赖的数据库契约

本文件描述**前后端共同遵守的数据库事实**，以及与文档不一致、需要联调的地方。`src/backend/sql/04_init.sql` 是六张表结构的唯一权威定义，`05_存储过程.sql` 是三个过程的唯一权威定义；`src/backend/sql/java/` 下的三份脚本是同步副本。本文件只做摘要，不复制整份建表脚本。

## 1. 表与前端用到的列

| 表 | 主键 | 前端实际读写的列 | 备注 |
| --- | --- | --- | --- |
| `Reader` | `reader_id` VARCHAR(32) | `reader_id`、`name`、`sex`、`phone`、`status` | `status`：1 正常 / 0 禁用 |
| `Admin` | `admin_id` | `admin_id`、`name`、`account`（唯一）、`pwd`、`role` | `pwd` 存 SHA256 十六进制，前端只校验不落库 |
| `Category` | `cat_id` | `cat_id`、`cat_name`、`parent_id` | `parent_id` 自引用，根节点 `parent_id IS NULL` |
| `Book` | `book_id` | `book_id`、`isbn`、`title`、`author`、`publisher`、`pub_date`、`descr`、`cat_id` | `descr` 是长文本 |
| `Copy` | `copy_id` | `copy_id`、`book_id`、`asset_no`（唯一）、`location`、`is_available` | `is_available`：1 在馆 / 0 借出 |
| `Borrow` | `borrow_id` | `borrow_id`、`reader_id`、`copy_id`、`admin_id`、`borrow_date`、`due_date`、`return_date`、`status`、`is_overdue`、`handle_time` | `admin_id` 在自助借书时可为 `NULL` |

- 一个 `Book` 对应多条 `Copy`；借还是**按副本**操作，页面上的"可借"数量来自 `Copy.is_available = 1` 的计数。
- 日期列是 `DATE`，时间列是 `DATETIME`；`handle_time` 是经办时间，可能为空。

## 2. 状态枚举

| 列 | 取值 | 含义 |
| --- | --- | --- |
| `Reader.status` | `1` / `0` | 正常 / 禁用（禁用不得借书） |
| `Copy.is_available` | `1` / `0` | 在馆可借 / 已借出 |
| `Borrow.status` | `在借` / `已归还` / `已逾期` | 书借还状态的中文枚举，前端按**中文原值**比较，不要自己另造 `borrowed` 之类的值 |
| `Borrow.is_overdue` | `0` / `1` | 是否曾经逾期（还书时按当时是否超期写入），**不等于"当前逾期"** |

## 3. 存储过程

### 3.1 `borrow_book`

```
borrow_book(IN p_reader_id VARCHAR(32), IN p_copy_id VARCHAR(32), OUT p_result INT)
```

| `p_result` | 含义 | 前端提示 |
| --- | --- | --- |
| `0` | 借出成功 | 借书成功，应还日期为 30 天后 |
| `-1` | 副本不存在或不在馆 | 该副本当前不在馆，请换一本 |
| `-2` | 读者被禁用 | 该读者已禁用，无法借书 |
| `-3` | 该读者在借已达 5 本 | 已借满 5 本，请先归还 |
| `-4` | 其他错误（过程内已 `ROLLBACK`） | 借书失败，请稍后重试 |

- 必须用 `CALL borrow_book(%s, %s, @p_result)`，再 `SELECT @p_result`；`docs/08_前端交付物/README.md` 里的两参写法是旧稿，已失效。
- 借期固定 30 天，由过程计算，前端不自己算 `due_date`。

### 3.2 `return_book`

```
return_book(IN p_borrow_id VARCHAR(32), IN p_admin_id VARCHAR(32))
```

- 无返回值。成功时写入 `return_date = CURDATE()`、`status = '已归还'`、`admin_id`、`handle_time = NOW()`、`is_overdue = (due_date < CURDATE())`，并把对应 `Copy.is_available` 置 1。
- **记录不存在或已归还时不会报错，只是更新 0 行**。前端必须复查该 `borrow_id` 的 `status` 与 `return_date` 后再提示成功，不能凭"没抛异常"判定成功。

### 3.3 `renew_book`

```
renew_book(IN p_borrow_id VARCHAR(32))
```

- 无返回值。成功时 `due_date` 顺延 30 天、`status = '在借'`、`is_overdue = 0`，条件为 `return_date IS NULL`。
- 同样会静默更新 0 行，前端需复查 `due_date` 是否变大。
- **过程没有"只能续借一次"的字段**：页面若要限制续借次数，只能按 `Borrow` 现有字段自行判断并在报告中说明局限，或向后端线提需求，不得声称数据库已实现该约束。

## 4. 报表口径

| 报表 | 口径 | 注意事项 |
| --- | --- | --- |
| 热门图书 TOP10 | 按 `Borrow` 中借阅次数分组降序取 10 | 统计的是借阅记录条数；同一书多次借阅累计；并列时追加 `book_id` 保证结果稳定 |
| 各分类馆藏量 | 按 `Category` 左连接统计**副本数** | 应为 `COUNT(c.copy_id)`（经 `Book`→`Copy`），不是书目数；空分类要显示 0；是否含子分类需明确并在页面标注 |
| 当前逾期清单 | `return_date IS NULL AND due_date < CURDATE()` | 不要用 `is_overdue = 1` 直接当"当前逾期"，它会带出"曾逾期但已归还"的历史记录 |
| 每月借阅量 | `DATE_FORMAT(borrow_date, '%Y-%m')` 分组计数 | 分组与排序用同一表达式；月份无数据时是否补 0 需说明 |

## 5. 口径状态与已知差异

1. **表结构已统一**：`04_init.sql` 是六张表的唯一权威定义，字段、CHECK、外键与统一排序规则均已补齐；`src/backend/sql/java/create_tables.sql`、`insert_data.sql`、`query.sql` 是同口径同步副本，修改需先改权威文件再同步。
2. **过程调用写法已同步**：前端 README 与本文档均使用三参 `CALL borrow_book(%s, %s, @p_result)`，并以 `05_存储过程.sql` 为准。
3. **逾期口径已统一**：报表只用 `return_date IS NULL AND due_date < CURDATE()`；`is_overdue = 1` 只表示曾逾期，不得当作当前逾期。
4. **配置示例含明文密码**：前端 README 的 `config.py` 示例写了 `password: '123456'`，实现时改为环境变量（见 `python-style.md` 第 6 节）。
5. **续借次数无字段**：见 3.3，过程不限制续借次数，需在报告"不足与改进"里如实写。
6. **真库集成已通过**：`DatabaseIntegrationTest` 7 个用例与前端 `test_live_db_smoke` 均已执行通过；执行中发现并修复了 `BR003` 日期基线错误与存储过程字符串排序规则冲突，详见 `docs/06_测试与优化/功能测试报告.md`。

## 6. 自检方式

- 对着 `06_测试数据.sql` 手工数：管理员 10、分类 11、读者 10、书籍 20、副本 30、借阅 15；`Copy.is_available = 0` 的副本应让对应书目显示"无可借"；`BR004`、`BR009` 是当前逾期，`BR005`、`BR015` 已归还但曾逾期（`is_overdue = 1` 共 4 条）——用这四条验证逾期口径是否正确。
- 借书成功一条、失败一条（对 `is_available = 0` 的副本再借）各跑一次，核对返回码与提示文案。
- 统计类查询的结果条数与总和，与直接 `SELECT COUNT(*)` 的结果对得上。
- 发现本文件与 `.sql` 不一致时，在 PR 描述里指出，不自行择一执行。
