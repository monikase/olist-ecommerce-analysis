# Data Model

## Project Overview

This project analyzes the Brazilian E-Commerce Public Dataset by Olist.

The main analytical question is:

> What distinguishes one-time customers from customers who return?

The project uses DuckDB and dbt to transform the raw relational dataset into
customer-level analytical models.

---

## Data Architecture

The project follows a layered transformation approach:

```text
Raw CSV files
      ↓
DuckDB raw tables
      ↓
Staging models
      ↓
Intermediate models
      ↓
Mart models
      ↓
SQL analysis / Python analysis
```

## Source Data

The dataset contains 9 CSV files covering:

- customers
- orders
- order items
- order payments
- order reviews
- products
- sellers
- geolocation
- product category translations

The raw CSV files are loaded into DuckDB before being transformed with dbt.

---

## Staging Layer

Staging models preserve the structure and grain of the source tables while providing consistent column names and references.

Current staging models:

- `stg_customers`
- `stg_orders`
- `stg_order_items`
- `stg_order_payments`
- `stg_order_reviews`
- `stg_products`
- `stg_sellers`
- `stg_category_translation`

### Important Grain Definitions

| Model | Grain |
|---|---|
| `stg_customers` | One row per customer record |
| `stg_orders` | One row per order |
| `stg_order_items` | One row per item within an order |
| `stg_order_payments` | Potentially multiple rows per order |
| `stg_order_reviews` | Potentially multiple rows per order |
| `stg_products` | One row per product |
| `stg_sellers` | One row per seller |

---

## Customer Identity

`customer_unique_id` is used as the persistent customer identifier for customer behavior analysis.

`customer_id` identifies the customer record associated with an order, while `customer_unique_id` is used to connect purchases belonging to the same customer across orders.

---

## Intermediate Layer

### `int_order_items_enriched`

**Grain:** one row per order item.

Combines:

- orders
- customers
- products
- category translations
- sellers

The model was validated against the original order-item data:

- Original rows: 112,650
- Enriched rows: 112,650
- Duplicate `(order_id, order_item_id)` keys: 0
- Missing `customer_unique_id`: 0

This confirms that the enrichment joins preserve the intended grain.

### `int_order_payments`

**Grain:** one row per order.

Payment records are aggregated before being joined to other order-level models because multiple payment records can exist for a single order.

### `int_order_reviews`

**Grain:** one row per order.

Review records are aggregated before being joined to other order-level models because multiple reviews can exist for a single order.

### `int_customer_orders`

**Grain:** one row per order.

Combines order, customer, item, payment, and review information.

Item, payment, and review data are aggregated to order grain before being joined to prevent row multiplication.

Orders without item-level records are retained, but their item-based order value remains `NULL` rather than being interpreted as a zero-value purchase.

---

## Customer Behavior Mart

### `mart_customer_behavior`

**Grain:** one row per customer with at least one order containing item-level purchase information.

The mart contains:

- purchase count
- customer type
- first purchase timestamp
- last purchase timestamp
- total customer value
- average order value
- total items purchased
- average review score

### Customer Classification

| Customer Type | Definition |
|---|---|
| One-time | 1 purchase |
| Returning | 2+ purchases | 


