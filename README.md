# 图书管理系统 · 数据库大作业

> **小组**：张展博（建模）· 谭博友（后端）· 段绪礼（前端）
> **数据库**：MySQL 8.0 · InnoDB · utf8mb4
> **代码托管**：GitCode
> **截止**：2026-12-04

## 快速开始

```bash
# 1. 克隆仓库（GitCode 地址 TODO）
git clone <repo_url>
cd 数据库大作业

# 2. 后端环境（谭博友负责写）
mysql -u root -p
source 02_后端线/04_init.sql;    # 建库建表
source 02_后端线/05_存储过程.sql;
source 02_后端线/06_测试数据.sql;

# 3. 前端环境（段绪礼负责写）
pip install flask mysql-connector-python
python 03_前端线/app.py            # 浏览器访问 http://localhost:5000
```

## 目录结构

见 `00_分工与进度.md` 第五节。

## 同步机制

每周二、周五晚 8:00 腾讯会议 15 分钟，**禁止跳过**。详情见 `00_分工与进度.md` 第四节。

## 提交方式

最终打包为 zip，以 **张展博+2024302111213.zip** 命名提交给老师。
