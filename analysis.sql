-- ============================================
-- E-Commerce SQL Analysis
-- ============================================


-- ============================================
-- Stage 1: Data Exploration
-- ============================================

-- Question 1
-- How many customers are in the database?
SELECT COUNT(customer_id)
FROM customers;

-- Question 2
-- How many orders are in the database?
SELECT COUNT(order_id)
FROM orders;

-- Question 3
-- How many products are in the database?
SELECT COUNT(product_id)
FROM products;

-- Question 4
-- How many product categories are in the database?
SELECT COUNT(category_id)
FROM categories;

-- Question 5
-- How many customers have never placed an order?
SELECT COUNT(customers.customer_id)
FROM customers
WHERE NOT EXISTS (
    SELECT 1
    FROM orders
    WHERE orders.customer_id = customers.customer_id
);

-- Question 6
-- What are the earliest and latest order dates?
-- Return both dates in one result.
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM orders;

-- Question 7
-- How many orders are there for each order status?
SELECT
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(CASE WHEN status = 'Shipped' THEN 1 ELSE 0 END) AS shipped_orders,
    SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_orders
FROM orders;

SELECT
    status,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY status;

-- Question 8
-- What is the total revenue generated from non-cancelled orders?
-- Revenue = quantity * unit_price
-- Non-cancelled orders have a status other than 'Cancelled'.
SELECT SUM(order_items.quantity * order_items.unit_price) AS total_revenue
FROM order_items
INNER JOIN orders ON order_items.order_id = orders.order_id
WHERE orders.status <> 'Cancelled';


-- ============================================
-- Stage 2: Customer & Order Analysis
-- ============================================

-- Question 9
-- For each customer, show:
-- customer_id
-- customer name
-- number of orders they have placed
-- Include customers who have never placed an order.
SELECT
    customers.customer_id,
    customers.name,
    COUNT(orders.order_id) AS orders_placed
FROM customers
LEFT OUTER JOIN orders ON customers.customer_id = orders.customer_id
GROUP BY
    customers.customer_id,
    customers.name;

-- Question 10
-- For each customer, show:
-- customer_id
-- customer name
-- total amount spent on non-cancelled orders
-- Include customers who have never placed an order.
-- Customers with no qualifying orders should show 0.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
)

SELECT
    customers.customer_id,
    customers.name,
    COALESCE(SUM(order_totals.order_total), 0) AS total_spent_viable_orders
FROM customers
LEFT OUTER JOIN order_totals ON customers.customer_id = order_totals.customer_id
GROUP BY
    customers.customer_id,
    customers.name;


-- Question 11
-- Which customers have spent more than $500 on non-cancelled orders?
-- Return:
-- customer_id
-- customer name
-- total amount spent
-- Order the results from highest spender to lowest spender.
WITH viable_order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
)

SELECT
    customers.customer_id,
    customers.name,
    COALESCE(SUM(viable_order_totals.order_total), 0)
        AS total_spent_viable_orders
FROM customers
LEFT OUTER JOIN
    viable_order_totals
    ON customers.customer_id = viable_order_totals.customer_id
GROUP BY
    customers.customer_id,
    customers.name
HAVING total_spent_viable_orders > 500
ORDER BY total_spent_viable_orders DESC;

-- Question 12
-- What is the average amount spent per customer on non-cancelled orders?
-- Customers who have never placed an order should be included in the average.

-- 1 row per customer
WITH viable_order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
)

SELECT
    customers.customer_id,
    customers.name,
    COALESCE(AVG(viable_order_totals.order_total), 0) AS avg_spent_viable_orders
FROM customers
LEFT OUTER JOIN
    viable_order_totals
    ON customers.customer_id = viable_order_totals.customer_id
GROUP BY
    customers.customer_id,
    customers.name;

-- 1 result for entire question
WITH customer_orders AS (
    SELECT
        customers.customer_id,
        orders.order_id,
        orders.status
    FROM customers
    LEFT OUTER JOIN orders ON customers.customer_id = orders.customer_id
),

