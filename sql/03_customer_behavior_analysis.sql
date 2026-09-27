-- ============================================================
-- 1. Customer type distribution
-- ============================================================

SELECT
    customer_type,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_share_pct

FROM main.mart_customer_behavior
GROUP BY customer_type
ORDER BY customer_count DESC;


-- ============================================================
-- 2. Customer behavior by segment
-- ============================================================

SELECT
    customer_type,
    COUNT(*) AS customer_count,
    ROUND(AVG(order_count), 2) AS avg_order_count,
    ROUND(AVG(total_customer_value), 2) AS avg_customer_value,
    ROUND(AVG(average_order_value), 2) AS avg_order_value,
    ROUND(AVG(total_items_purchased), 2) AS avg_items_purchased,
    ROUND(AVG(average_review_score), 2) AS avg_review_score

FROM main.mart_customer_behavior
GROUP BY customer_type
ORDER BY customer_type;


-- ============================================================
-- 3. Revenue contribution by customer type
-- ============================================================

SELECT
    customer_type,
    ROUND(SUM(total_customer_value), 2) AS total_revenue,
    ROUND(
        100.0 * SUM(total_customer_value)
        / SUM(SUM(total_customer_value)) OVER (),
        2
    ) AS revenue_share_pct

FROM main.mart_customer_behavior
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- ============================================================
-- 4. Time to Second Purchase
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS purchase_number
    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_and_second_purchases AS (
    SELECT
        customer_unique_id,

        MIN(
            CASE
                WHEN purchase_number = 1
                THEN order_purchase_timestamp
            END
        ) AS first_purchase_timestamp,

        MIN(
            CASE
                WHEN purchase_number = 2
                THEN order_purchase_timestamp
            END
        ) AS second_purchase_timestamp

    FROM customer_orders
    GROUP BY customer_unique_id
)

SELECT
    COUNT(*) AS returning_customers,
    MIN(
        DATE_DIFF(
            'day',
            first_purchase_timestamp,
            second_purchase_timestamp
        )
    ) AS min_days_to_second_purchase,
    ROUND(
        AVG(
            DATE_DIFF(
                'day',
                first_purchase_timestamp,
                second_purchase_timestamp
            )
        ),
        2
    ) AS avg_days_to_second_purchase,
    MEDIAN(
        DATE_DIFF(
            'day',
            first_purchase_timestamp,
            second_purchase_timestamp
        )
    ) AS median_days_to_second_purchase,
    MAX(
        DATE_DIFF(
            'day',
            first_purchase_timestamp,
            second_purchase_timestamp
        )
    ) AS max_days_to_second_purchase
FROM first_and_second_purchases
WHERE second_purchase_timestamp IS NOT NULL;

-- ============================================================
-- 4b. Time to Second Purchase Distribution
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS purchase_number
    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_and_second_purchases AS (
    SELECT
        customer_unique_id,

        MIN(
            CASE
                WHEN purchase_number = 1
                THEN order_purchase_timestamp
            END
        ) AS first_purchase_timestamp,

        MIN(
            CASE
                WHEN purchase_number = 2
                THEN order_purchase_timestamp
            END
        ) AS second_purchase_timestamp

    FROM customer_orders
    GROUP BY customer_unique_id
),

return_intervals AS (
    SELECT
        customer_unique_id,
        DATE_DIFF(
            'day',
            first_purchase_timestamp,
            second_purchase_timestamp
        ) AS days_to_second_purchase
    FROM first_and_second_purchases
    WHERE second_purchase_timestamp IS NOT NULL
)

SELECT
    CASE
        WHEN days_to_second_purchase <= 30 THEN '0-30 days'
        WHEN days_to_second_purchase <= 60 THEN '31-60 days'
        WHEN days_to_second_purchase <= 90 THEN '61-90 days'
        WHEN days_to_second_purchase <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END AS return_period,

    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share

FROM return_intervals

GROUP BY
    CASE
        WHEN days_to_second_purchase <= 30 THEN '0-30 days'
        WHEN days_to_second_purchase <= 60 THEN '31-60 days'
        WHEN days_to_second_purchase <= 90 THEN '61-90 days'
        WHEN days_to_second_purchase <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END

ORDER BY
    CASE return_period
        WHEN '0-30 days' THEN 1
        WHEN '31-60 days' THEN 2
        WHEN '61-90 days' THEN 3
        WHEN '91-180 days' THEN 4
        WHEN '181+ days' THEN 5
    END;

