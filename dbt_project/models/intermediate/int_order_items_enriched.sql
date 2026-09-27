SELECT
    oi.order_id,
    o.customer_id,
    c.customer_unique_id,

    o.order_status,
    o.order_purchase_timestamp,

    oi.order_item_id,
    oi.product_id,
    oi.seller_id,

    p.product_category_name,
    ct.product_category_name_english,

    oi.price,
    oi.freight_value

FROM {{ ref('stg_order_items') }} oi

LEFT JOIN {{ ref('stg_orders') }} o
    ON oi.order_id = o.order_id

LEFT JOIN {{ ref('stg_customers') }} c
    ON o.customer_id = c.customer_id

LEFT JOIN {{ ref('stg_products') }} p
    ON oi.product_id = p.product_id

LEFT JOIN {{ ref('stg_category_translation') }} ct
    ON p.product_category_name = ct.product_category_name

LEFT JOIN {{ ref('stg_sellers') }} s
    ON oi.seller_id = s.seller_id