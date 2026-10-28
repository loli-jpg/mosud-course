-- Практическая работа №3: Выборка, проекция, переименование и реляционная алгебра
-- ФИО: Газдиева Лоли Магомедовна
-- Группа: ИНБО-21-23
-- Вариант: 6
-- Отношение: order_reviews
-- Предикат: review_score <= 2 AND review_comment_message IS NOT NULL
-- Проекция: order_id, review_score, review_comment_message

-- сколько отзывов с низким баллом и непустым комментарием
SELECT
    order_id,
    review_score,
    review_comment_message
FROM olist.order_reviews
WHERE review_score <= 2 AND review_comment_message IS NOT NULL;

-- Разбиваем предикат на две последовательные выборки
-- Сначала фильтруем по review_score, затем по comment_message
-- Проверяем эквивалентность с запросом 1
SELECT
    order_id,
    review_score,
    review_comment_message
FROM (
    SELECT *
    FROM olist.order_reviews
    WHERE review_score <= 2
) t
WHERE review_comment_message IS NOT NULL;

-- сначала применяем проекцию, потом фильтруем
-- Ненужные столбцы исключаются раньше - меньше данных проходит через фильтры
-- Проверяем эквивалентность с запросом 1
SELECT
    order_id,
    review_score,
    review_comment_message
FROM (
    SELECT order_id, review_score, review_comment_message
    FROM olist.order_reviews
) t
WHERE review_score <= 2
  AND review_comment_message IS NOT NULL;

-- 4. Подсчёт строк в каждом варианте - должны совпадать
-- Проверяем эквивалентность всех трёх вариантов
SELECT 'variant 1 (WHERE AND)' AS variant, count(*) AS rows FROM (
    SELECT order_id, review_score, review_comment_message
    FROM olist.order_reviews
    WHERE review_score <= 2 AND review_comment_message IS NOT NULL
) x
UNION ALL
SELECT 'variant 2 (two filters)', count(*) FROM (
    SELECT order_id, review_score, review_comment_message
    FROM (SELECT * FROM olist.order_reviews WHERE review_score <= 2) t
    WHERE review_comment_message IS NOT NULL
) x
UNION ALL
SELECT 'variant 3 (project early)', count(*) FROM (
    SELECT order_id, review_score, review_comment_message
    FROM (SELECT order_id, review_score, review_comment_message FROM olist.order_reviews) t
    WHERE review_score <= 2 AND review_comment_message IS NOT NULL
) x;

-- Проверка на дубликаты
SELECT count(*) AS total_rows,
       count(DISTINCT (order_id, review_score, review_comment_message)) AS distinct_rows
FROM olist.order_reviews
WHERE review_score <= 2
  AND review_comment_message IS NOT NULL;

-- убираем дубликаты, если они есть
-- Проверяем, меняется ли количество строк
SELECT DISTINCT
    order_id,
    review_score,
    review_comment_message
FROM olist.order_reviews
WHERE review_score <= 2
  AND review_comment_message IS NOT NULL;

-- Проверяем, возникли ли дубликаты в проекции
SELECT 'SELECT' AS variant, count(*) AS rows FROM (
    SELECT order_id, review_score, review_comment_message
    FROM olist.order_reviews
    WHERE review_score <= 2 AND review_comment_message IS NOT NULL
) x
UNION ALL
SELECT 'SELECT DISTINCT', count(*) FROM (
    SELECT DISTINCT order_id, review_score, review_comment_message
    FROM olist.order_reviews
    WHERE review_score <= 2 AND review_comment_message IS NOT NULL
) x;

-- Комментарии:
-- Проекция в реляционной алгебре устраняет дубликаты (это множество).
-- SELECT в SQL оставляет дубликаты (это мультимножество), поэтому
-- для полной эквивалентности математической проекции нужен SELECT DISTINCT.
-- Выборка коммутативна: порядок фильтров можно менять без изменения результата.
-- Проекция не коммутирует с выборкой в общем случае: если фильтр использует
-- столбец, который проекция удалила, - запрос станет невозможным.
-- Поэтому "проекция раньше" допустима только если столбцы для фильтра сохраняются.