-- ============================================================
-- 5. First-Order Behavior: One-Time vs Returning Customers
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        total_order_value,
        item_count,
        freight_value,
        average_review_score,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS purchase_number

    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        total_order_value,
        item_count,
        freight_value,
        average_review_score
    FROM customer_orders
    WHERE purchase_number = 1
),

customer_types AS (
    SELECT
        customer_unique_id,
        CASE
            WHEN COUNT(*) = 1 THEN 'one-time'
            ELSE 'returning'
        END AS customer_type
    FROM customer_orders
    GROUP BY customer_unique_id
)

SELECT
    ct.customer_type,

    COUNT(*) AS customers,

    ROUND(
        AVG(fo.total_order_value),
        2
    ) AS avg_first_order_value,

    ROUND(
        AVG(fo.item_count),
        2
    ) AS avg_first_order_items,

    ROUND(
        AVG(fo.freight_value),
        2
    ) AS avg_first_order_freight,

    ROUND(
        AVG(fo.average_review_score),
        2
    ) AS avg_first_order_review

FROM first_orders fo

JOIN customer_types ct
    ON fo.customer_unique_id = ct.customer_unique_id

GROUP BY ct.customer_type

ORDER BY
    CASE ct.customer_type
        WHEN 'one-time' THEN 1
        WHEN 'returning' THEN 2
    END;

-- ============================================================
-- 6. First-Order Delivery Performance
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        total_order_value,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS purchase_number

    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        order_delivered_customer_date,
        order_estimated_delivery_date
    FROM customer_orders
    WHERE purchase_number = 1
),

customer_types AS (
    SELECT
        customer_unique_id,

        CASE
            WHEN COUNT(*) = 1 THEN 'one-time'
            ELSE 'returning'
        END AS customer_type

    FROM customer_orders
    GROUP BY customer_unique_id
),

delivery_metrics AS (
    SELECT
        fo.customer_unique_id,
        ct.customer_type,

        DATE_DIFF(
            'day',
            fo.order_purchase_timestamp,
            fo.order_delivered_customer_date
        ) AS delivery_days,

        CASE
            WHEN fo.order_delivered_customer_date
                 > fo.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END AS delivered_late

    FROM first_orders fo
    JOIN customer_types ct
        ON fo.customer_unique_id = ct.customer_unique_id
    WHERE fo.order_delivered_customer_date IS NOT NULL
      AND fo.order_estimated_delivery_date IS NOT NULL
)

SELECT
    customer_type,
    COUNT(*) AS customers,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    MEDIAN(delivery_days) AS median_delivery_days,
    SUM(delivered_late) AS late_deliveries,

    ROUND(
        100.0 * AVG(delivered_late),
        2
    ) AS late_delivery_rate

FROM delivery_metrics
GROUP BY customer_type
ORDER BY
    CASE customer_type
        WHEN 'one-time' THEN 1
        WHEN 'returning' THEN 2
    END;

-- ============================================================
-- 7. First-Order Category and Repeat Purchasing
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        total_order_value,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS purchase_number,

        COUNT(*) OVER (
            PARTITION BY customer_unique_id
        ) AS total_orders

    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        CASE
            WHEN total_orders = 1 THEN 'one-time'
            ELSE 'returning'
        END AS customer_type

    FROM customer_orders
    WHERE purchase_number = 1
),

first_order_categories AS (
    SELECT DISTINCT
        fo.customer_unique_id,
        fo.order_id,
        fo.customer_type,
        COALESCE(
            oi.product_category_name_english,
            oi.product_category_name,
            'unknown'
        ) AS product_category

    FROM first_orders fo
    JOIN int_order_items_enriched oi
        ON fo.order_id = oi.order_id
)

SELECT
    product_category,
    COUNT(DISTINCT customer_unique_id) AS first_order_customers,

    COUNT(
        DISTINCT CASE
            WHEN customer_type = 'returning'
            THEN customer_unique_id
        END
    ) AS returning_customers,

    ROUND(
        100.0 *
        COUNT(
            DISTINCT CASE
                WHEN customer_type = 'returning'
                THEN customer_unique_id
            END
        )
        / COUNT(DISTINCT customer_unique_id),
        2
    ) AS repeat_purchase_rate

FROM first_order_categories
GROUP BY product_category
HAVING COUNT(DISTINCT customer_unique_id) >= 100
ORDER BY repeat_purchase_rate DESC;

-- ============================================================
-- 7b. Category Repeat Rates - Larger Customer Groups
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        total_order_value,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS purchase_number,

        COUNT(*) OVER (
            PARTITION BY customer_unique_id
        ) AS total_orders

    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_orders AS (
    SELECT
        customer_unique_id,
        order_id,

        CASE
            WHEN total_orders = 1 THEN 'one-time'
            ELSE 'returning'
        END AS customer_type

    FROM customer_orders
    WHERE purchase_number = 1
),

