-- Практическая работа 2
-- ФИО: Газдиева Лоли Магомедовна
-- Группа: ИНБО-21-23
-- Вариант: 6

-- Показать, что разность некоммутативна.

DROP VIEW IF EXISTS lab.a CASCADE;
DROP VIEW IF EXISTS lab.b CASCADE;
-- Множество A. product_id товаров, купленных клиентами из ES
CREATE VIEW lab.a AS
SELECT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON o.order_id = oi.order_id
JOIN olist.customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND c.customer_state = 'ES';

-- Множество B. product_id товаров, купленных клиентами из RJ
CREATE VIEW lab.b AS
SELECT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o ON o.order_id = oi.order_id
JOIN olist.customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ';

-- A union B (множество без дубликатов)
SELECT count(*) AS union_count FROM (SELECT * FROM lab.a UNION SELECT * FROM lab.b) x;
-- A union all B (мультимножество с дубликатами)
SELECT count(*) AS union_all_count FROM (SELECT * FROM lab.a UNION ALL SELECT * FROM lab.b) x;
-- A intersect B
SELECT count(*) AS intersect_count FROM (SELECT * FROM lab.a INTERSECT SELECT * FROM lab.b) x;
-- A except B
SELECT count(*) AS a_minus_b FROM (SELECT * FROM lab.a EXCEPT SELECT * FROM lab.b) x;
-- B except A
SELECT count(*) AS b_minus_a FROM (SELECT * FROM lab.b EXCEPT SELECT * FROM lab.a) x;
-- Коммутативность объединения A и B, B и A
SELECT
  (SELECT count(*) FROM (SELECT * FROM lab.a UNION SELECT * FROM lab.b) x) AS a_union_b,
  (SELECT count(*) FROM (SELECT * FROM lab.b UNION SELECT * FROM lab.a) x) AS b_union_a;
-- Коммутативность их пересечения
SELECT
  (SELECT count(*) FROM (SELECT * FROM lab.a INTERSECT SELECT * FROM lab.b) x) AS a_intersect_b,
  (SELECT count(*) FROM (SELECT * FROM lab.b INTERSECT SELECT * FROM lab.a) x) AS b_intersect_a;
-- Некоммутативность разности
SELECT
  (SELECT count(*) FROM (SELECT * FROM lab.a EXCEPT SELECT * FROM lab.b) x) AS a_minus_b,
  (SELECT count(*) FROM (SELECT * FROM lab.b EXCEPT SELECT * FROM lab.a) x) AS b_minus_a;
-- Пересечение через EXISTS
SELECT count(*) AS intersect_via_exists
FROM (SELECT DISTINCT product_id FROM lab.a) a
WHERE EXISTS (SELECT 1 FROM lab.b WHERE lab.b.product_id = a.product_id);
-- Дубликаты
SELECT
  count(*) AS multiset_size,
  count(DISTINCT product_id) AS set_size,
  count(*) - count(DISTINCT product_id) AS duplicates
FROM (SELECT * FROM lab.a UNION ALL SELECT * FROM lab.b) x;

-- UNION, INTERSECT, EXCEPT без ALL возвращают множество - дубликаты устраняются.
-- UNION ALL, INTERSECT ALL, EXCEPT ALL возвращают мультимножество - дубликаты сохраняются.
-- UNION коммутативен: A и B = B и A.
-- INTERSECT коммутативен: A и B = B и A.
-- EXCEPT НЕ коммутативен: A - B != B - A.
