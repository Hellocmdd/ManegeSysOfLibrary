# release.md — 交付

截止 **2026-12-04**。无 CI，全部手动执行；本文件是交付前的执行清单，不是建议。

## 1. 交付物清单

| 交付物 | 位置 | 完成标准 |
| --- | --- | --- |
| SQL 脚本 | `src/backend/sql/04_init.sql`、`05_存储过程.sql`、`06_测试数据.sql` | 空库上按顺序执行无报错；表、过程、数据齐全 |
| 前端源码 | `src/frontend/app.py`、`config.py`、`requirements.txt`、`templates/`、`static/` | 按 README 步骤能起、能走通主流程 |
| 页面截图 | `08_前端页面截图/` | 来自真实运行页面，文件名体现页面与状态 |
| 查询样例 | `src/frontend/09_查询样例.sql` | 每条可单独执行，注释写明用途与口径 |
| 文档 | 根 `README.md`、各线 `README.md`、报告 | 启动步骤可复现；无占位符；无明文密码 |
| 打包 | `姓名+学号.zip` | 解压后可直接按 README 跑起来 |

## 2. 环境冻结

1. 在干净虚拟环境里按 README 从零装一遍：`python -m venv .venv` → 激活 → `pip install -r src/frontend/requirements.txt`。
2. `pip freeze > /tmp/freeze.txt`，核对 `requirements.txt` 里列的版本与实际一致；不把整个全局环境倒进去。
3. 记录版本号写进 README：Python、MySQL、Flask、MySQL 驱动。
4. 数据库侧：`SELECT VERSION();` 记下 MySQL 版本；确认字符集 `utf8mb4`、引擎 `InnoDB`。
5. 换一台机器（或删库重建）验证一次，确认不依赖本机残留状态。

## 3. 数据库导出与重建

```powershell
# 导出结构与数据（含存储过程）到仓库外的临时位置，避免污染目录编号
mysqldump -u root -p --default-character-set=utf8mb4 --routines --databases library > $env:TEMP\library_dump.sql

# 重建验证：先建空库，再按顺序导入
mysql -u root -p --default-character-set=utf8mb4 -e "DROP DATABASE IF EXISTS library; CREATE DATABASE library DEFAULT CHARACTER SET utf8mb4;"
mysql -u root -p --default-character-set=utf8mb4 library < $env:TEMP\library_dump.sql
```

- 重建后核对行数：读者 10、图书 20、副本 30、借阅 15。
- 导出文件里若出现真实密码（连接串、`IDENTIFIED BY`），改掉后再提交。
- 导出物默认不提交；确需随交付提交时，先按 `00_分工与进度.md` 的登记表申请编号，不自行起编号。

## 4. 截图归档

必须覆盖并逐张核对：登录页（含错误提示状态）、图书列表（含筛选条件与分页）、借书成功提示、还书/续借结果、报表页（四张表同屏或分屏）、读者借阅历史。

- 分辨率不低于 1280 宽，窗口不要带本机无关内容（浏览器书签、桌面图标）。
- 截图里的数据必须是真实运行结果，不用画图软件修数字。
- 文件名如 `03_图书列表_按分类筛选.png`，正文引用时配一句说明"展示了什么、说明哪个功能"。
- 改了页面后旧截图必须重截，不留与实现不一致的图。

## 5. 文档收尾

- 根 `README.md`：项目简介、目录说明、环境要求、从零启动步骤、已知限制。
- `src/frontend/README.md`：页面清单、路由、依赖的存储过程与真实签名、验证记录、已知问题。
- 已知限制如实写：`init.sql` 字段补齐情况、续借次数无数据库约束、读者登录只校验 `reader_id + name`、逾期口径。
- 全仓搜索 `TODO(`：每条要么已解决、要么写明阻塞与依赖方；交付版本不留无主 TODO。
- 搜索 `password`、`123456`、`root`：确认没有真实凭据。

## 6. 打包

1. 顶层目录保留 `docs/`、`src/backend/sql/`、`src/frontend/`、`00_分工与进度.md`、`README.md`、`LICENSE`。
2. 排除：`.git/`、`.venv/`、`__pycache__/`、`*.pyc`、`.env`、`config_secret.py`、`.vscode/`、`*.log`、`.agent/`。
3. ZIP 命名 `姓名+学号.zip`（格式固定，内容按成员分工填写）。
4. 解压到新目录，按 README 走一遍启动流程，确认能跑通再提交。

## 7. 交付前检查表

- [ ] 空库执行三个 SQL 脚本无报错，行数与基线一致（10/20/30/15）
- [ ] 存储过程用真实签名调用成功（`borrow_book` 三参 + `@p_result`）
- [ ] 借书四个返回码各触发一次，提示文案正确
- [ ] 还书、续借的复查逻辑有效（重复还书提示"已归还/不存在"）
- [ ] 四张报表有数据、有 `ORDER BY`、口径写在页面上
- [ ] 当前逾期清单 2 条（BR004、BR009），不含 BR005、BR015
- [ ] 未登录访问受保护页会跳转登录
- [ ] 截图齐全且与当前实现一致
- [ ] `requirements.txt` 与干净环境安装结果一致
- [ ] 全仓无明文密码、无 `.env`、无 `__pycache__`
- [ ] `TODO(` 清理完毕
- [ ] ZIP 解压后可复现

## 8. 演示脚本（5 分钟）

1. 登录（`admin / 123456`）→ 首页图书列表，展示按书名查询与分页。
2. 选一本有在馆副本的书 → 借出 → 展示成功提示与应还日期（30 天后）。
3. 对已借出副本再借 → 展示"不在馆"失败提示（证明返回码处理）。
4. 打开读者借阅历史 → 归还 → 展示状态变为"已归还"、副本恢复可借。
5. 打开报表页 → 逐张说明口径（尤其逾期清单为什么不含已归还记录）。
6. 说明不足：字段补齐、续借约束、登录校验方式。

## 9. 禁止事项（硬性）

- 禁止把 `.venv/`、`.git/`、`.agent/`、日志、临时文件打进 ZIP。
- 禁止用修图后的截图、编造的统计数字、没跑过的"已通过"。
- 禁止在交付版本里保留明文密码或真实连接串。
- 禁止在截止后才补的项上写"已完成"；来不及就写清"未完成 + 影响"。
