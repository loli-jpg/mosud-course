-- Практическая работа №11: Представления, CTE и рекурсивные запросы
-- ФИО: Газдиева ЛМ
-- Группа: ИНБО-21-23
-- Вариант: 6 (корневой штат SC)

-- 1. Обычное представление: одна строка на заказ
DROP VIEW IF EXISTS lab.v_order_summary CASCADE;
CREATE VIEW lab.v_order_summary AS
SELECT o.order_id,
       c.customer_state,
       COUNT(oi.order_item_id) AS items_count,
       COALESCE(SUM(oi.price + oi.freight_value), 0) AS total_amount
FROM olist.orders o
JOIN olist.customers c ON c.customer_id = o.customer_id
LEFT JOIN olist.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY o.order_id, c.customer_state;

-- 2. Материализованное представление: месяц × штат
DROP MATERIALIZED VIEW IF EXISTS lab.mv_monthly_state_sales CASCADE;
CREATE MATERIALIZED VIEW lab.mv_monthly_state_sales AS
SELECT date_trunc('month', o.order_purchase_timestamp) AS month,
       c.customer_state,
       COUNT(DISTINCT o.order_id) AS orders_count,
       SUM(oi.price + oi.freight_value) AS total_amount
FROM olist.orders o
JOIN olist.customers c ON c.customer_id = o.customer_id
JOIN olist.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1, 2;

-- REFRESH-команда для материализованного представления
-- REFRESH MATERIALIZED VIEW lab.mv_monthly_state_sales;

-- 3. Сложный аналитический запрос через три CTE
WITH monthly AS (
    SELECT date_trunc('month', o.order_purchase_timestamp) AS month,
           c.customer_state,
           COUNT(DISTINCT o.order_id) AS orders_count,
           SUM(oi.price + oi.freight_value) AS total_amount
    FROM olist.orders o
    JOIN olist.customers c ON c.customer_id = o.customer_id
    JOIN olist.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2
),
state_totals AS (
    SELECT customer_state,
           SUM(orders_count) AS total_orders,
           SUM(total_amount) AS total_revenue
    FROM monthly
    GROUP BY customer_state
),
ranked AS (
    SELECT customer_state, total_orders, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM state_totals
)
SELECT * FROM ranked WHERE revenue_rank <= 5 ORDER BY revenue_rank;

-- 4. Иерархия lab.geo_tree
DROP TABLE IF EXISTS lab.geo_tree CASCADE;
CREATE TABLE lab.geo_tree (
    node_id text PRIMARY KEY,
    parent_id text REFERENCES lab.geo_tree(node_id),
    node_type text NOT NULL CHECK (node_type IN ('country','state','city')),
    node_name text NOT NULL
);

INSERT INTO lab.geo_tree VALUES ('BR', NULL, 'country', 'Brazil');

INSERT INTO lab.geo_tree(node_id, parent_id, node_type, node_name)
SELECT 'ST:' || customer_state, 'BR', 'state', customer_state
FROM olist.customers
WHERE customer_state IS NOT NULL
GROUP BY customer_state;

INSERT INTO lab.geo_tree(node_id, parent_id, node_type, node_name)
SELECT 'CT:' || customer_state || ':' || customer_city,
       'ST:' || customer_state,
       'city',
       customer_city
FROM (
    SELECT customer_state, customer_city,
           ROW_NUMBER() OVER (PARTITION BY customer_state ORDER BY COUNT(*) DESC) AS rn
    FROM olist.customers
    WHERE customer_state IS NOT NULL AND customer_city IS NOT NULL
    GROUP BY customer_state, customer_city
) t
WHERE rn <= 20;

-- 5. Рекурсивный запрос: поддерево от SC
WITH RECURSIVE subtree AS (
    SELECT node_id, parent_id, node_name, 0 AS depth,
           node_id::text AS path
    FROM lab.geo_tree
    WHERE node_id = 'ST:SC'
    UNION ALL
    SELECT g.node_id, g.parent_id, g.node_name,
           s.depth + 1,
           s.path || ' -> ' || g.node_id
    FROM lab.geo_tree g
    JOIN subtree s ON g.parent_id = s.node_id
)
SELECT depth, node_id, path, node_name
FROM subtree
ORDER BY path;

-- 6. Обратный рекурсивный запрос: предки выбранного города до BR
WITH RECURSIVE ancestors AS (
    SELECT node_id, parent_id, node_name, 0 AS depth,
           node_id::text AS path
    FROM lab.geo_tree
    WHERE node_id = (
        SELECT node_id FROM lab.geo_tree
        WHERE node_type = 'city'
          AND parent_id = 'ST:SC'
        LIMIT 1
    )
    UNION ALL
    SELECT g.node_id, g.parent_id, g.node_name,
           a.depth + 1,
           a.path || ' -> ' || g.node_id
    FROM lab.geo_tree g
    JOIN ancestors a ON g.node_id = a.parent_id
)
SELECT depth, node_id, path, node_name
FROM ancestors
ORDER BY depth;

-- 7. Количество потомков каждого state-node
WITH RECURSIVE descendants AS (
    SELECT node_id AS ancestor_id, node_id AS descendant_id
    FROM lab.geo_tree
    UNION ALL
    SELECT d.ancestor_id, g.node_id
    FROM lab.geo_tree g
    JOIN descendants d ON g.parent_id = d.descendant_id
)
SELECT ancestor_id, COUNT(*) - 1 AS descendants_count
FROM descendants
WHERE ancestor_id LIKE 'ST:%'
GROUP BY ancestor_id
ORDER BY ancestor_id;

-- 8. Защита от цикла (демонстрация)
-- Если в графе есть цикл, рекурсия зациклится.
-- Защита: добавить в CTE массив посещённых узлов и проверять, что нового нет.
-- Пример:
-- WITH RECURSIVE safe AS (
--     SELECT node_id, parent_id, ARRAY[node_id] AS visited
--     FROM lab.geo_tree WHERE node_id = 'ST:SC'
--     UNION ALL
--     SELECT g.node_id, g.parent_id, s.visited || g.node_id
--     FROM lab.geo_tree g
--     JOIN safe s ON g.parent_id = s.node_id
--     WHERE NOT g.node_id = ANY(s.visited)
-- )
-- SELECT * FROM safe;