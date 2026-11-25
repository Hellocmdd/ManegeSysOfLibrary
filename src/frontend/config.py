"""
前端运行配置：数据库连接、Flask 密钥与分页参数。

配置来源优先级：系统环境变量 > src/frontend/.env（可选覆盖）> 仓库根目录 .env > 代码默认值。
唯一模板是仓库根目录 .env.example；本目录 .env 为可选覆盖，不提供单独模板。
代码里不出现真实密码。
"""

import os
from pathlib import Path


def _read_dotenv(path: Path) -> dict[str, str]:
    """
    读取 .env 为键值对，不修改环境变量。

    *Args:
        path: .env 路径；文件不存在时返回空字典。
    *Return:
        解析出的键值对。utf-8-sig 兼容记事本 BOM，errors="replace" 兼容 GBK 误存。
    """
    if not path.is_file():
        return {}
    values: dict[str, str] = {}
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        if key:
            values[key] = value.strip().strip('"').strip("'")
    return values


def _apply_dotenv() -> None:
    """
    按 根目录 .env < 本目录 .env < 系统环境变量 的顺序应用配置。

    *Return:
        无；只把缺省的环境变量补齐，已有的系统环境变量不覆盖。
    """
    root_dir = Path(__file__).resolve().parents[2]
    values = _read_dotenv(root_dir / ".env")
    values.update(_read_dotenv(Path(__file__).with_name(".env")))
    for key, value in values.items():
        if key not in os.environ:
            os.environ[key] = value


_apply_dotenv()

# 是否强制 TLS。组长的远程库要求 mysql --ssl-mode=REQUIRED，默认开启；
# 本机 MySQL 没开 TLS 时设 DB_SSL=0 关掉。
DB_SSL: bool = os.getenv("DB_SSL", "1").strip().lower() not in {"0", "false", "no", "off"}

# 会话时区。远程服务器多用 UTC，而借期与逾期判定取 CURDATE()，必须对齐东八区。
DB_TIME_ZONE: str = os.getenv("DB_TIME_ZONE", "+08:00")

# 数据库连接参数。密码只从环境变量来，缺省为空串，启动时会给出提示。
DB_CONFIG: dict[str, object] = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),
    "database": os.getenv("DB_NAME", "storageoflibrarysys"),
    "charset": "utf8mb4",
    # 存储过程内部自己开事务与回滚，这里打开自动提交，避免忘记 commit。
    "autocommit": True,
}

# PyMySQL 只有在收到非空的 ssl 参数时才强制 TLS，等价于 mysql 客户端的 --ssl-mode=REQUIRED；
# 不传则是 PREFERRED，服务器没要求 TLS 时会静默退化成明文。
if DB_SSL:
    DB_CONFIG["ssl"] = {"check_hostname": False}

# 连上后立即对齐时区，否则服务器的 CURDATE() 与本地差几小时，借期与逾期都会算错。
if DB_TIME_ZONE:
    DB_CONFIG["init_command"] = f"SET time_zone = '{DB_TIME_ZONE}'"

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
