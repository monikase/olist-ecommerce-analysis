import duckdb
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent
DB_PATH = PROJECT_ROOT / "olist.duckdb"

con = duckdb.connect(DB_PATH)


tables = [
    "raw_customers",
    "raw_orders",
    "raw_order_items",
    "raw_order_payments",
    "raw_order_reviews",
    "raw_products",
    "raw_sellers",
    "raw_category_translation",
    "raw_geolocation",
]


for table in tables:

    print("\n" + "=" * 60)
    print(f"TABLE: {table}")
    print("=" * 60)

    # Row count
    row_count = con.execute(
        f"SELECT COUNT(*) FROM {table}"
    ).fetchone()[0]

    print(f"Rows: {row_count:,}")

    # Columns and data types
    columns = con.execute(
        f"DESCRIBE {table}"
    ).fetchall()

    print("\nColumns:")

    for column in columns:
        print(f"  {column[0]:40} {column[1]}")


con.close()