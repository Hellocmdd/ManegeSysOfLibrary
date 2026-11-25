# web-style.md — 模板与页面规范

适用：`templates/*.html`、`static/style.css`、页面内少量 JS。技术栈固定为 Jinja2 + 原生 HTML/CSS，不引入前端框架与 CDN。

## 1. 模板结构

- 所有页面继承 `base.html`：导航、页头、消息区、页脚只写一份；子模板只填 `{% block content %}`。
- 一个模板对应一个路由函数，文件名与路由函数同名（`book_list.html` ↔ `def book_list()`）。
- 页面标题、当前高亮菜单、面包屑由子模板通过 block 传入，不靠 JS 改文字。
- 页面必需的上下文变量在路由里一次性传齐；模板内不做查询、不做业务判断以外的数据加工。
- 模板里不写 Python 表达式以外的东西：不 `import`、不调用未注册的函数、不访问 `_` 开头的私有属性。

## 2. 转义与安全

- 默认自动转义必须保持开启；**禁止对用户输入用 `|safe`**，禁止 `{% autoescape false %}`。
- 富文本字段（如 `Book.descr`）只做换行处理：`{{ descr }}` 配合 CSS `white-space: pre-wrap`，不渲染 HTML。
- 所有链接用 `url_for()` 生成；带参数的用 `url_for("reader_history", reader_id=r.reader_id)`。
- 表单 `method` 必须显式写明 `post`，借书/还书/续借**不得用 GET 触发写操作**。
- 表单提交后重定向（PRG），配合 `flash()` 展示结果，避免刷新导致重复借还。

## 3. 表单与校验

- 每个输入控件有 `<label for>`，`name` 与后端读取的参数名一致；必填项加 `required`，但**后端必须再校验一遍**。
- 输入框保留用户已填值（`value="{{ kw or '' }}"`），报错后不清空。
- 错误提示集中在表单上方或页头消息区，文案说清"哪个字段、怎么改"，不写"输入错误"。
- 日期输入用 `<input type="date">`，格式 `YYYY-MM-DD`，不用自由文本猜格式。
- 不使用 `alert()` 做业务提示；统一走 `flash()` 消息区。

## 4. 消息与状态展示

- `flash()` 分类至少区分成功 / 失败两种（`category="ok"` / `"err"`），CSS 用颜色 + 图标/前缀文字双重区分，**不能只靠颜色**。
- 状态值展示用固定映射，不在模板里堆 `if`：

```jinja
{% set status_class = {"在借": "badge-borrow", "已归还": "badge-returned", "已逾期": "badge-overdue"} %}
<span class="badge {{ status_class.get(b.status, 'badge-unknown') }}">{{ b.status }}</span>
```

- 页面上的统计数字必须来自 SQL 查询结果，**不得在模板里写死或估算**；标题旁标注口径（如"当前逾期（未归还）"）。
- 空结果统一显示占位行"暂无数据"，不显示空白表格头。

## 5. 样式

- 单文件 `static/style.css`，按区块注释分组（布局 / 导航 / 表格 / 表单 / 徽章 / 消息）。
- 颜色、字号、间距用 CSS 变量集中在 `:root`，不散落魔法值。
- 表格：`<thead>` + `<tbody>`，数字列右对齐，长文本列限制宽度并省略；行悬停高亮。
- 不做响应式框架，但要保证 1366px 宽下无横向滚动；打印样式不做。
- 不引外部字体、图标库、CDN 的 CSS/JS；图标用 Unicode 或内联 SVG。
- 不写行内 `style="..."`（一次性调试除外，提交前清除）。

## 6. 页面清单与职责

| 页面 | 路由 | 关键内容 | 依赖数据 |
| --- | --- | --- | --- |
| `login.html` | `/login` | 管理员账号密码登录；错误提示 | `Admin` |
| `book_list.html` | `/books` | 书目列表、书名/分类筛选、分页、在馆副本数、借书入口 | `Book`+`Category`+`Copy` |
| `reader_history.html` | `/readers/<id>` | 某读者借阅记录、当前在借、还书/续借按钮 | `Reader`+`Borrow` |
| `reports.html` | `/reports` | 四张报表：热门 TOP10、分类馆藏量、当前逾期清单、每月借阅量 | 聚合查询 |
| `base.html` | — | 导航、消息区、页脚、block 定义 | — |

- 借书入口只在有在馆副本（`is_available=1`）时可用；无副本时按钮置灰并说明原因。
- 读者被禁用（`Reader.status=0`）时，页面明确提示"该读者已禁用"，不给借书入口。

## 7. 无障碍与可读性

- 图片、图表占位有 `alt`；链接文字有实际含义（不写"点击这里"）。
- 表格首行用 `<th scope="col">`。
- 中文页面声明 `<meta charset="utf-8">`；`<html lang="zh-CN">`。
- 页面不自动播放、不弹窗拦截、不需要 JS 也能完成核心流程（借还书的按钮用表单提交）。

## 8. 禁止事项（硬性）

- 禁止 `|safe`、禁止 `render_template_string` 渲染用户内容。
- 禁止 CDN、禁止 `npm`、禁止引入 jQuery / Vue / React / ECharts。
- 禁止模板里写 SQL、写死统计数字、写死测试数据的假结果。
- 禁止用 GET 做写操作、禁止无 `action` 的表单。
- 禁止行内样式、禁止 `<style>` 块散落在页面里（统一进 `style.css`）。
- 禁止只靠颜色表达状态（逾期必须同时有文字）。
