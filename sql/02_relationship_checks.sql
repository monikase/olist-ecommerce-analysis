-- ============================================================
-- 1. How many orders have multiple payment records?
-- ============================================================

SELECT
    COUNT(*) AS orders_with_multiple_payments
FROM (
    SELECT
        order_id
    FROM main.stg_order_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
);

-- ============================================================
-- 2. How many orders have multiple reviews?
-- ============================================================

SELECT
    COUNT(*) AS orders_with_multiple_reviews
FROM (
    SELECT
        order_id
    FROM main.stg_order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
);

-- ============================================================
-- 3. Distribution of payment records per order
-- ============================================================

SELECT
    payment_count,
    COUNT(*) AS number_of_orders
FROM (
    SELECT
        order_id,
        COUNT(*) AS payment_count
    FROM main.stg_order_payments
    GROUP BY order_id
)
GROUP BY payment_count
ORDER BY payment_count;


-- ============================================================
-- 4. Distribution of item count per order
-- ============================================================

SELECT
    item_count,
    COUNT(*) AS number_of_orders
FROM (
    SELECT
        order_id,
        COUNT(*) AS item_count
    FROM main.stg_order_items
    GROUP BY order_id
)
GROUP BY item_count
ORDER BY item_count;


-- ============================================================
-- 5. Review score distribution
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS review_count
FROM main.stg_order_reviews
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 6. Orders without reviews
-- ============================================================

SELECT
    COUNT(*) AS orders_without_reviews
FROM main.stg_orders o
LEFT JOIN main.stg_order_reviews r
    ON o.order_id = r.order_id
WHERE r.order_id IS NULL;


-- ============================================================
-- 7. Orders without payments
-- ============================================================

SELECT
    COUNT(*) AS orders_without_payments
FROM main.stg_orders o
LEFT JOIN main.stg_order_payments p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;


-- ============================================================
-- 8. Row count of enriched order items
-- ============================================================

SELECT
    COUNT(*) AS enriched_rows
FROM main.int_order_items_enriched;


-- ============================================================
-- 9. Check for duplicate order-item keys
-- ============================================================

SELECT
    COUNT(*) AS duplicate_order_item_keys
FROM (
    SELECT
        order_id,
        order_item_id
    FROM main.int_order_items_enriched
    GROUP BY
        order_id,
        order_item_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 10. Compare staging and enriched row counts
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM main.stg_order_items) AS staging_item_rows,
    (SELECT COUNT(*) FROM main.int_order_items_enriched) AS enriched_item_rows;


-- ============================================================
-- 11. Check for missing customer identity
-- ============================================================

SELECT
    COUNT(*) AS missing_customer_unique_id
FROM main.int_order_items_enriched
WHERE customer_unique_id IS NULL;


-- ============================================================
-- 12. Check for missing English category
-- ============================================================

SELECT
    COUNT(*) AS missing_english_category
FROM main.int_order_items_enriched
WHERE product_category_name IS NOT NULL
  AND product_category_name_english IS NULL;

-- ============================================================
-- 13. Orders without item-level value
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count
FROM main.int_customer_orders
WHERE total_order_value IS NULL
GROUP BY order_status
ORDER BY order_count DESC;

-- ============================================================
-- 14. Compare order value with payment value
-- ============================================================

SELECT
    COUNT(*) AS orders_with_both_values,

    SUM(
        CASE
            WHEN ABS(total_order_value - total_payment_value) < 0.01
            THEN 1
            ELSE 0
        END
    ) AS matching_values,

    SUM(
        CASE
            WHEN ABS(total_order_value - total_payment_value) >= 0.01
            THEN 1
            ELSE 0
        END
    ) AS different_values

FROM main.int_customer_orders
WHERE total_order_value IS NOT NULL
  AND total_payment_value IS NOT NULL;


-- ============================================================
-- 15. Examples of differences between order and payment value
-- ============================================================

SELECT
    order_id,
    total_order_value,
    total_payment_value,
    total_payment_value - total_order_value AS difference
FROM main.int_customer_orders
WHERE total_order_value IS NOT NULL
  AND total_payment_value IS NOT NULL
  AND ABS(total_order_value - total_payment_value) >= 0.01
ORDER BY ABS(total_order_value - total_payment_value) DESC
LIMIT 20;

-- ============================================================
-- 16. Investigate order/payment value differences
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS orders_with_difference,
    ROUND(AVG(total_payment_value - total_order_value), 2) AS avg_difference,
    ROUND(MIN(total_payment_value - total_order_value), 2) AS min_difference,
    ROUND(MAX(total_payment_value - total_order_value), 2) AS max_difference
FROM main.int_customer_orders
WHERE total_order_value IS NOT NULL
  AND total_payment_value IS NOT NULL
  AND ABS(total_order_value - total_payment_value) >= 0.01
GROUP BY order_status
ORDER BY orders_with_difference DESC;

-- ============================================================
-- 17. Distribution of purchase orders per customer
-- ============================================================

SELECT
    order_count,
    COUNT(*) AS number_of_customers
FROM (
    SELECT
        customer_unique_id,
        COUNT(*) AS order_count
    FROM main.int_customer_orders
    WHERE total_order_value IS NOT NULL
    GROUP BY customer_unique_id
)
GROUP BY order_count
ORDER BY order_count;

-- ============================================================
-- 18. Customer and purchase counts
-- ============================================================

SELECT
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    COUNT(*) AS total_purchase_orders
FROM main.int_customer_orders
WHERE total_order_value IS NOT NULL;

