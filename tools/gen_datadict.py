# -*- coding: utf-8 -*-
"""生成图书管理系统数据字典 xlsx（6 张表，A4 宽列友好）
纯标准库实现，不依赖 openpyxl。
"""
import zipfile, os, time

OUT = r"c:\Users\23506\Desktop\杂物\ManegeSysOfLibrary\01_设计线\03_数据字典.xlsx"

NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"

def col(n):
    s = ""
    while n:
        n, r = divmod(n - 1, 26)
        s = chr(65 + r) + s
    return s

# 每张表的字段定义：(字段名, 类型, 长度, 可空, 默认值, 约束, 说明)
TABLES = [
    {
        "name": "Reader", "comment": "读者",
        "fields": [
            ("reader_id", "VARCHAR", 32,  "NO",  "",       "PK",     "读者编号，唯一主键"),
            ("name",      "VARCHAR", 50,  "NO",  "",       "",       "真实姓名"),
            ("sex",       "ENUM",    2,   "NO",  "'男'",   "",       "性别：男/女"),
            ("phone",     "VARCHAR", 20,  "YES", "NULL",   "",       "联系电话，可空"),
            ("email",     "VARCHAR", 100, "YES", "NULL",   "",       "邮箱"),
            ("reg_date",  "DATE",    0,   "NO",  "CURDATE()","",     "注册日期"),
            ("status",    "TINYINT", 1,   "NO",  "1",      "CHECK(0/1)", "账户状态：1正常/0禁用"),
        ],
    },
    {
        "name": "Admin", "comment": "管理员（公司职员）",
        "fields": [
            ("admin_id", "VARCHAR", 32,  "NO", "",      "PK",          "管理员编号，唯一主键"),
            ("name",     "VARCHAR", 50,  "NO", "",      "",            "真实姓名"),
            ("account",  "VARCHAR", 50,  "NO", "",      "UK(唯一)",    "登录账号"),
            ("pwd",      "VARCHAR", 255, "NO", "",      "",            "密码，SHA256 哈希存储，禁止明文"),
            ("role",     "ENUM",    10,  "NO", "'普通'", "",            "角色：普通/超级"),
        ],
    },
    {
        "name": "Category", "comment": "分类（支持多级父子关系）",
        "fields": [
            ("cat_id",   "VARCHAR", 32,  "NO",  "",     "PK",                     "分类编号"),
            ("cat_name", "VARCHAR", 50,  "NO",  "",     "",                       "分类名称，如 计算机"),
            ("parent_id","VARCHAR", 32,  "YES", "NULL", "FK→Category.cat_id",     "父分类编号，根节点为 NULL"),
        ],
    },
    {
        "name": "Book", "comment": "书籍（书名等共享信息，不含副本）",
        "fields": [
            ("book_id",   "VARCHAR", 32,  "NO",  "",       "PK",              "书籍编号"),
            ("isbn",      "VARCHAR", 20,  "YES", "NULL",   "",                "ISBN 国际标准书号"),
            ("title",     "VARCHAR", 200, "NO",  "",       "",                "书名"),
            ("author",    "VARCHAR", 100, "YES", "NULL",   "",                "作者，可多作者逗号分隔"),
            ("publisher", "VARCHAR", 100, "YES", "NULL",   "",                "出版社"),
            ("pub_date",  "DATE",    0,   "YES", "NULL",   "",                "出版日期"),
            ("descr",     "TEXT",    0,   "YES", "NULL",   "",                "简介/目录，长文本"),
            ("cat_id",    "VARCHAR", 32,  "YES", "NULL",   "FK→Category.cat_id","所属分类编号"),
        ],
    },
    {
        "name": "Copy", "comment": "书籍副本（实际借还的对象）",
        "fields": [
            ("copy_id",      "VARCHAR", 32,  "NO", "",       "PK",              "副本编号"),
            ("book_id",      "VARCHAR", 32,  "NO", "",       "FK→Book.book_id",  "所属书籍编号"),
            ("asset_no",     "VARCHAR", 32,  "NO", "",       "UK(唯一)",         "馆藏编号，贴在书脊上的标签号"),
            ("location",     "VARCHAR", 100, "YES", "NULL",  "",                "存放位置，如 二楼A区-01架"),
            ("is_available", "TINYINT", 1,   "NO", "1",     "CHECK(0/1)",      "是否在馆：1在馆/0借出（由应用层+事务维护）"),
        ],
    },
    {
        "name": "Borrow", "comment": "借阅记录（谁、借了哪本副本、什么时候借、什么时候还）",
        "fields": [
            ("borrow_id",  "VARCHAR", 32,  "NO",  "",      "PK",                   "借阅记录编号"),
            ("reader_id",  "VARCHAR", 32,  "NO",  "",      "FK→Reader.reader_id",  "读者编号"),
            ("copy_id",    "VARCHAR", 32,  "NO",  "",      "FK→Copy.copy_id",      "借出的副本编号"),
            ("borrow_date","DATE",    0,   "NO",  "",      "",                      "借出日期"),
            ("due_date",   "DATE",    0,   "NO",  "",      "",                      "应还日期（借出+30天）"),
            ("return_date","DATE",    0,   "YES", "NULL",  "",                      "实际归还日期，NULL=尚未归还"),
            ("status",     "VARCHAR", 10,  "NO",  "",      "CHECK(在借/已归还/已逾期)","状态标记（冗余，方便前端筛选）"),
            ("is_overdue", "TINYINT", 1,   "NO",  "0",     "CHECK(0/1)",            "是否逾期：1逾期/0未逾期（冗余，触发器每日维护）"),
            ("admin_id",   "VARCHAR", 32,  "YES", "NULL",  "FK→Admin.admin_id",    "处理归还的管理员编号，NULL=尚未归还"),
            ("handle_time","DATETIME",0,   "YES", "NULL",  "",                      "处理时间（管理员处理归还时刻）"),
        ],
    },
]

