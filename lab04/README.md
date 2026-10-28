# Практическая работа №4: Соединения отношений и сложные JOIN

## Выполнил
- ФИО: Газдиева Лоли Магомедовна
- Группа: ИНБО-21-23
- Вариант: 6 (повторные покупатели)

## Сценарий
Маршрут: `customers` по `customer_unique_id` → `orders`.
Акцент: сравнить первую и последнюю покупку клиента, найти повторных покупателей.

## Ключевое различие Olist
- `customer_id` — ID клиента **в конкретном заказе** (уникален для заказа).
- `customer_unique_id` — ID **реального человека**. Один человек может иметь много `customer_id` (по одному на заказ).

Повторный покупатель — тот, у кого по `customer_unique_id` больше одного заказа.

---

## П.1 — Основной запрос (≥3 таблиц)

Соединяет `customers`, `orders`, `order_payments`. Для каждого `customer_unique_id` считает:
- `order_count` — число заказов
- `first_order` / `last_order` — первая и последняя покупка
- `total_paid` — общая сумма платежей

```sql
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id)      AS order_count,
    MIN(o.order_purchase_timestamp) AS first_order,
    MAX(o.order_purchase_timestamp) AS last_order,
    SUM(op.payment_value)           AS total_paid
FROM olist.customers c
JOIN olist.orders o          ON o.customer_id = c.customer_id
JOIN olist.order_payments op ON op.order_id = o.order_id
GROUP BY c.customer_unique_id
ORDER BY order_count DESC
LIMIT 10;
```

**Результат (топ-10 повторных покупателей):**

| order_count | first_order | last_order | total_paid |
|------------:|-------------|------------|-----------:|
| 17 | 2017-05-15 23:30:03 | 2018-08-20 19:14:26 | 927.63 |
| 9  | 2017-09-18 18:53:15 | 2018-02-27 18:36:39 | 1172.66 |
| 7  | 2017-10-09 12:34:39 | 2018-06-01 11:38:29 | 1122.72 |
| 7  | 2017-11-13 16:44:41 | 2018-02-14 13:22:12 | 959.01 |
| 7  | 2017-09-19 01:02:44 | 2018-06-28 00:43:34 | 758.83 |
| 6  | 2017-07-01 04:22:21 | 2018-08-23 00:07:26 | 1094.63 |
| 6  | 2017-05-11 14:39:53 | 2018-05-28 17:20:02 | 826.32 |
| 6  | 2017-01-05 14:18:03 | 2017-01-05 15:25:10 | 110.72 |
| 6  | 2017-08-07 14:14:22 | 2018-01-24 15:15:26 | 944.21 |
| 6  | 2017-11-03 00:16:32 | 2018-01-17 23:34:21 | 660.94 |

**Вывод:** есть клиенты с 17 заказами за 15 месяцев — явные повторные покупатели. Первая покупка у большинства в 2017, последняя — в 2018, период активности больше года.

---

## П.2 — Кратности связей

| Связь | Кратность | Обоснование |
|-------|-----------|-------------|
| `customers.customer_id → orders.customer_id` | **1:1** | Один `customer_id` = один заказ (структура Olist). |
| `customers.customer_unique_id → orders` (через customer_id) | **1:N** | Один реальный человек → много заказов. |
| `orders.order_id → order_payments.order_id` | **1:N** | Один заказ может иметь несколько платежей (`payment_sequential`). |
| `orders.order_id → order_items.order_id` | **1:N** | Один заказ → много позиций. |

---

## П.3 — LEFT JOIN: сохраняем объекты без связанных строк

```sql
SELECT
    c.customer_unique_id,
    o.order_id,
    op.payment_value
FROM olist.customers c
LEFT JOIN olist.orders o         ON o.customer_id = c.customer_id
LEFT JOIN olist.order_payments op ON op.order_id = o.order_id
WHERE o.order_id IS NULL OR op.order_id IS NULL
LIMIT 10;
```

**Важно:** оба `JOIN` — `LEFT`. Если оставить внутренний `JOIN order_payments` после `LEFT JOIN orders`, клиенты без заказов потеряются (`NULL = ... → FALSE`).

**Результат:** пустой (0 строк) — в Olist у каждого `customer_id` есть заказ и платёж. Это подтверждает структуру датасета.

---

## П.4 — Антисоединение

### 4a. Клиенты без заказов

```sql
SELECT c.customer_unique_id
FROM olist.customers c
LEFT JOIN olist.orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;
```

