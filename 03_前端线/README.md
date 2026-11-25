# 图书管理系统 · 前端应用线 README

> 作者：段绪礼 · 2026-11-25

## 1. 技术选型

**推荐方案**（请在周会确认）：
- **后端**：Python 3 + Flask（轻量 Web 框架）
- **数据库驱动**：`mysql-connector-python`（官方驱动）或 `PyMySQL`
- **前端**：Jinja2 模板 + 原生 HTML/CSS（作业不需要复杂前端）
- **ORM**：不用 ORM，直接 SQL（让 SQL 功底可见）

备选方案：Python + tkinter（桌面 GUI，不用 Web，适合不想装浏览器的同学）

## 2. 环境准备

```bash
pip install flask mysql-connector-python pymysql
```

## 3. 目录结构

```
03_前端线/
├── app.py              ← Flask 主程序（TODO）
├── config.py           ← 数据库连接配置（TODO：把密码填进去）
├── requirements.txt    ← pip freeze > requirements.txt
├── templates/          ← Jinja2 模板
│   ├── base.html       ← 通用布局（TODO）
│   ├── login.html      ← 登录页（TODO）
│   ├── book_list.html  ← 书籍列表（TODO）
│   ├── reader_history.html  ← 读者借阅历史（TODO）
│   └── reports.html     ← 统计报表（TODO）
├── static/
│   └── style.css       ← 自定义样式（TODO）
└── 08_前端页面截图/     ← 完成后截图放这里
```

## 4. 数据库连接配置（config.py）

```python
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',           # 谭博友告诉我实际账号
    'password': '123456',     # TODO：换成你自己机器的 MySQL 密码
    'database': 'library_system',
    'charset': 'utf8mb4',
}
```

## 5. 启动步骤（后端先跑 init.sql）

```bash
# 1. 谭博友那边建库 + 建表 + 插入测试数据
# 2. 你这边启动 Flask
python app.py
# 3. 浏览器访问 http://localhost:5000
```

## 6. 必须实现的功能清单

| 功能 | 页面 | 核心 SQL |
|------|------|----------|
| 读者登录 | login.html | SELECT * FROM Reader WHERE reader_id=? AND name=? |
| 管理员登录 | login.html | SELECT * FROM Admin WHERE account=? AND pwd=SHA2(?,256) |
| 书籍列表（全部） | book_list.html | SELECT b.*, c.cat_name FROM Book b JOIN Category c ON b.cat_id=c.cat_id |
| 按分类筛选 | book_list.html | 上面加 WHERE b.cat_id=? |
| 按书名搜索 | book_list.html | 上面加 WHERE b.title LIKE %?% |
| 副本在馆状态 | book_list.html | SELECT * FROM Copy WHERE book_id=? |
| 读者借阅历史 | reader_history.html | SELECT br.*, b.title FROM Borrow br JOIN Copy c ON br.copy_id=c.copy_id JOIN Book b ON c.book_id=b.book_id WHERE reader_id=? |
| 借书操作 | 按钮触发 | CALL borrow_book(reader_id, copy_id) |
| 还书操作 | 按钮触发 | CALL return_book(borrow_id, admin_id) |
| 续借操作 | 按钮触发 | CALL renew_book(borrow_id) |
| ① 热门 TOP10 | reports.html | SELECT b.title, COUNT(*) AS cnt FROM Borrow br JOIN Copy c ON br.copy_id=c.copy_id JOIN Book b ON c.book_id=b.book_id GROUP BY b.book_id ORDER BY cnt DESC LIMIT 10 |
| ② 各分类馆藏量 | reports.html | SELECT cat.cat_name, COUNT(b.book_id) FROM Category cat LEFT JOIN Book b ON cat.cat_id=b.cat_id GROUP BY cat.cat_id |
| ③ 逾期清单 | reports.html | SELECT r.name, b.title, br.due_date FROM Borrow br JOIN Reader r ON br.reader_id=r.reader_id JOIN Copy c ON br.copy_id=c.copy_id JOIN Book b ON c.book_id=b.book_id WHERE br.is_overdue=1 |
| ④ 每月借阅量 | reports.html | SELECT DATE_FORMAT(borrow_date,'%Y-%m') AS m, COUNT(*) FROM Borrow GROUP BY m ORDER BY m |

## 7. 最终交付物（12/04 前）

- [ ] `app.py` + 所有模板 + CSS 能跑通
- [ ] 四张统计报表都能用（给老师看的亮点）
- [ ] `08_前端页面截图/` 里放 4-6 张关键截图并标注
- [ ] README 更新接口使用说明

---

*v1.0 · 2026-11-25 · 段绪礼*
