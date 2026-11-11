-- Практическая работа №8: ER-модель и расширение предметной области
-- ФИО: Газдиева Лоли Магомедовна
-- Группа: ИНБО-21-23
-- Вариант: 6 (попытки доставки)

DROP TABLE IF EXISTS lab.delivery_events CASCADE;
DROP TABLE IF EXISTS lab.delivery_attempts CASCADE;
DROP TABLE IF EXISTS lab.shipments CASCADE;

-- Отправления
CREATE TABLE lab.shipments (
    shipment_id integer GENERATED ALWAYS AS IDENTITY,
    order_id text NOT NULL,
    seller_id text NOT NULL,
    status text NOT NULL,
    created_at timestamp NOT NULL DEFAULT now(),
    CONSTRAINT pk_shipments PRIMARY KEY (shipment_id),
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id),
    CONSTRAINT fk_shipments_seller FOREIGN KEY (seller_id)
        REFERENCES olist.sellers(seller_id),
    CONSTRAINT uq_shipments_order_seller UNIQUE (order_id, seller_id),
    CONSTRAINT ck_shipments_status CHECK (
        status IN ('created','in_transit','delivered','returned','lost')
    )
);

-- Попытки доставки
CREATE TABLE lab.delivery_attempts (
    attempt_id integer GENERATED ALWAYS AS IDENTITY,
    shipment_id integer NOT NULL,
    attempt_number integer NOT NULL,
    attempted_at timestamp NOT NULL,
    success boolean NOT NULL DEFAULT false,
    reason text,
    CONSTRAINT pk_delivery_attempts PRIMARY KEY (attempt_id),
    CONSTRAINT fk_attempts_shipment FOREIGN KEY (shipment_id)
        REFERENCES lab.shipments(shipment_id),
    CONSTRAINT uq_attempts_shipment_number UNIQUE (shipment_id, attempt_number),
    CONSTRAINT ck_attempts_number_positive CHECK (attempt_number > 0)
);

-- События доставки
CREATE TABLE lab.delivery_events (
    event_id integer GENERATED ALWAYS AS IDENTITY,
    attempt_id integer NOT NULL,
    event_type text NOT NULL,
    event_time timestamp NOT NULL,
    description text,
    CONSTRAINT pk_delivery_events PRIMARY KEY (event_id),
    CONSTRAINT fk_events_attempt FOREIGN KEY (attempt_id)
        REFERENCES lab.delivery_attempts(attempt_id),
    CONSTRAINT ck_events_type CHECK (
        event_type IN ('created','dispatched','arrived','failed','delivered')
    )
);

-- Тестовые данные (реальные order_id, seller_id из Olist)
INSERT INTO lab.shipments (order_id, seller_id, status, created_at)
SELECT o.order_id, oi.seller_id, 'in_transit', now()
FROM olist.orders o
JOIN olist.order_items oi ON oi.order_id = o.order_id
WHERE o.order_id IN (
    'e481f51cbdc54678b7cc49136f2d6af7',
    '53cdb2fc8bc7dce0b6741e2150273451',
    'fa65dad1b0e818e3ccc5cb0e39231352',
    'b81ef226f3fe1789b1e8b2acac839d17',
    'a955df4dbaa2c7b8f1e2e3c0b0a7c2d1'
)
GROUP BY o.order_id, oi.seller_id
LIMIT 5;

INSERT INTO lab.delivery_attempts (shipment_id, attempt_number, attempted_at, success, reason)
SELECT shipment_id, 1, created_at + interval '2 days', false, 'client_absent'
FROM lab.shipments LIMIT 5;

INSERT INTO lab.delivery_attempts (shipment_id, attempt_number, attempted_at, success, reason)
SELECT shipment_id, 2, created_at + interval '4 days', true, NULL
FROM lab.shipments LIMIT 5;

INSERT INTO lab.delivery_events (attempt_id, event_type, event_time, description)
SELECT attempt_id, 'dispatched', attempted_at - interval '1 hour', 'courier left warehouse'
FROM lab.delivery_attempts WHERE attempt_number = 1;

INSERT INTO lab.delivery_events (attempt_id, event_type, event_time, description)
SELECT attempt_id, 'failed', attempted_at, 'client did not answer'
FROM lab.delivery_attempts WHERE attempt_number = 1;

INSERT INTO lab.delivery_events (attempt_id, event_type, event_time, description)
SELECT attempt_id, 'delivered', attempted_at, 'handed to client'
FROM lab.delivery_attempts WHERE attempt_number = 2;

-- Ошибочные операции (в комментариях, не выполняются)
--  Нарушение CHECK: недопустимый статус
-- INSERT INTO lab.shipments (order_id, seller_id, status)
-- VALUES ('e481f51cbdc54678b7cc49136f2d6af7', 'some_seller', 'unknown_status');
-- Отклонит: ck_shipments_status

--  Нарушение UNIQUE: дубликат пары (order_id, seller_id)
-- INSERT INTO lab.shipments (order_id, seller_id, status)
-- VALUES ('e481f51cbdc54678b7cc49136f2d6af7', 'same_seller', 'created');
-- Повторный INSERT с той же парой отклонит: uq_shipments_order_seller

--  Нарушение FK: несуществующий order_id
-- INSERT INTO lab.shipments (order_id, seller_id, status)
-- VALUES ('nonexistent_order', 'some_seller', 'created');
-- Отклонит: fk_shipments_order

--  Нарушение CHECK: отрицательный attempt_number
-- INSERT INTO lab.delivery_attempts (shipment_id, attempt_number, attempted_at)
-- VALUES (1, -1, now());
-- Отклонит: ck_attempts_number_positive

-- Проверка через information_schema
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'lab'
  AND table_name IN ('shipments','delivery_attempts','delivery_events')
ORDER BY table_name, ordinal_position;

SELECT con_name, con_type, table_name
FROM (
    SELECT conname AS con_name,
           contype AS con_type,
           conrelid::regclass::text AS table_name
    FROM pg_constraint
    WHERE connamespace = 'lab'::regnamespace
) t
WHERE table_name IN ('lab.shipments','lab.delivery_attempts','lab.delivery_events')
ORDER BY table_name, con_type;

-- Проверка, что данные загрузились
SELECT 'shipments' AS tbl, COUNT(*) FROM lab.shipments
UNION ALL SELECT 'delivery_attempts', COUNT(*) FROM lab.delivery_attempts
UNION ALL SELECT 'delivery_events', COUNT(*) FROM lab.delivery_events;