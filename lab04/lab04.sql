-- Практическая работа №4: Освоить математический смысл соединения и научиться строить запросы из 3–6 связанных таблиц без ошибочного размножения строк.
-- ФИО: Газдиева Лоли Магомедовна
-- Группа: ИНБО-21-23
-- Вариант: 6, Повторные покупатели/customers по customer_unique_id → orders; сравнить первую и последнюю покупку.
-- Отношение: order_reviews
-- Предикат: review_score <= 2 AND review_comment_message IS NOT NULL
-- Проекция: order_id, review_score, review_comment_message

-- Основной запрос

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS order_count,
    MIN(o.order_purchase_timestamp) AS first_order,
    MAX(o.order_purchase_timestamp) AS last_order,
    SUM(op.payment_value) AS total_paid
FROM olist.customers c
JOIN olist.orders o         ON o.customer_id = c.customer_id   -- 1:N
JOIN olist.order_payments op ON op.order_id = o.order_id       -- 1:N
GROUP BY c.customer_unique_id
ORDER BY order_count DESC
LIMIT 10;

-- LEFT JOIN, чобы сохраниличь объекты без связанных строк
SELECT
    c.customer_unique_id,
    o.order_id,
    op.payment_value
FROM olist.customers c
LEFT JOIN olist.orders o ON o.customer_id = c.customer_id
LEFT JOIN olist.order_payments op ON op.order_id = o.order_id
WHERE o.order_id IS NULL OR op.order_id IS NULL
LIMIT 10;

-- Антисоединение, клиенты без заказов
SELECT c.customer_unique_id
FROM olist.customers c
LEFT JOIN olist.orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Ошибочный JOIN
-- У заказа с 3 позициями и 2 платежами получится 6 строк.
-- SUM(oi.price) завышен в 2 раза, SUM(op.payment_value) в 3 раза.
SELECT
    c.customer_unique_id,
    SUM(oi.price) AS total_items_wrong,
    SUM(op.payment_value) AS total_paid_wrong,
    COUNT(*) AS rows_count
FROM olist.customers c
JOIN olist.orders o ON o.customer_id = c.customer_id
JOIN olist.order_items oi ON oi.order_id = o.order_id
JOIN olist.order_payments op ON op.order_id = o.order_id
GROUP BY c.customer_unique_id
ORDER BY rows_count DESC
LIMIT 5;

-- Исправление агрегацией
-- предварительная агрегация order_items и order_payments
WITH items_agg AS (
    SELECT order_id, SUM(price) AS order_items_total
    FROM olist.order_items
    GROUP BY order_id
),
payments_agg AS (
    SELECT order_id, SUM(payment_value) AS order_paid
    FROM olist.order_payments
    GROUP BY order_id
)
SELECT
    c.customer_unique_id,
    SUM(ia.order_items_total) AS total_items_correct,
    SUM(pa.order_paid)        AS total_paid_correct,
    COUNT(DISTINCT o.order_id) AS order_count
FROM olist.customers c
JOIN olist.orders o ON o.customer_id = c.customer_id
JOIN items_agg ia ON ia.order_id = o.order_id
JOIN payments_agg pa ON pa.order_id = o.order_id
GROUP BY c.customer_unique_id
ORDER BY total_paid_correct DESC
LIMIT 5;

/*γ_{customer_unique_id; COUNT(order_id), MIN(order_purchase_timestamp), MAX(order_purchase_timestamp), SUM(payment_value)}(
    π_{customer_unique_id, order_id, order_purchase_timestamp, payment_value}(
        customers ⋈_{customers.customer_id = orders.customer_id} orders
                  ⋈_{orders.order_id = order_payments.order_id} order_payments
    )
)*/
