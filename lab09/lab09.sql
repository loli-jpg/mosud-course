-- Практическая работа №9: Функциональные зависимости и нормализация
-- ФИО: Газдиева ЛМ
-- Группа: ИНБО-21-23
-- Вариант: 6 (delivery_flat)

DROP TABLE IF EXISTS lab.nf_v6_attempts CASCADE;
DROP TABLE IF EXISTS lab.nf_v6_shipments CASCADE;
DROP TABLE IF EXISTS lab.nf_v6_events CASCADE;
DROP TABLE IF EXISTS lab.nf_v6_sellers CASCADE;

CREATE TABLE lab.nf_v6_sellers (
    seller_id text NOT NULL,
    seller_city text NOT NULL,
    CONSTRAINT pk_nf_v6_sellers PRIMARY KEY (seller_id)
);

CREATE TABLE lab.nf_v6_events (
    event_code text NOT NULL,
    event_name text NOT NULL,
    CONSTRAINT pk_nf_v6_events PRIMARY KEY (event_code)
);

CREATE TABLE lab.nf_v6_shipments (
    shipment_id integer NOT NULL,
    order_id text NOT NULL,
    seller_id text NOT NULL,
    CONSTRAINT pk_nf_v6_shipments PRIMARY KEY (shipment_id),
    CONSTRAINT fk_nf_v6_ship_seller FOREIGN KEY (seller_id)
        REFERENCES lab.nf_v6_sellers(seller_id)
);

CREATE TABLE lab.nf_v6_attempts (
    shipment_id integer NOT NULL,
    attempt_no integer NOT NULL,
    attempt_time timestamp NOT NULL,
    event_code text NOT NULL,
    CONSTRAINT pk_nf_v6_attempts PRIMARY KEY (shipment_id, attempt_no),
    CONSTRAINT fk_nf_v6_attempt_ship FOREIGN KEY (shipment_id)
        REFERENCES lab.nf_v6_shipments(shipment_id),
    CONSTRAINT fk_nf_v6_attempt_event FOREIGN KEY (event_code)
        REFERENCES lab.nf_v6_events(event_code),
    CONSTRAINT ck_nf_v6_attempt_no CHECK (attempt_no > 0)
);

INSERT INTO lab.nf_v6_sellers VALUES
    ('s1', 'São Paulo'),
    ('s2', 'Rio de Janeiro'),
    ('s3', 'Curitiba');

INSERT INTO lab.nf_v6_events VALUES
    ('EV01', 'created'),
    ('EV02', 'dispatched'),
    ('EV03', 'delivered');

INSERT INTO lab.nf_v6_shipments VALUES
    (1001, 'order_aaa', 's1'),
    (1002, 'order_bbb', 's1'),
    (1003, 'order_ccc', 's2'),
    (1004, 'order_ddd', 's3');

INSERT INTO lab.nf_v6_attempts VALUES
    (1001, 1, '2026-01-01 10:00', 'EV01'),
    (1001, 2, '2026-01-02 11:00', 'EV02'),
    (1002, 1, '2026-01-03 12:00', 'EV01'),
    (1002, 2, '2026-01-04 13:00', 'EV03'),
    (1003, 1, '2026-01-05 14:00', 'EV01');

SELECT 'sellers' AS table_name, COUNT(*) AS rows FROM lab.nf_v6_sellers
UNION ALL SELECT 'events', COUNT(*) FROM lab.nf_v6_events
UNION ALL SELECT 'shipments', COUNT(*) FROM lab.nf_v6_shipments
UNION ALL SELECT 'attempts', COUNT(*) FROM lab.nf_v6_attempts;

-- Проверка: город продавца хранится один раз
SELECT s.seller_id, s.seller_city, COUNT(sh.shipment_id) AS shipments_count
FROM lab.nf_v6_sellers s
LEFT JOIN lab.nf_v6_shipments sh ON sh.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_city
ORDER BY s.seller_id;

-- Проверка: название события хранится один раз
SELECT e.event_code, e.event_name, COUNT(a.attempt_no) AS attempts_count
FROM lab.nf_v6_events e
LEFT JOIN lab.nf_v6_attempts a ON a.event_code = e.event_code
GROUP BY e.event_code, e.event_name
ORDER BY e.event_code;