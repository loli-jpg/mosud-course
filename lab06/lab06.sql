-- Практическая работа №6: Подзапросы и логика предикатов
-- ФИО: Газдиева Л.М.
-- Группа: ИНБО-21-23
-- Вариант: 6 (сумма платежей > сумма price+freight по позициям)

-- 1. Основное решение: скалярный подзапрос + EXISTS
SELECT o.order_id
FROM olist.orders o
WHERE o.order_status = 'delivered'
AND (SELECT SUM(op.payment_value) FROM olist.order_payments op WHERE op.order_id = o.order_id)
    > (SELECT SUM(oi.price + oi.freight_value) FROM olist.order_items oi WHERE oi.order_id = o.order_id)
AND EXISTS (SELECT 1 FROM olist.order_payments op WHERE op.order_id = o.order_id)
AND EXISTS (SELECT 1 FROM olist.order_items oi WHERE oi.order_id = o.order_id)
ORDER BY o.order_id;

-- 2. Альтернатива: JOIN + CTE с предварительной агрегацией
WITH pay AS (
    SELECT order_id, SUM(payment_value) AS total_paid
    FROM olist.order_payments
    GROUP BY order_id
),
items AS (
    SELECT order_id, SUM(price + freight_value) AS total_items
    FROM olist.order_items
    GROUP BY order_id
)
SELECT o.order_id
FROM olist.orders o
JOIN pay p ON p.order_id = o.order_id
JOIN items i ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
AND p.total_paid > i.total_items
ORDER BY o.order_id;

-- 3. Проверка эквивалентности
WITH main AS (
    SELECT o.order_id
    FROM olist.orders o
    WHERE o.order_status = 'delivered'
    AND (SELECT SUM(op.payment_value) FROM olist.order_payments op WHERE op.order_id = o.order_id)
        > (SELECT SUM(oi.price + oi.freight_value) FROM olist.order_items oi WHERE oi.order_id = o.order_id)
    AND EXISTS (SELECT 1 FROM olist.order_payments op WHERE op.order_id = o.order_id)
    AND EXISTS (SELECT 1 FROM olist.order_items oi WHERE oi.order_id = o.order_id)
),
alt AS (
    SELECT o.order_id
    FROM olist.orders o
    JOIN (SELECT order_id, SUM(payment_value) AS total_paid FROM olist.order_payments GROUP BY order_id) p
        ON p.order_id = o.order_id
    JOIN (SELECT order_id, SUM(price + freight_value) AS total_items FROM olist.order_items GROUP BY order_id) i
        ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    AND p.total_paid > i.total_items
)
SELECT 'main EXCEPT alt' AS side, COUNT(*) AS diff FROM (SELECT * FROM main EXCEPT SELECT * FROM alt) x
UNION ALL
SELECT 'alt EXCEPT main', COUNT(*) FROM (SELECT * FROM alt EXCEPT SELECT * FROM main) x;

-- 4. Демонстрация ANY: заказы, где хотя бы один платёж больше 1000
SELECT o.order_id
FROM olist.orders o
WHERE o.order_status = 'delivered'
AND 1000 < ANY (SELECT op.payment_value FROM olist.order_payments op WHERE op.order_id = o.order_id)
LIMIT 10;

-- 5. Демонстрация ALL: заказы, где все позиции дороже 100
SELECT o.order_id
FROM olist.orders o
WHERE o.order_status = 'delivered'
AND 100 < ALL (SELECT oi.price FROM olist.order_items oi WHERE oi.order_id = o.order_id)
AND EXISTS (SELECT 1 FROM olist.order_items oi WHERE oi.order_id = o.order_id)
LIMIT 10;