# ============== 手写 xlsx ==============

sheet_rows = []
sheet_rows.append(["数据表", "字段名", "MySQL 类型", "长度", "可空", "默认值", "约束(PK/FK/UK)", "中文说明"])

for t in TABLES:
    for i, f in enumerate(t["fields"]):
        fname, ftype, flen, nullable, default, cons, desc = f
        if i == 0:
            sheet_rows.append([f"{t['name']}  ({t['comment']})", fname, ftype,
                              flen if flen else "", nullable, default, cons, desc])
        else:
            sheet_rows.append(["", fname, ftype,
                              flen if flen else "", nullable, default, cons, desc])

# 生成 sheet xml 的 row/cell 片段
def cell_xml(v, col_idx, row_idx, bold=False):
    # 字符串值
    ref = f"{col(col_idx)}{row_idx}"
    s = 1 if bold else None
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return f'<c r="{ref}"' + (f' s="{s}"' if s else "") + f'><v>{v}</v></c>'
    else:
        # 字符串用内联字符串，避免共享字符串表
        text = str(v).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
        return f'<c r="{ref}" t="inlineStr"' + (f' s="{s}"' if s else "") + f'><is><t xml:space="preserve">{text}</t></is></c>'

sheet_xml = []
sheet_xml.append(f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
sheet_xml.append(f'<worksheet xmlns="{NS}"><sheetData>')
for r_idx, row in enumerate(sheet_rows, 1):
    sheet_xml.append(f'<row r="{r_idx}">')
    for c_idx, val in enumerate(row, 1):
        sheet_xml.append(cell_xml(val, c_idx, r_idx, bold=(r_idx==1)))
    sheet_xml.append(f'</row>')
sheet_xml.append(f'</sheetData>')
# 列宽
widths = [16, 20, 24, 8, 6, 16, 24, 40]
sheet_xml.append(f'<cols>')
for i, w in enumerate(widths, 1):
    sheet_xml.append(f'<col min="{i}" max="{i}" width="{w}" customWidth="1"/>')
sheet_xml.append(f'</cols>')
sheet_xml.append(f'</worksheet>')
sheet_xml = "\n".join(sheet_xml)

# workbook.xml
workbook_xml = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="{NS}" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="数据字典" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>'''

# workbook 关系
wb_rels_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>'''

# Content_Types
ct_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>'''

root_rels_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>'''

# styles.xml（加一个 bold 样式）
styles_xml = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="{NS}">
  <fonts count="2">
    <font><sz val="11"/><name val="Arial"/></font>
    <font><b/><sz val="11"/><name val="Arial"/></font>
  </fonts>
  <fills count="2">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
  </fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="2">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/>
  </cellXfs>
</styleSheet>'''

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", ct_xml)
    z.writestr("_rels/.rels", root_rels_xml)
    z.writestr("xl/workbook.xml", workbook_xml)
    z.writestr("xl/_rels/workbook.xml.rels", wb_rels_xml)
    z.writestr("xl/worksheets/sheet1.xml", sheet_xml)
    z.writestr("xl/styles.xml", styles_xml)

print("生成成功！")
print("路径:", OUT)
print("大小:", os.path.getsize(OUT), "bytes")
print("行数:", len(sheet_rows), "(含表头)")
