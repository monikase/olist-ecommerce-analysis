-- ============================================================
-- 01_raw_data_quality.sql
-- Raw data quality and relationship checks
-- ============================================================


-- ============================================================
-- 1. PRIMARY KEY UNIQUENESS
-- ============================================================

-- Customers
SELECT
    'customers.customer_id' AS check_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_values,
    COUNT(*) = COUNT(DISTINCT customer_id) AS passes
FROM raw_customers;


-- Orders
SELECT
    'orders.order_id' AS check_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_values,
    COUNT(*) = COUNT(DISTINCT order_id) AS passes
FROM raw_orders;


-- Products
SELECT
    'products.product_id' AS check_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS distinct_values,
    COUNT(*) = COUNT(DISTINCT product_id) AS passes
FROM raw_products;


-- Sellers
SELECT
    'sellers.seller_id' AS check_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS distinct_values,
    COUNT(*) = COUNT(DISTINCT seller_id) AS passes
FROM raw_sellers;


-- ============================================================
-- 2. NULL CHECKS ON IMPORTANT KEYS
-- ============================================================

SELECT
    'orders.order_id NULLs' AS check_name,
    COUNT(*) AS null_count
FROM raw_orders
WHERE order_id IS NULL;


SELECT
    'orders.customer_id NULLs' AS check_name,
    COUNT(*) AS null_count
FROM raw_orders
WHERE customer_id IS NULL;


SELECT
    'order_items.order_id NULLs' AS check_name,
    COUNT(*) AS null_count
FROM raw_order_items
WHERE order_id IS NULL;


SELECT
    'order_items.product_id NULLs' AS check_name,
    COUNT(*) AS null_count
FROM raw_order_items
WHERE product_id IS NULL;


SELECT
    'order_items.seller_id NULLs' AS check_name,
    COUNT(*) AS null_count
FROM raw_order_items
WHERE seller_id IS NULL;


-- ============================================================
-- 3. FOREIGN KEY INTEGRITY
-- ============================================================

-- Every order should have a customer
SELECT
    'orders → customers' AS relationship,
    COUNT(*) AS orphan_records
FROM raw_orders o
LEFT JOIN raw_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Every order item should belong to an existing order
SELECT
    'order_items → orders' AS relationship,
    COUNT(*) AS orphan_records
FROM raw_order_items oi
LEFT JOIN raw_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Every order item should reference an existing product
SELECT
    'order_items → products' AS relationship,
    COUNT(*) AS orphan_records
FROM raw_order_items oi
LEFT JOIN raw_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Every order item should reference an existing seller
SELECT
    'order_items → sellers' AS relationship,
    COUNT(*) AS orphan_records
FROM raw_order_items oi
LEFT JOIN raw_sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- ============================================================
-- 4. CUSTOMER IDENTITY
-- ============================================================

SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM raw_customers;


-- How many customer IDs belong to customers
-- who appear more than once?
SELECT
    customer_unique_id,
    COUNT(*) AS customer_id_count
FROM raw_customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY customer_id_count DESC;


-- ============================================================
-- 5. ORDER CARDINALITY
-- ============================================================

-- How many items does an order contain?
SELECT
    order_id,
    COUNT(*) AS item_count
FROM raw_order_items
GROUP BY order_id
ORDER BY item_count DESC
LIMIT 10;


-- How many payment records can an order have?
SELECT
    order_id,
    COUNT(*) AS payment_count
FROM raw_order_payments
GROUP BY order_id
ORDER BY payment_count DESC
LIMIT 10;


-- How many reviews can an order have?
SELECT
    order_id,
    COUNT(*) AS review_count
FROM raw_order_reviews
GROUP BY order_id
ORDER BY review_count DESC
LIMIT 10;


-- ============================================================
-- 6. ORDER STATUS DISTRIBUTION
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS orders
FROM raw_orders
GROUP BY order_status
ORDER BY orders DESC;


-- ============================================================
-- 7. DATE RANGE
-- ============================================================

SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM raw_orders;


-- ============================================================
-- 8. DELIVERY DATA COMPLETENESS
-- ============================================================

SELECT
    COUNT(*) AS total_orders,

    COUNT(order_delivered_carrier_date)
        AS orders_with_carrier_date,

    COUNT(order_delivered_customer_date)
        AS orders_with_delivery_date,

    COUNT(order_estimated_delivery_date)
        AS orders_with_estimated_date

FROM raw_orders;