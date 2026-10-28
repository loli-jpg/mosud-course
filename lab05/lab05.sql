-- Практическая работа №5: Кванторы, EXISTS и реляционное деление
-- ФИО: Газдиева Лоли Магомедовна
-- Группа: ИНБО-21-23
-- Вариант: 6 (S = PA, AM, RO)

-- 1. CTE target_states
WITH target_states AS (
    SELECT unnest(ARRAY['PA','AM','RO']) AS customer_state --в отд строку
)
SELECT * FROM target_states;

-- 2. Двойной NOT EXISTS/«категория продавалась во всех штатах S»
WITH target_states AS (
    SELECT unnest(ARRAY['PA','AM','RO']) AS customer_state
)
SELECT DISTINCT p.product_category_name
FROM olist.products p
WHERE p.product_category_name IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM target_states ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM olist.order_items oi
        JOIN olist.orders o ON o.order_id = oi.order_id
        JOIN olist.customers c ON c.customer_id = o.customer_id
        WHERE o.order_status = 'delivered'
        AND oi.product_id = p.product_id
        AND c.customer_state = ts.customer_state
    )
)
ORDER BY p.product_category_name;

-- 3. GROUP BY / HAVING COUNT(DISTINCT)
WITH target_states AS (
    SELECT unnest(ARRAY['PA','AM','RO']) AS customer_state
),
sold AS (
    SELECT p.product_category_name, c.customer_state
    FROM olist.products p
    JOIN olist.order_items oi ON oi.product_id = p.product_id
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    AND p.product_category_name IS NOT NULL
    AND c.customer_state IN (SELECT customer_state FROM target_states)
    GROUP BY p.product_category_name, c.customer_state
)
SELECT product_category_name
FROM sold
GROUP BY product_category_name
HAVING COUNT(DISTINCT customer_state) = (SELECT COUNT(*) FROM target_states)
ORDER BY product_category_name;

-- 4. EXCEPT
WITH target_states AS (
    SELECT unnest(ARRAY['PA','AM','RO']) AS customer_state
),
sold AS (
    SELECT DISTINCT p.product_category_name, c.customer_state
    FROM olist.products p
    JOIN olist.order_items oi ON oi.product_id = p.product_id
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    AND p.product_category_name IS NOT NULL
    AND c.customer_state IN (SELECT customer_state FROM target_states)
)
SELECT DISTINCT s.product_category_name
FROM sold s
EXCEPT
SELECT p.product_category_name
FROM olist.products p
CROSS JOIN target_states ts
WHERE p.product_category_name IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sold s
    WHERE s.product_category_name = p.product_category_name
    AND s.customer_state = ts.customer_state
);

-- 5. Проверка эквивалентности
WITH target_states AS (
    SELECT unnest(ARRAY['PA','AM','RO']) AS customer_state
),
r1 AS (
    SELECT DISTINCT p.product_category_name
    FROM olist.products p
    WHERE p.product_category_name IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM target_states ts
        WHERE NOT EXISTS (
            SELECT 1
            FROM olist.order_items oi
            JOIN olist.orders o ON o.order_id = oi.order_id
            JOIN olist.customers c ON c.customer_id = o.customer_id
            WHERE o.order_status = 'delivered'
            AND oi.product_id = p.product_id
            AND c.customer_state = ts.customer_state
        )
    )
),
r2 AS (
    SELECT p.product_category_name
    FROM olist.products p
    JOIN olist.order_items oi ON oi.product_id = p.product_id
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    AND p.product_category_name IS NOT NULL
    AND c.customer_state IN (SELECT customer_state FROM target_states)
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT c.customer_state) = (SELECT COUNT(*) FROM target_states)
)
SELECT 'r1 EXCEPT r2' AS side, COUNT(*) AS diff
FROM (SELECT * FROM r1 EXCEPT SELECT * FROM r2) x
UNION ALL
SELECT 'r2 EXCEPT r1', COUNT(*)
FROM (SELECT * FROM r2 EXCEPT SELECT * FROM r1) x;

-- 6. Диагностика для одной категории
WITH target_states AS (
    SELECT unnest(ARRAY['PA','AM','RO']) AS customer_state
),
chosen AS (
    SELECT p.product_category_name
    FROM olist.products p
    JOIN olist.order_items oi ON oi.product_id = p.product_id
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    AND p.product_category_name IS NOT NULL
    AND c.customer_state IN (SELECT customer_state FROM target_states)
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT c.customer_state) = (SELECT COUNT(*) FROM target_states)
    LIMIT 1
)
SELECT p.product_category_name, c.customer_state, COUNT(DISTINCT o.order_id) AS orders_count
FROM olist.products p
JOIN olist.order_items oi ON oi.product_id = p.product_id
JOIN olist.orders o ON o.order_id = oi.order_id
JOIN olist.customers c ON c.customer_id = o.customer_id
CROSS JOIN chosen ch
WHERE o.order_status = 'delivered'
AND p.product_category_name = ch.product_category_name
AND c.customer_state IN (SELECT customer_state FROM target_states)
GROUP BY p.product_category_name, c.customer_state
ORDER BY c.customer_state;

-- 7. Пустой target_states: NOT EXISTS
WITH target_states AS (
    SELECT unnest(ARRAY[]::text[]) AS customer_state
)
SELECT COUNT(DISTINCT p.product_category_name) AS categories
FROM olist.products p
WHERE p.product_category_name IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM target_states ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM olist.order_items oi
        JOIN olist.orders o ON o.order_id = oi.order_id
        JOIN olist.customers c ON c.customer_id = o.customer_id
        WHERE o.order_status = 'delivered'
        AND oi.product_id = p.product_id
        AND c.customer_state = ts.customer_state
    )
);

-- 7b. Пустой target_states: GROUP BY / HAVING
WITH target_states AS (
    SELECT unnest(ARRAY[]::text[]) AS customer_state
)
SELECT COUNT(DISTINCT p.product_category_name) AS categories
FROM olist.products p
JOIN olist.order_items oi ON oi.product_id = p.product_id
JOIN olist.orders o ON o.order_id = oi.order_id
JOIN olist.customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
AND p.product_category_name IS NOT NULL
AND c.customer_state IN (SELECT customer_state FROM target_states)
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT c.customer_state) = (SELECT COUNT(*) FROM target_states);

-- 8. Продавцы, продававшие во всех штатах S
WITH target_states AS (
    SELECT unnest(ARRAY['PA','AM','RO']) AS customer_state
)
SELECT s.seller_id
FROM olist.sellers s
WHERE NOT EXISTS (
    SELECT 1 FROM target_states ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM olist.order_items oi
        JOIN olist.orders o ON o.order_id = oi.order_id
        JOIN olist.customers c ON c.customer_id = o.customer_id
        WHERE o.order_status = 'delivered'
        AND oi.seller_id = s.seller_id
        AND c.customer_state = ts.customer_state
    )
)
ORDER BY s.seller_id;