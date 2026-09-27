WITH customer_orders AS (

    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        total_order_value,
        item_count,
        average_review_score
    FROM {{ ref('int_customer_orders') }}
    WHERE total_order_value IS NOT NULL

),

customer_summary AS (

    SELECT
        customer_unique_id,
        COUNT(*) AS order_count,
        MIN(order_purchase_timestamp) AS first_purchase_timestamp,
        MAX(order_purchase_timestamp) AS last_purchase_timestamp,
        SUM(total_order_value) AS total_customer_value,
        AVG(total_order_value) AS average_order_value,
        SUM(item_count) AS total_items_purchased,
        AVG(average_review_score) AS average_review_score
    FROM customer_orders
    GROUP BY customer_unique_id

)

SELECT
    customer_unique_id,
    order_count,

    CASE
        WHEN order_count = 1 THEN 'one-time'
        ELSE 'returning'
    END AS customer_type,

    first_purchase_timestamp,
    last_purchase_timestamp,
    total_customer_value,
    average_order_value,
    total_items_purchased,
    average_review_score
FROM customer_summary