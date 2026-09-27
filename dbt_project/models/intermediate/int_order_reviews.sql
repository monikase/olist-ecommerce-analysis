SELECT
    order_id,

    AVG(review_score) AS average_review_score,

    COUNT(*) AS review_count

FROM {{ ref('stg_order_reviews') }}

GROUP BY order_id