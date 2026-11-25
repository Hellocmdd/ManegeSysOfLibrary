import re
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[3]
FRONTEND_DIR = REPO_ROOT / "src" / "frontend"
sys.path.insert(0, str(FRONTEND_DIR))

import queries  # noqa: E402

EXPECTED_DB_KEYS = {"DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"}
EXPECTED_FLASK_KEYS = {"FLASK_SECRET_KEY", "FLASK_HOST", "FLASK_PORT", "PAGE_SIZE"}
EXPECTED_TABLES = {"Admin", "Category", "Reader", "Book", "Copy", "Borrow"}
EXPECTED_PROCEDURES = {"borrow_book", "return_book", "renew_book"}


def test_root_env_template_has_all_shared_keys() -> None:
    text = (REPO_ROOT / ".env.example").read_text(encoding="utf-8")
    keys = set(re.findall(r"(?m)^([A-Z_]+)=", text))
    assert EXPECTED_DB_KEYS <= keys
    assert EXPECTED_FLASK_KEYS <= keys


def test_both_stacks_read_the_same_db_keys() -> None:
    java_util = (
        REPO_ROOT / "src" / "backend" / "main" / "java" / "com" / "library" / "util" / "DBUtil.java"
    ).read_text(encoding="utf-8")
    python_config = (FRONTEND_DIR / "config.py").read_text(encoding="utf-8")
    for key in EXPECTED_DB_KEYS:
        assert f'get("{key}"' in java_util, key
        assert f'os.getenv("{key}"' in python_config, key


def test_backend_sql_defines_expected_tables_and_procedures() -> None:
    init_sql = (REPO_ROOT / "src" / "backend" / "sql" / "04_init.sql").read_text(encoding="utf-8")
    proc_sql = (REPO_ROOT / "src" / "backend" / "sql" / "05_存储过程.sql").read_text(encoding="utf-8")
    for table in EXPECTED_TABLES:
        assert re.search(rf"CREATE\s+TABLE\s+{table}\b", init_sql, re.IGNORECASE), table
    for procedure in EXPECTED_PROCEDURES:
        assert procedure in proc_sql.lower(), procedure


def test_frontend_queries_reference_only_known_tables() -> None:
    referenced = set()
    for name, sql in vars(queries).items():
        if name.endswith("_SQL") and isinstance(sql, str):
            referenced.update(re.findall(r"\b(?:FROM|JOIN)\s+([A-Za-z_]\w*)", sql))
    assert referenced, "no tables detected in frontend SQL constants"
    assert referenced <= EXPECTED_TABLES, referenced - EXPECTED_TABLES


@pytest.mark.integration
def test_live_db_smoke() -> None:
    """Optional live smoke test; enable with RUN_DB_INTEGRATION=1."""
    import pymysql
    from config import DB_CONFIG

    try:
        connection = pymysql.connect(**DB_CONFIG)
    except Exception as exc:
        pytest.skip(f"remote MySQL unavailable: {exc}")

    with connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            assert cursor.fetchone()[0]