first_order_categories AS (
    SELECT DISTINCT
        fo.customer_unique_id,
        fo.customer_type,

        COALESCE(
            oi.product_category_name_english,
            oi.product_category_name,
            'unknown'
        ) AS product_category

    FROM first_orders fo
    JOIN int_order_items_enriched oi
        ON fo.order_id = oi.order_id
)

SELECT
    product_category,
    COUNT(DISTINCT customer_unique_id) AS first_order_customers,

    COUNT(
        DISTINCT CASE
            WHEN customer_type = 'returning'
            THEN customer_unique_id
        END
    ) AS returning_customers,

    ROUND(
        100.0 *
        COUNT(
            DISTINCT CASE
                WHEN customer_type = 'returning'
                THEN customer_unique_id
            END
        )
        / COUNT(DISTINCT customer_unique_id),
        2
    ) AS repeat_purchase_rate

FROM first_order_categories
GROUP BY product_category
HAVING COUNT(DISTINCT customer_unique_id) >= 500
ORDER BY repeat_purchase_rate DESC;

-- ============================================================
-- 8. First-to-Second Purchase Category Transitions
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS purchase_number

    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_orders AS (
    SELECT
        customer_unique_id,
        order_id
    FROM customer_orders
    WHERE purchase_number = 1
),

second_orders AS (
    SELECT
        customer_unique_id,
        order_id
    FROM customer_orders
    WHERE purchase_number = 2
),

first_order_categories AS (
    SELECT DISTINCT
        fo.customer_unique_id,

        COALESCE(
            oi.product_category_name_english,
            oi.product_category_name,
            'unknown'
        ) AS first_category

    FROM first_orders fo

    JOIN int_order_items_enriched oi
        ON fo.order_id = oi.order_id
),

second_order_categories AS (
    SELECT DISTINCT
        so.customer_unique_id,

        COALESCE(
            oi.product_category_name_english,
            oi.product_category_name,
            'unknown'
        ) AS second_category

    FROM second_orders so

    JOIN int_order_items_enriched oi
        ON so.order_id = oi.order_id
),

category_transitions AS (
    SELECT
        f.customer_unique_id,
        f.first_category,
        s.second_category

    FROM first_order_categories f
    JOIN second_order_categories s
        ON f.customer_unique_id = s.customer_unique_id
)

SELECT
    first_category,
    second_category,
    COUNT(DISTINCT customer_unique_id) AS customers,

    ROUND(
        100.0 *
        COUNT(DISTINCT customer_unique_id)
        /
        SUM(COUNT(DISTINCT customer_unique_id))
        OVER (PARTITION BY first_category),
        2
    ) AS share_of_first_category

FROM category_transitions
GROUP BY
    first_category,
    second_category
ORDER BY
    customers DESC;

-- ============================================================
-- 8b. Significant First-to-Second Category Transitions
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS purchase_number

    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_orders AS (
    SELECT
        customer_unique_id,
        order_id
    FROM customer_orders
    WHERE purchase_number = 1
),

second_orders AS (
    SELECT
        customer_unique_id,
        order_id
    FROM customer_orders
    WHERE purchase_number = 2
),

first_order_categories AS (
    SELECT DISTINCT
        fo.customer_unique_id,
        COALESCE(
            oi.product_category_name_english,
            oi.product_category_name,
            'unknown'
        ) AS first_category

    FROM first_orders fo
    JOIN int_order_items_enriched oi
        ON fo.order_id = oi.order_id
),

second_order_categories AS (
    SELECT DISTINCT
        so.customer_unique_id,
        COALESCE(
            oi.product_category_name_english,
            oi.product_category_name,
            'unknown'
        ) AS second_category

    FROM second_orders so
    JOIN int_order_items_enriched oi
        ON so.order_id = oi.order_id
),

category_transitions AS (
    SELECT
        f.customer_unique_id,
        f.first_category,
        s.second_category

    FROM first_order_categories f
    JOIN second_order_categories s
        ON f.customer_unique_id = s.customer_unique_id
)

SELECT
    first_category,
    second_category,
    COUNT(DISTINCT customer_unique_id) AS customers,

    ROUND(
        100.0 *
        COUNT(DISTINCT customer_unique_id)
        /
        SUM(COUNT(DISTINCT customer_unique_id))
        OVER (PARTITION BY first_category),
        2
    ) AS share_of_first_category

