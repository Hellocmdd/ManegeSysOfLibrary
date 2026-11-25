import re
import sys
from pathlib import Path

FRONTEND_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(FRONTEND_DIR))

import config  # noqa: E402


def test_read_dotenv_parses_comments_and_quotes(tmp_path: Path) -> None:
    env_file = tmp_path / ".env"
    env_file.write_text(
        "# comment\n\nDB_HOST='db.example'\nDB_PORT=3307\nPAGE_SIZE=\"20\"\n",
        encoding="utf-8",
    )
    values = config._read_dotenv(env_file)
    assert values == {"DB_HOST": "db.example", "DB_PORT": "3307", "PAGE_SIZE": "20"}


def test_public_config_has_required_keys() -> None:
    assert {
        "host", "port", "user", "password", "database", "charset", "autocommit"
    } <= config.DB_CONFIG.keys()
    assert isinstance(config.DB_CONFIG["port"], int)
    assert isinstance(config.DB_CONFIG["autocommit"], bool)
    assert isinstance(config.PAGE_SIZE, int) and config.PAGE_SIZE > 0
    assert isinstance(config.SECRET_KEY, str) and config.SECRET_KEY


def test_no_hardcoded_db_password_in_python_sources() -> None:
    pattern = re.compile(r"password\s*[:=]\s*['\"][^'\"]+['\"]", re.IGNORECASE)
    for path in FRONTEND_DIR.glob("*.py"):
        text = path.read_text(encoding="utf-8")
        assert not pattern.search(text), f"hardcoded password in {path.name}"
