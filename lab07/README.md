# Практическая работа №7: NULL, трёхзначная логика и качество данных

## Выполнил
- ФИО: Газдиева Л.М.
- Группа: ИНБО-21-23

## 1. NULL по необязательным столбцам
Подсчитано через `COUNT(*) FILTER (WHERE ... IS NULL)` для orders, products, order_reviews.

## 2. COUNT(*) vs COUNT(column)
- `COUNT(*)` считает все строки, включая те, где столбец NULL.
- `COUNT(order_delivered_customer_date)` считает только не-NULL значения.
- Разница = число заказов без фактической даты доставки.

## 3. = NULL и <> NULL
Оба возвращают **0 строк**: сравнение с NULL даёт UNKNOWN, а WHERE пропускает только TRUE. Работает только `IS NULL` / `IS NOT NULL`.

## 4. IS DISTINCT FROM
- `NULL IS DISTINCT FROM 'abc'` → TRUE (NULL отличается от значения)
- `'abc' IS DISTINCT FROM 'abc'` → FALSE (равны)
- `NULL IS DISTINCT FROM NULL` → FALSE (NULL не отличается от NULL)
- `NULL IS NOT DISTINCT FROM NULL` → TRUE

`IS DISTINCT FROM` — это «безопасное <>», учитывающее NULL.

## 5. NOT IN vs NOT EXISTS с NULL
- **NOT IN** с NULL в подзапросе возвращает **0 строк**: `x NOT IN (a, NULL)` = `x ≠ a AND x ≠ NULL` = `UNKNOWN AND UNKNOWN` = UNKNOWN.
- **NOT EXISTS** возвращает корректный результат: NULL в подзапросе не ломает логику.

**Вывод:** для антисоединений безопаснее `NOT EXISTS`.

## 6. LEFT JOIN: ON vs WHERE
- **Фильтр в ON:** `LEFT JOIN ... ON ... AND review_score >= 4` — сохраняет все заказы, у которых нет отзывов с score ≥ 4 (review_score = NULL). Число строк = числу заказов.
- **Фильтр в WHERE:** `WHERE review_score >= 4` — отбрасывает NULL-строки, превращая LEFT JOIN в INNER JOIN. Число строк меньше.

**Семантика:** предикат в ON применяется при соединении, в WHERE — после. NULL в правой таблице не проходит `>= 4`, поэтому WHERE отбрасывает «левые без пары».

## 7. COALESCE и NULLIF
- `COALESCE(review_comment_message, '(без комментария)')` — заменяет NULL на текст.
- `NULLIF(10, 10)` → NULL; `NULLIF(10, 5)` → 10. Используется для безопасного деления: `100 / NULLIF(0, 0)` → NULL вместо ошибки деления на ноль.

## 8. Мини-профиль качества
- Доля заказов без фактической даты доставки
- Доля товаров без категории
- Доля отзывов без текста

См. lab07.sql, блок 8.

## 9. Естественный vs проблемный NULL
- **Естественный:** `order_reviews.review_comment_message` — клиент вправе не писать комментарий. NULL = «не оставил», это норма.
- **Проблемный:** `products.product_category_name` — товар без категории это потеря данных, затрудняет аналитику. NULL здесь = «не заполнено», проблема качества.

## Контрольные вопросы

**1.** NULL означает «неизвестно». Сравнение «неизвестно = неизвестно» не даёт TRUE, потому что мы не знаем, равны ли два неизвестных значения. Результат — UNKNOWN.

**2.** Предикат в WHERE применяется **после** внешнего соединения. Строки, где правая таблица дала NULL, не проходят условие `column >= 4` (NULL >= 4 = UNKNOWN), поэтому отбрасываются. LEFT JOIN фактически превращается в INNER JOIN.

**3.** `NOT IN` с NULL в подзапросе даёт UNKNOWN для всех проверяемых значений: `x NOT IN (a, NULL)` = `x ≠ a AND x ≠ NULL` = `... AND UNKNOWN` = UNKNOWN. `NOT EXISTS` проверяет «нет ли строки», NULL не мешает — условие `t.id = o.order_id` при NULL даёт UNKNOWN, но EXISTS смотрит только на факт наличия строки, а не на её значение.