# Практическая работа №1: Развёртывание PostgreSQL и загрузка Olist

## Выполнил
- ФИО: Газдиева Лоли Магомедовна
- Группа: ИНБО-21-23

## Запуск
docker compose up -d
docker cp lab01\lab01.sql mosud-postgres:/tmp/lab01.sql
docker exec -it mosud-postgres psql -U student -d olist -f /tmp/lab01.sql

## Версия PostgreSQL
PostgreSQL 17

## Способ импорта
Вручную через интерфейс 

## Фактическое количество строк
| Таблица | Количество строк |
|---------|------------------|
| customers | 99441 |
| geolocation | 1000163 |
| orders | 99441 |
| order_items | 112650 |
| order_payments | 103886 |
| order_reviews | 99224 |
| products | 32951 |
| sellers | 3095 |
| product_category_name_translation | 71 |

## Результаты проверок
- NULL в ключевых полях: 0
- Осиротевших ссылок: 0