import duckdb
from pathlib import Path


# Project paths
PROJECT_ROOT = Path(__file__).resolve().parent
DATA_DIR = PROJECT_ROOT / "data" / "raw"
DB_PATH = PROJECT_ROOT / "olist.duckdb"


# Connect to DuckDB
con = duckdb.connect(DB_PATH)


# CSV files → raw table names
tables = {
    "raw_customers": "olist_customers_dataset.csv",
    "raw_geolocation": "olist_geolocation_dataset.csv",
    "raw_order_items": "olist_order_items_dataset.csv",
    "raw_order_payments": "olist_order_payments_dataset.csv",
    "raw_order_reviews": "olist_order_reviews_dataset.csv",
    "raw_orders": "olist_orders_dataset.csv",
    "raw_products": "olist_products_dataset.csv",
    "raw_sellers": "olist_sellers_dataset.csv",
    "raw_category_translation": "product_category_name_translation.csv",
}


for table_name, file_name in tables.items():

    file_path = DATA_DIR / file_name

    print(f"Loading {file_name}...")

    con.execute(f"""
        CREATE OR REPLACE TABLE {table_name} AS
        SELECT *
        FROM read_csv_auto('{file_path.as_posix()}')
    """)

    row_count = con.execute(
        f"SELECT COUNT(*) FROM {table_name}"
    ).fetchone()[0]

    print(f"  → {table_name}: {row_count:,} rows")


print("\nAll tables loaded successfully.")

con.close()