**Результат:** **0 строк.** В Olist не бывает клиентов без заказов — `customers` содержит только тех, кто уже что-то купил.

### 4b. Не повторные покупатели (ровно один заказ)

```sql
WITH per_customer AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS cnt
    FROM olist.customers c
    JOIN olist.orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT customer_unique_id, cnt
FROM per_customer
WHERE cnt = 1
LIMIT 20;
```

**Результат:** много строк — большинство клиентов Olist совершают **один** заказ.

---

## П.5 — Ошибочный JOIN (размножение строк)

```sql
SELECT
    c.customer_unique_id,
    SUM(oi.price)         AS total_items_wrong,
    SUM(op.payment_value) AS total_paid_wrong,
    COUNT(*)              AS rows_count
FROM olist.customers c
JOIN olist.orders o         ON o.customer_id = c.customer_id
JOIN olist.order_items oi   ON oi.order_id = o.order_id
JOIN olist.order_payments op ON op.order_id = o.order_id
GROUP BY c.customer_unique_id
ORDER BY rows_count DESC
LIMIT 5;
```

**Результат (топ по размножению):**

| customer_unique_id | total_items_wrong | total_paid_wrong | rows_count |
|--------------------|------------------:|-----------------:|-----------:|
| 830d5b7aaa3b6f1e9ad63703bec97d23 | 2847.78 | 556.13 | **75** |
| 6fbc7cdadbb522125f4b27ae9dee4060 | 3039.62 | 411.48 | **38** |
| f9ae226291893fda10af7965268fb7f6 | 5436.50 | 946.47 | **35** |
| 8af7ac63b2efbcbd88e5b11505e8098a | 11383.95 | 457.99 | **29** |
| 569aa12b73b5f7edeaa6f2a01603e381 | 1299.74 | 62.68 | **26** |

**Причина размножения:** `order_items` и `order_payments` — обе 1:N по `order_id`. Прямое соединение даёт **декартово произведение внутри заказа**:
```
(позиции заказа) × (платежи заказа)
```

Пример: клиент с `rows_count = 75` — если у него 5 заказов, в среднем 15 строк на заказ. Значит, где-то 3 позиции × 5 платежей = 15 строк.

**Что завышено:**
- `COUNT(*)` — считает строки после размножения, а не заказы
- `SUM(oi.price)` — каждая позиция посчитана `(число платежей)` раз
- `SUM(op.payment_value)` — каждый платёж посчитан `(число позиций)` раз

---

## П.6 — Исправление (предварительная агрегация)

```sql
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
JOIN olist.orders o     ON o.customer_id = c.customer_id
JOIN items_agg ia       ON ia.order_id = o.order_id
JOIN payments_agg pa    ON pa.order_id = o.order_id
GROUP BY c.customer_unique_id
ORDER BY total_paid_correct DESC
LIMIT 5;
```

**Результат (топ-5 по сумме):**

| customer_unique_id | total_items_correct | total_paid_correct | order_count |
|--------------------|--------------------:|-------------------:|------------:|
| 0a0a92112bd4c708ca5fde585afaa872 | 13440.00 | 13664.08 | 1 |
| da122df9eeddfedc1dc1f5349a1a690c | 7388.00  | 7571.63  | 2 |
| 763c8b1c9c68a0229c42c9fc6f662b93 | 7160.00  | 7274.88  | 1 |
| dc4802a71eae9be1dd28f5d788ceb526 | 6735.00  | 6929.31  | 1 |
| 459bef486812aa25204be022145caa62 | 6729.00  | 6922.21  | 1 |

**Почему работает:** `items_agg` и `payments_agg` дают **по одной строке на заказ**. После `JOIN` — одна строка на заказ. Размножения нет. `SUM` по такой выборке — правильный.

**Альтернатива** — `COUNT(DISTINCT order_id)` спасает **только COUNT**, но **не SUM**. Для `SUM` обязательна предварительная агрегация.

---

## П.7 — Композиция операций реляционной алгебры

Основной запрос:

```
γ_{customer_unique_id; COUNT(order_id), MIN(order_purchase_timestamp), MAX(order_purchase_timestamp), SUM(payment_value)}(
    π_{customer_unique_id, order_id, order_purchase_timestamp, payment_value}(
        customers ⋈_{customers.customer_id = orders.customer_id} orders
                  ⋈_{orders.order_id = order_payments.order_id} order_payments
    )
)
```