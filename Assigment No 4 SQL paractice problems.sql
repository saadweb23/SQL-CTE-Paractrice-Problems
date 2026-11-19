--Q1. List customers from the state of NY who have no phone number on file.
--Show their first name, last name, email and city with the aliases
--First Name, Last Name, Email and City. Sort by last name, then first name,
--and return only the first 10 rows.
SELECT   first_name AS 'First Name',
         last_name AS 'last Name',
         email AS Email,
         city AS City
FROM     sales.customers
WHERE    phone IS NULL
ORDER BY last_name,
         first_name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q2. Find products with a model year of 2017 or 2018, a list price between--
--500 and 1500, whose name contains Trek but does not contain Kids. Show
--product_id, product_name, model_year and list_price, sorted by list_price 
--from highest to lowest.
SELECT   product_id,
         product_name,
         model_year,
         list_price
FROM     production.products
WHERE    list_price BETWEEN 500 AND 1500
         AND model_year IN (
             2017,
             2018
         )
         AND product_name LIKE 'Trek%'
         AND product_name NOT LIKE '%Kids%'
ORDER BY list_price DESC;

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q3. (a) List the distinct values of order_status in sales.orders.
--(b) List orders that have not been shipped yet, placed at store 1 or 3
--during 2018. Show order_id, customer_id, store_id, order_date and 
--required_date, sorted by order_date.
--- a
SELECT DISTINCT (order_status) AS unique_orders
FROM   sales.orders;

--- b
SELECT order_id,
       customer_id,
       store_id,
       order_date,
       required_date,
       shipped_date
FROM   sales.orders
WHERE  store_id IN (
           1,
           3
       )
       AND year(order_date) = 2018
       AND shipped_date IS NULL;

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q4. For order_id = 1, show one row per order line with: order_id, 
--order_date, customer full name, product_name, brand_name, category_name,
--quantity, list_price, discount and line_revenue, 
--where line_revenue = quantity * list_price * (1 - discount) 
--from sales.order_items.
SELECT   c.first_name + ' ' + c.last_name AS customer_name,
         o.order_id,
         p.product_name,
         b.brand_name,
         cat.category_name,
         oi.quantity,
         oi.list_price,
         oi.discount,
         sum(oi.quantity * oi.list_price * (1 - oi.discount)) AS line_Revenue
FROM     sales.customers AS c
         INNER JOIN
         sales.orders AS o
         ON o.customer_id = c.customer_id
         INNER JOIN
         sales.order_items AS oi
         ON oi.order_id = o.order_id
         INNER JOIN
         production.products AS p
         ON p.product_id = oi.product_id
         INNER JOIN
         production.categories AS cat
         ON cat.category_id = p.category_id
         INNER JOIN
         production.brands AS b
         ON b.brand_id = p.brand_id
GROUP BY c.first_name + ' ' + c.last_name,
         o.order_id,
         p.product_name,
         b.brand_name,
         cat.category_name,
         oi.quantity,
         oi.list_price,
         oi.discount
HAVING   o.order_id = 1;

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q5. Show every staff member with their store_name and their manager's
--full name. Staff who have no manager must still appear, with the manager
--shown as 'No Manager'.
SELECT e.first_name + ' ' + e.last_name AS staff_name,
       s.store_name,
       m.first_name + ' ' + m.last_name AS manager_name
FROM   sales.staffs AS e
       LEFT OUTER JOIN
       sales.staffs AS m
       ON e.manager_id = m.staff_id
       INNER JOIN
       sales.stores AS s
       ON s.store_id = e.store_id;

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q6. List products that have never been ordered. Show product_id,
--product_name, brand_name and model_year.
SELECT p.product_id,
       p.product_name,
       p.model_year,
       b.brand_name
FROM   production.products AS p
       INNER JOIN
       production.brands AS b
       ON b.brand_id = p.brand_id
WHERE  NOT EXISTS (SELECT 1
                   FROM   sales.order_items AS oi
                   WHERE  oi.product_id = p.product_id);


-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q7. (a) Create a view sales.vw_order_line_details that returns the
--Q4 details for all orders, also including store_name and order_status.
--(b) Query the view to return all order lines from January 2018, sorted
--by order_date, then order_id.