FROM category_transitions
GROUP BY
    first_category,
    second_category
HAVING COUNT(DISTINCT customer_unique_id) >= 20
ORDER BY customers DESC;

-- ============================================================
-- 9. First Purchase Features for Repeat-Purchase Analysis
-- ============================================================

WITH customer_orders AS (

    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        total_order_value,
        item_count,
        freight_value,
        average_review_score,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp, order_id
        ) AS purchase_number,

        COUNT(*) OVER (
            PARTITION BY customer_unique_id
        ) AS total_purchases

    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_purchase AS (

    SELECT
        customer_unique_id,
        order_id,
        total_purchases,

        total_order_value AS first_order_value,
        item_count AS first_order_items,
        freight_value AS first_order_freight,
        average_review_score AS first_review_score,

        order_purchase_timestamp,
        order_delivered_customer_date,
        order_estimated_delivery_date,

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
            WHEN order_delivered_customer_date IS NOT NULL
             AND order_estimated_delivery_date IS NOT NULL
             AND order_delivered_customer_date > order_estimated_delivery_date
            THEN 1
            ELSE 0
        END AS late_delivery,

        CASE
            WHEN total_purchases >= 2
            THEN 1
            ELSE 0
        END AS returned

    FROM customer_orders
    WHERE purchase_number = 1
)

SELECT
    returned,
    COUNT(*) AS customers,
    ROUND(AVG(first_order_value), 2) AS avg_order_value,
    ROUND(AVG(first_order_items), 2) AS avg_items,
    ROUND(AVG(first_review_score), 2) AS avg_review,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(
        100.0 * AVG(late_delivery), 2
    ) AS late_delivery_pct
FROM first_purchase
GROUP BY returned
ORDER BY returned;

-- ============================================================
-- 10. Observation Window After First Purchase
-- ============================================================

WITH customer_orders AS (

    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp, order_id
        ) AS purchase_number

    FROM int_customer_orders

    WHERE total_order_value IS NOT NULL
),

first_purchase AS (

    SELECT
        customer_unique_id,
        order_purchase_timestamp AS first_purchase_timestamp
    FROM customer_orders
    WHERE purchase_number = 1
),

dataset_end AS (

    SELECT
        MAX(order_purchase_timestamp) AS dataset_end_date
    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
)

SELECT
    COUNT(*) AS customers,

    ROUND(
        AVG(
            DATE_DIFF(
                'day',
                CAST(first_purchase_timestamp AS DATE),
                CAST(dataset_end_date AS DATE)
            )
        ),
        1
    ) AS avg_observation_days,

    MEDIAN(
        DATE_DIFF(
            'day',
            CAST(first_purchase_timestamp AS DATE),
            CAST(dataset_end_date AS DATE)
        )
    ) AS median_observation_days,

    MIN(
        DATE_DIFF(
            'day',
            CAST(first_purchase_timestamp AS DATE),
            CAST(dataset_end_date AS DATE)
        )
    ) AS min_observation_days,

    MAX(
        DATE_DIFF(
            'day',
            CAST(first_purchase_timestamp AS DATE),
            CAST(dataset_end_date AS DATE)
        )
    ) AS max_observation_days

FROM first_purchase
CROSS JOIN dataset_end;

-- ============================================================
-- 11. 180-day repeat purchase cohort
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp, order_id
        ) AS purchase_number
    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

first_purchase AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp AS first_purchase_timestamp
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
    FROM int_customer_orders
    WHERE total_order_value IS NOT NULL
),

eligible_customers AS (
    SELECT
        f.customer_unique_id,
        f.first_purchase_timestamp,
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

    WHERE DATE_DIFF(
        'day',
        CAST(f.first_purchase_timestamp AS DATE),
        CAST(d.dataset_end_date AS DATE)
    ) >= 180
)

SELECT
    COUNT(*) AS eligible_customers,

    SUM(returned_180d) AS returned_within_180d,

    COUNT(*) - SUM(returned_180d) AS not_returned_within_180d,

    ROUND(
        100.0 * SUM(returned_180d) / COUNT(*),
        2
    ) AS return_rate_180d_pct

FROM eligible_customers;

-- ============================================================
-- 12. Validate 180-day repeat purchase model
-- ============================================================

SELECT
    COUNT(*) AS customers,
    SUM(returned_180d) AS returned_180d,
    COUNT(*) - SUM(returned_180d) AS not_returned_180d,
    ROUND(
        100.0 * AVG(returned_180d),
        2
    ) AS return_rate_180d_pct
FROM mart_customer_repeat_180d;