# Data Quality & Validation

This document records the main data-quality checks and modeling decisions
made during the transformation process.

## Raw Data

All 9 source CSV files were loaded into DuckDB.

| Raw table | Rows |
|---|---:|
| `raw_customers` | 99,441 |
| `raw_orders` | 99,441 |
| `raw_order_items` | 112,650 |
| `raw_order_payments` | 103,886 |
| `raw_order_reviews` | 99,224 |
| `raw_products` | 32,951 |
| `raw_sellers` | 3,095 |
| `raw_category_translation` | 71 |
| `raw_geolocation` | 1,000,163 |

---

## Relationship Checks

The source contains several one-to-many relationships that need to be
handled carefully.

### Payments

- 2,961 orders have multiple payment records.
- Payment records per order can range from 1 to 29.

### Reviews

- 547 orders have multiple review records.
- 768 orders have no review record.

### Order items

Orders can contain multiple items, so `order_item_id` is not globally
unique. Its natural key is:

```text
(order_id, order_item_id)
```

## Missing Payments

Only 1 order has no payment record.

---

## Join-Grain Validation

`int_order_items_enriched` was checked for accidental row multiplication.

| Check | Result |
|---|---:|
| Original item rows | 112,650 |
| Enriched rows | 112,650 |
| Duplicate order-item keys | 0 |
| Missing customer identity | 0 |

The matching row counts confirm that the enrichment joins preserve the one-row-per-order-item grain.

---

## Orders Without Item Data

775 orders in `int_customer_orders` have no item-level value.

| Order Status | Orders |
|---|---:|
| unavailable | 603 |
| canceled | 164 |
| created | 5 |
| invoiced | 2 |
| shipped | 1 |

These orders are retained in the order-level model but are not interpreted as zero-value purchases.

For customer purchasing analysis, orders with item-level purchase information are used.

---

## Order Value vs Payment Value

Item-based order value was compared with aggregated payment value.

Among 98,665 orders where both values were available:

- 98,285 matched within €0.01.
- 380 had a difference.

The differences occurred in both directions.

The model therefore retains both metrics:

- `total_order_value`: item price + freight value
- `total_payment_value`: aggregated payment records

Neither metric is used as a replacement for the other.