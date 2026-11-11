# Практическая работа №9: Функциональные зависимости и нормализация

## Выполнил
- ФИО: Газдиева ЛМ
- Группа: ИНБО-21-23
- Вариант: 6 (delivery_flat)

## Исходное отношение
delivery_flat(shipment_id, order_id, seller_id, seller_city, attempt_no, attempt_time, event_code, event_name)

text

## 1. Функциональные зависимости

| Правило | ФЗ |
|---------|-----|
| Отправление → заказ, продавец | `shipment_id → order_id, seller_id` |
| Продавец → город | `seller_id → seller_city` |
| Код события → название | `event_code → event_name` |
| Отправление + номер попытки → время, событие | `(shipment_id, attempt_no) → attempt_time, event_code` |

## 2. Потенциальный ключ
Кандидат `(shipment_id, attempt_no)`. Замыкание:
{shipment_id, attempt_no}+ =
{shipment_id, attempt_no, order_id, seller_id, seller_city, attempt_time, event_code, event_name}

text
Покрывает все атрибуты. Минимальный.

## 3. Частичные и транзитивные зависимости

**Частичные:** `shipment_id → order_id, seller_id` — зависит от части составного ключа.

**Транзитивные:** `shipment_id → seller_id → seller_city`; `attempt_no → event_code → event_name`.

## 4. Аномалии плоской таблицы

**INSERT:** нельзя добавить продавца с городом без отправления — нет места.

**UPDATE:** изменение города продавца требует обновления всех его строк; пропуск → противоречие.

**DELETE:** удаление последнего отправления продавца теряет информацию о его городе.

## 5. Декомпозиция

### Шаг 1: 1НФ → 2НФ
Устранение частичных зависимостей. Вынесли `shipments(shipment_id, order_id, seller_id)` и `attempts(shipment_id, attempt_no, attempt_time, event_code)`.

### Шаг 2: 2НФ → 3НФ
Устранение транзитивных зависимостей:
- `seller_id → seller_city` → вынесли `sellers(seller_id, seller_city)`.
- `event_code → event_name` → вынесли `events(event_code, event_name)`.

### Итоговая схема (3НФ)
sellers(seller_id PK, seller_city NOT NULL)
events(event_code PK, event_name NOT NULL)
shipments(shipment_id PK, order_id NOT NULL, seller_id NOT NULL FK)
attempts(shipment_id PK/FK, attempt_no PK, attempt_time NOT NULL, event_code NOT NULL FK)

text

## 6. НФБК
Все детерминанты — суперключи:
- `seller_id` — PK в sellers
- `event_code` — PK в events
- `shipment_id` — PK в shipments
- `(shipment_id, attempt_no)` — PK в attempts

Схема в **НФБК** без потери зависимостей.

## 7–8. Реализация и проверка
См. `lab09.sql`. После вставки тестовых строк:
- Города продавцов хранятся по одному разу (`sellers`).
- Названия событий хранятся по одному разу (`events`).
- Данные связаны через PK/FK, дубликатов нет.

## Контрольные вопросы

**1. Что означает замыкание множества атрибутов?**
Замыкание `X+` — множество всех атрибутов, которые функционально определяются набором `X` по заданным ФЗ. Используется для проверки, является ли `X` суперключом (если `X+` = все атрибуты).

**2. Чем 3НФ отличается от НФБК?**
3НФ разрешает транзитивные зависимости от ключа, если детерминант — неключевой атрибут, но требует, чтобы каждый неключевой атрибут зависел **непосредственно** от ключа. НФБК строже: **каждый** детерминант любой нетривиальной ФЗ должен быть суперключом. 3НФ ослабляет требование для неключевых детерминантов.

**3. Что значит «декомпозиция без потерь»?**
Декомпозиция `R` на `R1, R2` без потерь означает, что естественное соединение `R1 ⋈ R2` даёт **исходное** `R` (без потери и без добавления строк). Проверяется: `R1 ∩ R2 → R1` или `R1 ∩ R2 → R2` — общие атрибуты должны быть ключом хотя бы одной части.