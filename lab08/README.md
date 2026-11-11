# Практическая работа №8: ER-модель и расширение предметной области

## Выполнил
- ФИО: Газдиева Л.М.
- Группа: ИНБО-21-23
- Вариант: 6 (попытки доставки)

## Предметная область
Расширение Olist: учёт **отправлений**, **попыток доставки** и **событий** по каждой попытке. Позволяет отслеживать, сколько раз курьер пытался доставить заказ, чем закончилась каждая попытка, и какие события происходили.

## ER-модель
olist.orders ──1:N──┐
├──→ lab.shipments ──1:N──→ lab.delivery_attempts ──1:N──→ lab.delivery_events
olist.sellers ─1:N──┘


**Сущности:**
- **shipments** — отправление (заказ + продавец). Уникально по паре `(order_id, seller_id)`.
- **delivery_attempts** — попытки доставки одного отправления. Уникальны по паре `(shipment_id, attempt_number)`.
- **delivery_events** — события внутри попытки (создано, отправлено, прибыло, провал, доставлено).

**Кратности:**
- `olist.orders → lab.shipments` — 1:N, обязательная
- `olist.sellers → lab.shipments` — 1:N, обязательная
- `lab.shipments → lab.delivery_attempts` — 1:N, обязательная
- `lab.delivery_attempts → lab.delivery_events` — 1:N, обязательная

## Бизнес-правила и ограничения

| № | Правило | Ограничение | Тип |
|---|---------|-------------|-----|
| 1 | Отправление относится к реальному заказу | `fk_shipments_order` | FK |
| 2 | Отправление имеет реального продавца | `fk_shipments_seller` | FK |
| 3 | Один продавец по заказу = одно отправление | `uq_shipments_order_seller` | UNIQUE (составной) |
| 4 | Статус — из фиксированного списка | `ck_shipments_status` | CHECK |
| 5 | Попытка относится к существующему отправлению | `fk_attempts_shipment` | FK |
| 6 | Номер попытки положительный | `ck_attempts_number_positive` | CHECK |
| 7 | Номер попытки уникален в рамках отправления | `uq_attempts_shipment_number` | UNIQUE (составной) |
| 8 | Событие относится к существующей попытке | `fk_events_attempt` | FK |
| 9 | Тип события — из фиксированного списка | `ck_events_type` | CHECK |
| 10 | Время события обязательно | `NOT NULL` на `event_time` | NOT NULL |

## Ошибочные операции (должны отклоняться)

**5a. Недопустимый статус**
```sql
INSERT INTO lab.shipments (order_id, seller_id, status)
VALUES ('e481f51cbdc54678b7cc49136f2d6af7', 'some_seller', 'unknown_status');
Отклонит ck_shipments_status: статус не входит в ('created','in_transit','delivered','returned','lost').

5b. Дубликат пары (order_id, seller_id)

sql
INSERT INTO lab.shipments (order_id, seller_id, status)
VALUES ('e481f51cbdc54678b7cc49136f2d6af7', 'existing_seller', 'created');
Отклонит uq_shipments_order_seller: нарушение UNIQUE.

5c. Несуществующий order_id

sql
INSERT INTO lab.shipments (order_id, seller_id, status)
VALUES ('nonexistent_order', 'some_seller', 'created');
Отклонит fk_shipments_order: ссылка на несуществующий заказ.

5d. Отрицательный номер попытки

sql
INSERT INTO lab.delivery_attempts (shipment_id, attempt_number, attempted_at)
VALUES (1, -1, now());
Отклонит ck_attempts_number_positive: attempt_number > 0.