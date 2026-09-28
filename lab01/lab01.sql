-- Практическая работа №1
-- ФИО: Газдиева Лоли Магомедовна
-- Группа: ИНБО-21-23
-- Вариант: общий

-- Создание схем
CREATE SCHEMA IF NOT EXISTS olist;
CREATE SCHEMA IF NOT EXISTS lab;

-- Создание таблиц
CREATE TABLE olist.customers (
    customer_id text NOT NULL,
    customer_unique_id text,
    customer_zip_code_prefix integer,
    customer_city text,
    customer_state text
);


CREATE TABLE olist.geolocation (
    geolocation_zip_code_prefix integer,
    geolocation_lat numeric(12,8),
    geolocation_lng numeric(12,8),
    geolocation_city text,
    geolocation_state text
);


CREATE TABLE olist.orders (
    order_id text NOT NULL,
    customer_id text NOT NULL,
    order_status text,
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);


CREATE TABLE olist.order_items (
    order_id text NOT NULL,
    order_item_id integer NOT NULL,
    product_id text NOT NULL,
    seller_id text NOT NULL,
    shipping_limit_date timestamp,
    price numeric(10,2),
    freight_value numeric(10,2)
);


CREATE TABLE olist.order_payments (
    order_id text NOT NULL,
    payment_sequential integer NOT NULL,
    payment_type text,
    payment_installments integer,
    payment_value numeric(10,2)
);


CREATE TABLE olist.order_reviews (
    review_id text NOT NULL,
    order_id text NOT NULL,
    review_score smallint,
    review_comment_title text,
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp
);


CREATE TABLE olist.products (
    product_id text NOT NULL,
    product_category_name text,
    product_name_lenght integer,
    product_description_lenght integer,
    product_photos_qty integer,
    product_weight_g integer,
    product_length_cm integer,
    product_height_cm integer,
    product_width_cm integer
);


CREATE TABLE olist.sellers (
    seller_id text NOT NULL,
    seller_zip_code_prefix integer,
    seller_city text,
    seller_state text
);


CREATE TABLE olist.product_category_name_translation (
    product_category_name text NOT NULL,
    product_category_name_english text
);

-- Импорт
\copy olist.customers FROM '/data/olist/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy olist.geolocation FROM '/data/olist/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy olist.orders FROM '/data/olist/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy olist.order_items FROM '/data/olist/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy olist.order_payments FROM '/data/olist/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy olist.order_reviews FROM '/data/olist/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy olist.products FROM '/data/olist/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy olist.sellers FROM '/data/olist/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy olist.product_category_name_translation FROM '/data/olist/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Первичные ключи
ALTER TABLE olist.customers ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);
ALTER TABLE olist.orders ADD CONSTRAINT pk_orders PRIMARY KEY (order_id);
ALTER TABLE olist.products ADD CONSTRAINT pk_products PRIMARY KEY (product_id);
ALTER TABLE olist.sellers ADD CONSTRAINT pk_sellers PRIMARY KEY (seller_id);
ALTER TABLE olist.product_category_name_translation
    ADD CONSTRAINT pk_category_translation PRIMARY KEY (product_category_name);
ALTER TABLE olist.order_items
    ADD CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id);
ALTER TABLE olist.order_payments
    ADD CONSTRAINT pk_order_payments PRIMARY KEY (order_id, payment_sequential);
ALTER TABLE olist.order_reviews
    ADD CONSTRAINT pk_order_reviews PRIMARY KEY (review_id, order_id);

-- Внешние ключи
ALTER TABLE olist.orders ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES olist.customers(customer_id);
ALTER TABLE olist.order_items ADD CONSTRAINT fk_items_order
    FOREIGN KEY (order_id) REFERENCES olist.orders(order_id);
ALTER TABLE olist.order_items ADD CONSTRAINT fk_items_product
    FOREIGN KEY (product_id) REFERENCES olist.products(product_id);
ALTER TABLE olist.order_items ADD CONSTRAINT fk_items_seller
    FOREIGN KEY (seller_id) REFERENCES olist.sellers(seller_id);
ALTER TABLE olist.order_payments ADD CONSTRAINT fk_payments_order
    FOREIGN KEY (order_id) REFERENCES olist.orders(order_id);
ALTER TABLE olist.order_reviews ADD CONSTRAINT fk_reviews_order
    FOREIGN KEY (order_id) REFERENCES olist.orders(order_id);

-- Контрольные проверки
-- Кол-во строк в таблицах 
SELECT 'customers' AS table_name, count(*) FROM olist.customers
UNION ALL SELECT 'geolocation', count(*) FROM olist.geolocation
UNION ALL SELECT 'orders', count(*) FROM olist.orders
UNION ALL SELECT 'order_items', count(*) FROM olist.order_items
UNION ALL SELECT 'order_payments', count(*) FROM olist.order_payments
UNION ALL SELECT 'order_reviews', count(*) FROM olist.order_reviews
UNION ALL SELECT 'products', count(*) FROM olist.products
UNION ALL SELECT 'sellers', count(*) FROM olist.sellers
UNION ALL SELECT 'product_category_name_translation', count(*) FROM olist.product_category_name_translation
ORDER BY table_name;

-- NULL в ключевых полях
SELECT 'customers.customer_id' AS field, count(*) AS null_count
FROM olist.customers WHERE customer_id IS NULL
UNION ALL SELECT 'orders.order_id', count(*) FROM olist.orders WHERE order_id IS NULL
UNION ALL SELECT 'order_items.order_id', count(*) FROM olist.order_items WHERE order_id IS NULL
UNION ALL SELECT 'products.product_id', count(*) FROM olist.products WHERE product_id IS NULL
UNION ALL SELECT 'sellers.seller_id', count(*) FROM olist.sellers WHERE seller_id IS NULL;

-- Осиротевшие ссылки
SELECT 'orphan order_items (no order)' AS check_name, count(*) AS count
FROM olist.order_items oi
LEFT JOIN olist.orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'orphan orders (no customer)', count(*)
FROM olist.orders o
LEFT JOIN olist.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'orphan order_items (no product)', count(*)
FROM olist.order_items oi
LEFT JOIN olist.products p ON p.product_id = oi.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'orphan order_items (no seller)', count(*)
FROM olist.order_items oi
LEFT JOIN olist.sellers s ON s.seller_id = oi.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'orphan order_payments (no order)', count(*)
FROM olist.order_payments op
LEFT JOIN olist.orders o ON o.order_id = op.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'orphan order_reviews (no order)', count(*)
FROM olist.order_reviews orv
LEFT JOIN olist.orders o ON o.order_id = orv.order_id
WHERE o.order_id IS NULL;

-- ANALYZE
ANALYZE olist.customers;
ANALYZE olist.orders;
ANALYZE olist.order_items;
ANALYZE olist.products;
ANALYZE olist.sellers;
ANALYZE olist.order_payments;
ANALYZE olist.order_reviews;
ANALYZE olist.geolocation;
ANALYZE olist.product_category_name_translation;