--- (a
CREATE OR ALTER VIEW sales.vw_order_line_details
AS

SELECT
    o.order_id,
    o.order_date,
    c.first_name + ' ' + c.last_name AS customer_name,
    p.product_name,
    b.brand_name,
    cat.category_name,
    oi.quantity,
    oi.list_price,
    oi.discount,
    oi.quantity * oi.list_price * (1 - oi.discount) AS line_revenue,
    s.store_name,
    o.order_status

FROM sales.orders o

JOIN sales.order_items oi
    ON o.order_id = oi.order_id

JOIN sales.customers c
    ON o.customer_id = c.customer_id

JOIN production.products p
    ON oi.product_id = p.product_id

JOIN production.brands b
    ON p.brand_id = b.brand_id

JOIN production.categories cat
    ON p.category_id = cat.category_id

JOIN sales.stores s
    ON o.store_id = s.store_id;

--- (b

SELECT *
FROM sales.vw_order_line_details
WHERE order_date >= '2018-01-01'
  AND order_date < '2018-02-01'
ORDER BY
    order_date,
    order_id; 

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q8. (a) Create a view production.vw_product_catalog with product_id,
--product_name, brand_name, category_name, model_year and list_price.
--(b) Using only this view, return all Electric Bikes priced above 3000,
--sorted by price from highest to lowest.

--- (a
CREATE OR ALTER VIEW production.vw_product_catalog
AS
SELECT
    p.product_id,
    p.product_name,
    b.brand_name,
    c.category_name,
    p.model_year,
    p.list_price
FROM production.products AS p
INNER JOIN production.categories AS c
    ON c.category_id = p.category_id
INNER JOIN production.brands AS b
    ON b.brand_id = p.brand_id;

--- (b

select * from production.vw_product_catalog
where category_name = 'Electric Bikes' and list_price > 3000
order by list_price desc;

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q9. Using sales.vw_order_line_details, show the total number of distinct
--orders and total revenue for each store in each year. Sort by store_name,
--then year.

select 
count(distinct order_id) as total_orders,
store_name,
year(order_date) as order_year,
sum(quantity * list_price * (1- discount)) as total_revenue
from sales.vw_order_line_details
group by store_name , year(order_date)

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q10. For each brand, show the number of products and the minimum,
--average and maximum list price. Keep only brands with more than 10
--products, sorted by average price from highest to lowest.

SELECT
    b.brand_name,
    COUNT(p.product_id) AS total_products,
    MIN(p.list_price) AS minimum_price,
    AVG(p.list_price) AS average_price,
    MAX(p.list_price) AS maximum_price
FROM production.brands AS b
INNER JOIN production.products AS p
    ON b.brand_id = p.brand_id
GROUP BY
    b.brand_name
HAVING
    COUNT(p.product_id) > 10
ORDER BY
    average_price DESC;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--Q11. Find products whose list price is higher than the average list price
--of their own category. Show product_name, category_name, list_price
--and the category's average price.


SELECT
    p.product_name,
    c.category_name,
    p.list_price,
    (
        SELECT AVG(p2.list_price)
        FROM production.products AS p2
        WHERE p2.category_id = p.category_id
    ) AS category_avg_price

FROM production.products AS p
INNER JOIN production.categories AS c
    ON p.category_id = c.category_id

WHERE p.list_price > (
    SELECT AVG(p2.list_price)
    FROM production.products AS p2
    WHERE p2.category_id = p.category_id
);

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--Q12. Find customers who placed at least one order in 2016 but no orders
--in 2018. Show customer_id, full name, email and state.
--Write the query twice: once with IN / NOT IN and once with
--EXISTS / NOT EXISTS.

---- With IN Operator

SELECT customer_id,
       first_name + ' ' + last_name AS full_name,
       email,
       state
FROM   sales.customers
WHERE  customer_id IN (SELECT customer_id
                       FROM   sales.orders
                       WHERE  year(order_date) = 2016);

---- With Not IN Operator

SELECT customer_id,
       first_name + ' ' + last_name AS full_name,
       email,
       state
FROM   sales.customers
WHERE  customer_id NOT IN (SELECT customer_id
                           FROM   sales.orders
                           WHERE  year(order_date) = 2018);

---- With Exist Operator
SELECT customer_id,
       first_name + ' ' + last_name AS full_name,
       email,
       state
FROM   sales.customers
WHERE  EXISTS (SELECT 1
               FROM   sales.orders
               WHERE  year(order_date) = 2016);


---- With Not Exist Operator
SELECT customer_id,
       first_name + ' ' + last_name AS full_name,
       email,
       state
FROM   sales.customers AS c
WHERE  NOT EXISTS (SELECT 1
                   FROM   sales.orders AS o
                   WHERE  o.customer_id = c.customer_id
                          AND YEAR(o.order_date) = 2018);

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--Q13. Using two CTEs in one WITH clause, first calculate the total revenue 
--for each store, then the average of those store totals. Return only the
--stores whose revenue is above the average, with store_name, total_revenue,
--average and the difference.


WITH store_revenue AS
(
    SELECT
        s.store_id,
        s.store_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
    FROM sales.stores AS s
    INNER JOIN sales.orders AS o
        ON s.store_id = o.store_id
    INNER JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    GROUP BY
        s.store_id,
        s.store_name
),
average_revenue AS
(
    SELECT
        AVG(total_revenue) AS avg_revenue
    FROM store_revenue
)

SELECT
    sr.store_name,
    sr.total_revenue,
    ar.avg_revenue,
    sr.total_revenue - ar.avg_revenue AS difference

FROM store_revenue AS sr
CROSS JOIN average_revenue AS ar

WHERE sr.total_revenue > ar.avg_revenue;

