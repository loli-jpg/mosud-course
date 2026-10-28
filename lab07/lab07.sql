-- Практическая работа №7: NULL, трёхзначная логика и качество данных
-- ФИО: Газдиева Л.М.
-- Группа: ИНБО-21-23

-- 1. Число NULL по необязательным столбцам
SELECT 'orders' AS tbl, COUNT(*) AS total,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_delivered,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated
FROM olist.orders
UNION ALL
SELECT 'products', COUNT(*),
    COUNT(*) FILTER (WHERE product_category_name IS NULL),
    COUNT(*) FILTER (WHERE product_weight_g IS NULL),
    COUNT(*) FILTER (WHERE product_length_cm IS NULL),
    COUNT(*) FILTER (WHERE product_height_cm IS NULL)
FROM olist.products
UNION ALL
SELECT 'order_reviews', COUNT(*),
    COUNT(*) FILTER (WHERE review_comment_title IS NULL),
    COUNT(*) FILTER (WHERE review_comment_message IS NULL),
    NULL, NULL
FROM olist.order_reviews;

-- 2. COUNT(*) vs COUNT(order_delivered_customer_date)
SELECT COUNT(*) AS count_all,
       COUNT(order_delivered_customer_date) AS count_delivered_date
FROM olist.orders;

-- 3. = NULL и <> NULL не работают
SELECT COUNT(*) AS eq_null FROM olist.orders WHERE order_delivered_customer_date = NULL;
SELECT COUNT(*) AS neq_null FROM olist.orders WHERE order_delivered_customer_date <> NULL;
SELECT COUNT(*) AS is_null FROM olist.orders WHERE order_delivered_customer_date IS NULL;
SELECT COUNT(*) AS is_not_null FROM olist.orders WHERE order_delivered_customer_date IS NOT NULL;

-- 4. IS DISTINCT FROM
SELECT
    NULL::text IS DISTINCT FROM 'abc' AS null_vs_value,
    'abc'::text IS DISTINCT FROM 'abc' AS same_value,
    NULL::text IS DISTINCT FROM NULL::text AS null_vs_null,
    NULL::text IS NOT DISTINCT FROM NULL::text AS null_not_distinct_null;

-- 5. NOT IN vs NOT EXISTS с NULL
CREATE TEMP TABLE temp_ids(id text);
INSERT INTO temp_ids VALUES ('e481f51cbdc54678b7cc49136f2d6af7'), (NULL);

SELECT COUNT(*) AS not_in_count
FROM olist.orders o
WHERE o.order_id NOT IN (SELECT id FROM temp_ids);

SELECT COUNT(*) AS not_exists_count
FROM olist.orders o
WHERE NOT EXISTS (SELECT 1 FROM temp_ids t WHERE t.id = o.order_id);

DROP TABLE temp_ids;

-- 6. LEFT JOIN: фильтр в ON vs в WHERE
SELECT COUNT(*) AS filter_in_on
FROM olist.orders o
LEFT JOIN olist.order_reviews r ON r.order_id = o.order_id AND r.review_score >= 4;

SELECT COUNT(*) AS filter_in_where
FROM olist.orders o
LEFT JOIN olist.order_reviews r ON r.order_id = o.order_id
WHERE r.review_score >= 4;

-- 7. COALESCE и NULLIF
SELECT order_id,
       COALESCE(review_comment_message, '(без комментария)') AS comment_filled
FROM olist.order_reviews
LIMIT 5;

SELECT NULLIF(10, 10) AS nullif_equal,
       NULLIF(10, 5) AS nullif_diff,
       100 / NULLIF(0, 0) AS safe_division;

-- 8. Мини-профиль качества
SELECT
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) / COUNT(*), 2) AS pct_orders_no_delivery
FROM olist.orders;

SELECT
    ROUND(100.0 * COUNT(*) FILTER (WHERE product_category_name IS NULL) / COUNT(*), 2) AS pct_products_no_category
FROM olist.products;

SELECT
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_comment_message IS NULL) / COUNT(*), 2) AS pct_reviews_no_text
FROM olist.order_reviews;

-- 9. Естественный NULL vs проблемный NULL
-- Естественный: order_reviews.review_comment_message — клиент может не писать текст
SELECT COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS natural_nulls
FROM olist.order_reviews;

-- Проблемный: products.product_category_name — товар без категории это потеря данных
SELECT COUNT(*) FILTER (WHERE product_category_name IS NULL) AS problem_nulls
FROM olist.products;