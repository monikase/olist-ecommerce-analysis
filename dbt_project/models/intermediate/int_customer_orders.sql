WITH order_items AS (

    SELECT
        order_id,

        COUNT(*) AS item_count,

        SUM(price) AS product_value,

        SUM(freight_value) AS freight_value,

        SUM(price + freight_value) AS total_order_value

    FROM {{ ref('int_order_items_enriched') }}

    GROUP BY order_id

)

SELECT
    o.order_id,
    c.customer_unique_id,

    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    oi.item_count,
    oi.product_value,
    oi.freight_value,
    oi.total_order_value,

    p.total_payment_value,
    p.payment_count,
    p.max_payment_installments,

    r.average_review_score,
    r.review_count

FROM {{ ref('stg_orders') }} o

LEFT JOIN {{ ref('stg_customers') }} c
    ON o.customer_id = c.customer_id

LEFT JOIN order_items oi
    ON o.order_id = oi.order_id

LEFT JOIN {{ ref('int_order_payments') }} p
    ON o.order_id = p.order_id

LEFT JOIN {{ ref('int_order_reviews') }} r
    ON o.order_id = r.order_id