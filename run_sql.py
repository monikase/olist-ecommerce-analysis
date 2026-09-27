import duckdb
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
DB_PATH = PROJECT_ROOT / "olist.duckdb"

import sys

sql_file_name = (
    sys.argv[1]
    if len(sys.argv) > 1
    else "02_relationship_checks.sql"
)

sql_file = Path(__file__).resolve().parent / "sql" / sql_file_name

con = duckdb.connect(DB_PATH)

sql = sql_file.read_text()

# Split queries using semicolons
queries = [q.strip() for q in sql.split(";") if q.strip()]

for i, query in enumerate(queries, start=1):
    print("\n" + "=" * 70)
    print(f"QUERY {i}")
    print("=" * 70)
    print(query)

    result = con.execute(query).fetchdf()

    print("\nRESULT:")
    print(result.to_string(index=False))

con.close()