customer_viable_order_totals AS (
    SELECT
        SUM(CASE
            WHEN
                customer_orders.status <> 'Cancelled'
                THEN order_items.quantity * order_items.unit_price
            ELSE 0
        END) AS total_spent
    FROM customer_orders
    LEFT OUTER JOIN
        order_items
        ON customer_orders.order_id = order_items.order_id
    GROUP BY customer_orders.customer_id
)

SELECT AVG(total_spent) AS average_amount_spent
FROM customer_viable_order_totals;

-- Revised CTE version for readability
WITH customer_totals AS (
    SELECT
        customers.customer_id,
        SUM(
            CASE
                WHEN orders.status <> 'Cancelled'
                    THEN order_items.quantity * order_items.unit_price
                ELSE 0
            END
        ) AS total_spent
    FROM customers
    LEFT JOIN orders
        ON customers.customer_id = orders.customer_id
    LEFT JOIN order_items
        ON orders.order_id = order_items.order_id
    GROUP BY
        customers.customer_id
)

SELECT AVG(total_spent) AS average_amount_spent
FROM customer_totals;

-- Question 13
-- For each order, show:
-- order_id
-- customer name
-- order date
-- order status
-- order total
--
-- Order total = SUM(quantity * unit_price) for all items in the order.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        orders.order_date,
        orders.status,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items ON orders.order_id = order_items.order_id
    GROUP BY
        orders.customer_id,
        orders.order_id
)

SELECT
    order_totals.order_id,
    customers.name,
    order_totals.order_date,
    order_totals.status,
    order_totals.order_total
FROM customers
INNER JOIN order_totals ON customers.customer_id = order_totals.customer_id;

-- Question 14
-- What is the average order value for non-cancelled orders?
-- Order value = SUM(quantity * unit_price) for each order.
WITH viable_order_totals AS (
    SELECT
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_value
    FROM orders
    INNER JOIN order_items ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY orders.order_id
)

SELECT AVG(viable_order_totals.order_value) AS average_order_value
FROM viable_order_totals;

-- Question 15
-- Which customers have placed more orders than the average customer?
-- Return:
-- customer_id
-- customer name
-- order_count
--
-- Customers with zero orders should be included when calculating
-- the average customer order count.

WITH customer_order_counts AS (
    SELECT
        customers.customer_id,
        customers.name,
        COUNT(orders.order_id) AS order_count
    FROM customers
    LEFT OUTER JOIN orders ON customers.customer_id = orders.customer_id
    GROUP BY
        customers.customer_id,
        customers.name
)

SELECT
    customer_order_counts.customer_id,
    customer_order_counts.name,
    customer_order_counts.order_count
FROM customer_order_counts
WHERE customer_order_counts.order_count > (
    SELECT AVG(t1.order_count)
    FROM customer_order_counts AS t1
);

-- Question 16
-- For each customer, show:
-- customer_id
-- customer name
-- most recent order date
--
-- Include customers who have never placed an order.
SELECT
    customers.customer_id,
    customers.name,
    MAX(orders.order_date) AS most_recent_order_date
FROM customers
LEFT OUTER JOIN orders ON customers.customer_id = orders.customer_id
GROUP BY
    customers.customer_id,
    customers.name;


-- ============================================
-- Stage 3: Time-Based Order Analysis
-- ============================================

-- Question 17
-- How many orders were placed in each month?
-- Return:
-- year_month
-- order_count
--
-- Format year_month as YYYY-MM.
SELECT
    STRFTIME('%Y-%m', order_date) AS year_month,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY year_month;

-- Question 18
-- What is the total revenue generated in each month
-- from non-cancelled orders?
-- Return:
-- year_month
-- total_revenue
--
-- Revenue = quantity * unit_price.
WITH order_totals AS (
    SELECT
        orders.order_id,
        orders.order_date,
        orders.status,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items ON orders.order_id = order_items.order_id
    GROUP BY
        orders.order_id,
        orders.order_date,
        orders.status
)

