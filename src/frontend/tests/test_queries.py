import sys
from pathlib import Path

FRONTEND_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(FRONTEND_DIR))

import queries  # noqa: E402

SQL_CONSTANTS = {
    name: value
    for name, value in vars(queries).items()
    if name.endswith("_SQL") and isinstance(value, str)
}

REPORT_SQL_NAMES = ["TOP_BOOK_SQL", "CATEGORY_STOCK_SQL", "OVERDUE_SQL", "MONTHLY_SQL"]


def test_sql_constants_are_non_empty() -> None:
    assert SQL_CONSTANTS
    for name, sql in SQL_CONSTANTS.items():
        assert sql.strip(), name


def test_sql_constants_have_balanced_parentheses() -> None:
    for name, sql in SQL_CONSTANTS.items():
        assert sql.count("(") == sql.count(")"), name


def test_only_dynamic_in_list_uses_placeholder_template() -> None:
    for name, sql in SQL_CONSTANTS.items():
        if name == "AVAILABLE_COPY_SQL":
            assert "{placeholders}" in sql
        else:
            assert "{placeholders}" not in sql, name


def test_report_queries_have_order_by() -> None:
    for name in REPORT_SQL_NAMES:
        assert name in SQL_CONSTANTS
        assert "ORDER BY" in SQL_CONSTANTS[name], name
