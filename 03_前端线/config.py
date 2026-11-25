"""
前端运行配置：数据库连接、Flask 密钥与分页参数。

所有可能随机器变化的值都从环境变量读取，代码里不出现真实密码。
同目录的 ``.env``（已被 .gitignore 忽略）会被本模块自动加载，系统环境变量优先；
也可以直接在终端里设置：

    $env:DB_PASSWORD = "你的密码"
    $env:DB_NAME     = "library_system"
"""

import os
from pathlib import Path


def _load_dotenv(path: Path) -> None:
    """
    把同目录下的 .env 文件读进环境变量，省掉 python-dotenv 依赖。

    *Args:
        path: .env 路径，通常与本文件同目录；文件不存在时直接返回。
    *Return:
        无。已经存在的环境变量不会被覆盖，命令行环境优先于 .env。
    """
    if not path.is_file():
        return
    # utf-8-sig 兼容记事本加的 BOM；errors="replace" 保证被别人用 GBK 存过也能启动。
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        if key and key not in os.environ:
            os.environ[key] = value.strip().strip('"').strip("'")


_load_dotenv(Path(__file__).with_name(".env"))

# 数据库连接参数。密码只从环境变量来，缺省为空串，启动时会给出提示。
DB_CONFIG: dict[str, object] = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),
    "database": os.getenv("DB_NAME", "library_system"),
    "charset": "utf8mb4",
    # 存储过程内部自己开事务与回滚，这里打开自动提交，避免忘记 commit。
    "autocommit": True,
}

# Flask 会话签名密钥。本地演示可用默认值，正式提交前换成自己的随机串。
SECRET_KEY: str = os.getenv("FLASK_SECRET_KEY", "library-demo-dev-only")

# 图书列表每页条数。
PAGE_SIZE: int = int(os.getenv("PAGE_SIZE", "10"))

# 单读者在借上限，与 05_存储过程.sql 中 borrow_book 的 -3 判定保持一致。
BORROW_LIMIT: int = 5

# 借期天数，仅用于页面文案，真实应还日期由存储过程计算。
BORROW_DAYS: int = 30

# 监听地址与端口。
HOST: str = os.getenv("FLASK_HOST", "127.0.0.1")
PORT: int = int(os.getenv("FLASK_PORT", "5000"))
