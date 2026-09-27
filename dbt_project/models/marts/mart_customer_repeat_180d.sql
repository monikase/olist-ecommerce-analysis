WITH customer_orders AS (

    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        total_order_value,
        item_count,
        freight_value,
        average_review_score,
        order_delivered_customer_date,
        order_estimated_delivery_date,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp, order_id
        ) AS purchase_number

    FROM {{ ref('int_customer_orders') }}

    WHERE total_order_value IS NOT NULL
),

first_purchase AS (

    SELECT
        customer_unique_id,
        order_purchase_timestamp AS first_purchase_timestamp,
        total_order_value AS first_order_value,
        item_count AS first_order_items,
        freight_value AS first_order_freight,
        average_review_score AS first_review_score,

        CASE
            WHEN order_delivered_customer_date IS NOT NULL
             AND order_estimated_delivery_date IS NOT NULL
            THEN DATE_DIFF(
                'day',
                CAST(order_purchase_timestamp AS DATE),
                CAST(order_delivered_customer_date AS DATE)
            )
        END AS delivery_days,

        CASE
            WHEN order_delivered_customer_date IS NULL
                OR order_estimated_delivery_date IS NULL
            THEN NULL
            WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 1
            ELSE 0
END AS late_delivery

    FROM customer_orders

    WHERE purchase_number = 1
),

second_purchase AS (

    SELECT
        customer_unique_id,
        order_purchase_timestamp AS second_purchase_timestamp

    FROM customer_orders

    WHERE purchase_number = 2
),

dataset_end AS (

    SELECT
        MAX(order_purchase_timestamp) AS dataset_end_date

    FROM {{ ref('int_customer_orders') }}

    WHERE total_order_value IS NOT NULL
),

customer_repeat AS (

    SELECT
        f.customer_unique_id,
        f.first_purchase_timestamp,
        f.first_order_value,
        f.first_order_items,
        f.first_order_freight,
        f.first_review_score,
        f.delivery_days,
        f.late_delivery,

        s.second_purchase_timestamp,

        DATE_DIFF(
            'day',
            CAST(f.first_purchase_timestamp AS DATE),
            CAST(d.dataset_end_date AS DATE)
        ) AS observation_days,

        CASE
            WHEN s.second_purchase_timestamp IS NOT NULL
             AND DATE_DIFF(
                    'day',
                    CAST(f.first_purchase_timestamp AS DATE),
                    CAST(s.second_purchase_timestamp AS DATE)
                 ) <= 180
            THEN 1
            ELSE 0
        END AS returned_180d

    FROM first_purchase f

    LEFT JOIN second_purchase s
        ON f.customer_unique_id = s.customer_unique_id

    CROSS JOIN dataset_end d
)

SELECT *
FROM customer_repeat

WHERE observation_days >= 180