SELECT
    STRFTIME('%Y-%m', order_date) AS year_month,
    SUM(order_total) AS total_revenue
FROM order_totals
WHERE status <> 'Cancelled'
GROUP BY year_month;


-- Question 19
-- Which month had the highest total revenue from non-cancelled orders?
-- Return:
-- year_month
-- total_revenue
--
-- Return only the single highest-revenue month.
WITH order_totals AS (
    SELECT
        orders.order_id,
        orders.order_date,
        orders.status,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items ON orders.order_id = order_items.order_id
    GROUP BY
        orders.order_id,
        orders.order_date,
        orders.status
)

SELECT
    STRFTIME('%Y-%m', order_date) AS year_month,
    COALESCE(SUM(order_total), 0) AS total_revenue
FROM order_totals
WHERE status <> 'Cancelled'
GROUP BY STRFTIME('%Y-%m', order_date)
ORDER BY total_revenue DESC
LIMIT 1;

-- Question 20
-- For each customer, what was the date of their first order?
-- Return:
-- customer_id
-- customer name
-- first_order_date
--
-- Include customers who have never placed an order.
SELECT
    customers.customer_id,
    customers.name,
    COALESCE(MIN(orders.order_date), 'No orders') AS first_order_date
FROM customers
LEFT OUTER JOIN orders ON customers.customer_id = orders.customer_id
GROUP BY
    customers.customer_id,
    customers.name;

-- Question 21
-- For each customer, what was the date of their most recent order,
-- and how many days had passed between their signup date
-- and their most recent order?
--
-- Return:
-- customer_id
-- customer name
-- signup_date
-- most_recent_order_date
-- days_to_most_recent_order
--
-- Include customers who have never placed an order.
SELECT
    customers.customer_id,
    customers.name,
    customers.signup_date,
    MAX(orders.order_date) AS most_recent_order_date,
    JULIANDAY(MAX(orders.order_date))
    - JULIANDAY(customers.signup_date) AS days_to_most_recent_order
FROM customers
LEFT OUTER JOIN orders ON customers.customer_id = orders.customer_id
GROUP BY
    customers.customer_id,
    customers.name,
    customers.signup_date;


-- Question 22
-- How many new customers signed up in each month?
-- Return:
-- year_month
-- new_customers
--
-- Format year_month as YYYY-MM.
SELECT
    STRFTIME('%Y-%m', signup_date) AS year_month,
    COUNT(customer_id) AS new_customers
FROM customers
GROUP BY year_month;


-- Question 23
-- For each month, calculate:
-- year_month
-- total_revenue
-- total_orders
-- average_order_value
--
-- Include only non-cancelled orders.
WITH order_totals AS (
    SELECT
        orders.order_id,
        orders.order_date,
        orders.status,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items ON orders.order_id = order_items.order_id
    GROUP BY
        orders.order_id,
        orders.order_date,
        orders.status
)

SELECT
    STRFTIME('%Y-%m', order_date) AS year_month,
    SUM(order_total) AS total_revenue,
    COUNT(order_id) AS total_orders,
    AVG(order_total) AS average_order_value
FROM order_totals
WHERE status <> 'Cancelled'
GROUP BY year_month;

-- Question 24
-- For each customer, calculate:
-- customer_id
-- customer name
-- first_order_date
-- most_recent_order_date
-- total_orders
--
-- Include customers who have never placed an order.
SELECT
    customers.customer_id,
    customers.name,
    MIN(orders.order_date) AS first_order_date,
    MAX(orders.order_date) AS most_recent_order_date,
    COUNT(orders.order_id) AS total_orders
FROM customers
LEFT OUTER JOIN orders ON customers.customer_id = orders.customer_id
GROUP BY
    customers.customer_id,
    customers.name;
