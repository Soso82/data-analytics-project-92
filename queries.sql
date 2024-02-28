--запрос, который считает общее количество покупателей. Название колонки customers_count:
select count(customer_id) as customs_count 
from customers;
------
--Первый отчет о десятке лучших продавцов. Таблица состоит из трех колонок - данных о продавце, суммарной выручке 
--с проданных товаров и количестве проведенных сделок, и отсортирована по убыванию выручки:

--name — имя и фамилия продавца
--operations - количество проведенных сделок
--income — суммарная выручка продавца за все время

--Вариант 1
SELECT  CONCAT_WS(' ', employees.first_name, employees.last_name) AS name,
        COUNT(*) AS operations, 
        SUM(sales.quantity * products.price) AS income
FROM sales
LEFT JOIN employees ON employees.employee_id = sales.sales_person_id
LEFT JOIN products ON products.product_id = sales.product_id 
GROUP BY CONCAT_WS(' ', employees.first_name, employees.last_name)
order by income desc
limit 10;
-----------

--Второй отчет информациz о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам. Таблица отсортирована по выручке по возрастанию.
--name — имя и фамилия продавца
--average_income — средняя выручка продавца за сделку с округлением до целого

WITH subquery AS (
    SELECT first_name || ' ' || last_name AS name,
            ROUND(AVG(quantity * price), 0) AS average_income
    FROM sales
    LEFT JOIN employees ON employees.employee_id = sales.sales_person_id 
    LEFT JOIN products ON products.product_id = sales.product_id 
    GROUP BY first_name || ' ' || last_name
)
SELECT name, average_income
FROM subquery
WHERE average_income < (SELECT AVG(average_income) FROM subquery)
ORDER BY average_income;
---------------------

--Третий отчет по дням недели. 
--name — имя и фамилия продавца
--weekday — название дня недели на английском языке
--income — суммарная выручка продавца в определенный день недели, округленная до целого числа

-- запрос
WITH 
    tab_1 AS (
        SELECT
            s.*,
            e.first_name || ' ' || e.last_name AS salesperson,
            c.first_name || ' ' || c.last_name AS customer,
            s.quantity * p.price AS total_sum,
            to_char(s.sale_date, 'ID') AS number_of_day_week,
            to_char(s.sale_date, 'day') AS day_week
        FROM
            sales s
            LEFT JOIN customers c ON c.customer_id = s.customer_id
            LEFT JOIN employees e ON e.employee_id = s.sales_person_id
            LEFT JOIN products p ON p.product_id = s.product_id
    ),
    tab_2 AS (
        SELECT
            salesperson,
            number_of_day_week,
            day_week,
            SUM(total_sum)
        FROM
            tab_1
        GROUP BY
            salesperson,
            number_of_day_week,
            day_week
        ORDER BY
            number_of_day_week,
            salesperson
    )
select
	salesperson as name,
	day_week as weekday,
	ROUND(sum, 0) as income
FROM tab_2;

SELECT 
    name,
    weekday,
    sum as income
FROM (
    SELECT 
    e.first_name || ' ' || e.last_name AS name,
    CASE 
        WHEN extract(isodow from s.sale_date) = 1 THEN "Monday"
        WHEN extract(isodow from s.sale_date) = 2 THEN "Tuesday"
        WHEN extract(isodow from s.sale_date) = 3 THEN "Wednesday"
        WHEN extract(isodow from s.sale_date) = 4 THEN "Thursday"
        WHEN extract(isodow from s.sale_date) = 5 THEN "Friday"
        WHEN extract(isodow from s.sale_date) = 6 THEN "Saturday"
        WHEN extract(isodow from s.sale_date) = 7 THEN "Sunday"
    END AS weekday,
    round(sum(s.quantity * p.price)) AS sum,
    extract(isodow from s.sale_date) AS number
    FROM 
    sales s 
    JOIN employees e ON s.sales_person_id = e.employee_id 
    JOIN products p ON s.product_id = p.product_id
    GROUP BY 
    e.first_name, e.last_name, weekday, number
    ORDER BY 4, 1) as t;
------

--шаг 6
--Первый отчет - количество покупателей в разных возрастных группах: 10-15, 16-25, 26-40 и 40+. 
--Итоговая таблица должна быть отсортирована по возрастным группам и содержать следующие поля:
--age_category - возрастная группа
--count - количество человек в группе

WITH tab_1 AS 
(
    SELECT 
    *,
        CASE 
	        WHEN age BETWEEN 0 AND 15 THEN '15-'
            WHEN age BETWEEN 16 AND 25 THEN '16-25' 
            WHEN age BETWEEN 26 AND 40 THEN '26-40' 
            ELSE '40+' 
        END AS age_categories
    FROM customers
)
SELECT 
    age_categories,
    COUNT(*) AS count
FROM tab_1
GROUP BY age_categories
order by age_categories;
--------

--Во втором отчете предоставьте данные по количеству уникальных покупателей и выручке, которую они принесли. 
--Сгруппируйте данные по дате, которая представлена в числовом виде ГОД-МЕСЯЦ. Итоговая таблица должна быть отсортирована 
--по дате по возрастанию и содержать следующие поля:
--date - дата в указанном формате
--total_customers - количество покупателей
--income - принесенная выручка

SELECT 
    TO_CHAR(DATE_TRUNC('month', s.sale_date), 'YYYY-MM') AS date,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    SUM(s.quantity * p.price) AS income
FROM 
    sales s
LEFT JOIN 
    products p ON s.product_id = p.product_id 
GROUP BY 
    DATE_TRUNC('month', s.sale_date)
ORDER BY 
    date ASC;
---------------------

--Третий отчет следует составить о покупателях, первая покупка которых была в ходе проведения акций 
--(акционные товары отпускали со стоимостью равной 0). Итоговая таблица должна быть отсортирована по id покупателя и дате покупки. Таблица состоит из следующих полей:
--customer - имя и фамилия покупателя
--sale_date - дата покупки
--seller - имя и фамилия продавца

SELECT 
    sub.customer,
    sub.sale_date,
    sub.seller
FROM 
    (
        SELECT 
            CONCAT(c.first_name, ' ', c.last_name) AS customer,
            s.sale_date,
            CONCAT(e.first_name, ' ', e.last_name) AS seller,
            ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY s.sale_date) AS rn
        FROM 
            sales s
            INNER JOIN customers c ON s.customer_id = c.customer_id
            INNER JOIN employees e ON s.sales_person_id = e.employee_id
            INNER JOIN products p ON s.product_id = p.product_id
        WHERE 
            p.price = 0
    ) sub
WHERE 
    sub.rn = 1
ORDER BY 
    sub.customer, sub.sale_date;
