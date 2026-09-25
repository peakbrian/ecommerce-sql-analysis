-- ============================================
-- E-Commerce SQL Analysis
-- ============================================


-- ============================================
-- Stage 1: Data Exploration
-- ============================================

-- Question 1
-- How many customers are in the database?
SELECT COUNT(*)
FROM customers;

-- Question 2
-- How many orders are in the database?
SELECT COUNT(*)
FROM orders;

-- Question 3
-- How many products are in the database?
SELECT COUNT(*)
FROM products;

-- Question 4
-- How many product categories are in the database?
SELECT COUNT(*)
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
INNER JOIN orders
    ON order_items.order_id = orders.order_id
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
LEFT OUTER JOIN orders
    ON customers.customer_id = orders.customer_id
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
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
)

SELECT
    customers.customer_id,
    customers.name,
    COALESCE(SUM(order_totals.order_total), 0) AS total_spent
FROM customers
LEFT OUTER JOIN order_totals
    ON customers.customer_id = order_totals.customer_id
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
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
)

SELECT
    customers.customer_id,
    customers.name,
    COALESCE(SUM(viable_order_totals.order_total), 0)
        AS total_spent
FROM customers
LEFT OUTER JOIN viable_order_totals
    ON customers.customer_id = viable_order_totals.customer_id
GROUP BY
    customers.customer_id,
    customers.name
HAVING total_spent > 500
ORDER BY total_spent DESC;

-- Question 12
-- What is the average amount spent per customer on non-cancelled orders?
-- Customers who have never placed an order should be included in the average.
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
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    GROUP BY
        orders.customer_id,
        orders.order_id,
        orders.order_date,
        orders.status
)

SELECT
    order_totals.order_id,
    customers.name,
    order_totals.order_date,
    order_totals.status,
    order_totals.order_total
FROM customers
INNER JOIN order_totals
    ON customers.customer_id = order_totals.customer_id;

-- Question 14
-- What is the average order value for non-cancelled orders?
-- Order value = SUM(quantity * unit_price) for each order.
WITH viable_order_totals AS (
    SELECT
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_value
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
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
    LEFT OUTER JOIN orders
        ON customers.customer_id = orders.customer_id
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
LEFT OUTER JOIN orders
    ON customers.customer_id = orders.customer_id
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
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
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
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
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
    MIN(orders.order_date) AS first_order_date
FROM customers
LEFT OUTER JOIN orders
    ON customers.customer_id = orders.customer_id
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
LEFT OUTER JOIN orders
    ON customers.customer_id = orders.customer_id
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
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
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
LEFT OUTER JOIN orders
    ON customers.customer_id = orders.customer_id
GROUP BY
    customers.customer_id,
    customers.name;


-- ============================================
-- Stage 4: Product & Category Analysis
-- ============================================

-- Question 25
-- How many products are in each product category?
-- Return:
-- category_name
-- product_count
--
-- Include categories that currently have no products.
SELECT
    categories.category_name,
    COUNT(products.product_id) AS product_count
FROM categories
LEFT OUTER JOIN products
    ON categories.category_id = products.category_id
GROUP BY
    categories.category_id,
    categories.category_name;

-- Question 26
-- How many units of each product have been sold
-- in non-cancelled orders?
-- Return:
-- product_id
-- product_name
-- units_sold
--
-- Include products with no sales.
WITH non_cancelled_sales AS (
    SELECT
        order_items.product_id,
        order_items.quantity
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    WHERE orders.status <> 'Cancelled'
)

SELECT
    products.product_id,
    products.product_name,
    COALESCE(SUM(non_cancelled_sales.quantity), 0) AS units_sold
FROM products
LEFT JOIN non_cancelled_sales
    ON products.product_id = non_cancelled_sales.product_id
GROUP BY
    products.product_id,
    products.product_name;

-- Question 27
-- What is the total revenue generated by each product
-- from non-cancelled orders?
-- Return:
-- product_id
-- product_name
-- total_revenue
--
-- Include products with no sales.
-- Products with no sales should show 0 revenue.
WITH non_cancelled_sales AS (
    SELECT
        order_items.product_id,
        order_items.quantity,
        order_items.quantity * order_items.unit_price AS line_revenue
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    WHERE orders.status <> 'Cancelled'
)

SELECT
    products.product_id,
    products.product_name,
    COALESCE(SUM(non_cancelled_sales.line_revenue), 0) AS total_revenue
FROM products
LEFT OUTER JOIN non_cancelled_sales
    ON products.product_id = non_cancelled_sales.product_id
GROUP BY
    products.product_id,
    products.product_name;


-- Question 28
-- Which products generated the most revenue?
-- Return:
-- product_id
-- product_name
-- total_revenue
--
-- Show the top 5 products, ordered from highest revenue
-- to lowest revenue.
--
-- Only include revenue from non-cancelled orders.
WITH non_cancelled_sales AS (
    SELECT
        order_items.product_id,
        order_items.quantity,
        order_items.quantity * order_items.unit_price AS line_revenue
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    WHERE orders.status <> 'Cancelled'
)

SELECT
    products.product_id,
    products.product_name,
    COALESCE(SUM(non_cancelled_sales.line_revenue), 0) AS total_revenue
FROM products
LEFT OUTER JOIN non_cancelled_sales
    ON products.product_id = non_cancelled_sales.product_id
GROUP BY
    products.product_id,
    products.product_name
ORDER BY total_revenue DESC
LIMIT 5;


-- Question 29
-- Which product category generated the most revenue
-- from non-cancelled orders?
-- Return:
-- category_name
-- total_revenue
--
-- Return only the single highest-revenue category.
WITH non_cancelled_sales AS (
    SELECT
        order_items.product_id,
        order_items.quantity,
        order_items.quantity * order_items.unit_price AS line_revenue
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    WHERE orders.status <> 'Cancelled'
),

product_revenues AS (
    SELECT
        products.product_id,
        products.category_id,
        COALESCE(SUM(non_cancelled_sales.line_revenue), 0) AS revenue
    FROM products
    LEFT OUTER JOIN non_cancelled_sales
        ON products.product_id = non_cancelled_sales.product_id
    GROUP BY
        products.product_id,
        products.category_id
)

SELECT
    categories.category_name,
    SUM(product_revenues.revenue) AS total_revenue
FROM categories
INNER JOIN product_revenues
    ON categories.category_id = product_revenues.category_id
GROUP BY
    categories.category_id,
    categories.category_name
ORDER BY total_revenue DESC
LIMIT 1;

-- Question 30
-- For each product category, calculate:
-- category_name
-- total_revenue
-- units_sold
-- product_count
--
-- Only include revenue and units from non-cancelled orders.
WITH non_cancelled_sales AS (
    SELECT
        order_items.product_id,
        order_items.quantity,
        order_items.quantity * order_items.unit_price AS line_revenue
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    WHERE orders.status <> 'Cancelled'
),

product_summary AS (
    SELECT
        products.product_id,
        products.category_id,
        COALESCE(SUM(non_cancelled_sales.line_revenue), 0) AS product_revenue,
        COALESCE(SUM(non_cancelled_sales.quantity), 0) AS units_sold
    FROM products
    LEFT OUTER JOIN non_cancelled_sales
        ON products.product_id = non_cancelled_sales.product_id
    GROUP BY
        products.product_id,
        products.category_id
)

SELECT
    categories.category_name,
    SUM(product_summary.product_revenue) AS total_revenue,
    SUM(product_summary.units_sold) AS units_sold,
    COUNT(product_summary.product_id) AS product_count
FROM categories
INNER JOIN product_summary
    ON categories.category_id = product_summary.category_id
GROUP BY
    categories.category_id,
    categories.category_name;


-- Question 31
-- What percentage of total non-cancelled revenue
-- came from each product category?
-- Return:
-- category_name
-- category_revenue
-- revenue_percentage
--
-- The revenue percentages across all categories should add up
-- to approximately 100%.
WITH non_cancelled_sales AS (
    SELECT
        order_items.product_id,
        order_items.quantity,
        order_items.quantity * order_items.unit_price AS line_revenue
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    WHERE orders.status <> 'Cancelled'
),

product_revenues AS (
    SELECT
        products.product_id,
        products.category_id,
        COALESCE(SUM(non_cancelled_sales.line_revenue), 0) AS product_revenue
    FROM products
    LEFT OUTER JOIN non_cancelled_sales
        ON products.product_id = non_cancelled_sales.product_id
    GROUP BY
        products.product_id,
        products.category_id
),

category_revenues AS (
    SELECT
        categories.category_id,
        categories.category_name,
        SUM(product_revenues.product_revenue) AS category_revenue
    FROM categories
    INNER JOIN product_revenues
        ON categories.category_id = product_revenues.category_id
    GROUP BY
        categories.category_id,
        categories.category_name
)

SELECT
    category_name,
    category_revenue,
    category_revenue * 100.0
        / SUM(category_revenue) OVER () AS revenue_percentage
FROM category_revenues;

-- Question 32
-- For each category, identify its highest-revenue product.
-- Return:
-- category_name
-- product_name
-- product_revenue
--
-- If two or more products tie for the highest revenue
-- within a category, return all tied products.
--
-- Only include revenue from non-cancelled orders.
WITH non_cancelled_sales AS (
    SELECT
        order_items.product_id,
        order_items.quantity,
        order_items.quantity * order_items.unit_price AS line_revenue
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    WHERE orders.status <> 'Cancelled'
),

product_revenues AS (
    SELECT
        products.product_id,
        products.product_name,
        products.category_id,
        COALESCE(SUM(non_cancelled_sales.line_revenue), 0) AS product_revenue
    FROM products
    LEFT OUTER JOIN non_cancelled_sales
        ON products.product_id = non_cancelled_sales.product_id
    GROUP BY
        products.product_id,
        products.category_id
),

products_ranked AS (
    SELECT
        product_id,
        product_name,
        category_id,
        product_revenue,
        DENSE_RANK() OVER (
            PARTITION BY category_id
            ORDER BY product_revenue DESC
        ) AS product_ranking
    FROM product_revenues
)

SELECT
    categories.category_name,
    products_ranked.product_name,
    products_ranked.product_revenue
FROM categories
INNER JOIN products_ranked
    ON categories.category_id = products_ranked.category_id
WHERE products_ranked.product_ranking = 1;


-- ============================================
-- Stage 5: Advanced Customer & Business Analysis
-- ============================================

-- Question 33
-- Rank all customers by their total spending on
-- non-cancelled orders.
--
-- Return:
-- customer_id
-- customer name
-- total_spent
-- spending_rank
--
-- Customers with the same total spending should receive
-- the same rank.
WITH order_totals AS (
    SELECT
        orders.order_id,
        orders.customer_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.order_id,
        orders.customer_id
),

customer_spending AS (
    SELECT
        customers.customer_id,
        customers.name,
        COALESCE(SUM(order_totals.order_total), 0) AS total_spent
    FROM customers
    LEFT OUTER JOIN order_totals
        ON customers.customer_id = order_totals.customer_id
    GROUP BY
        customers.customer_id,
        customers.name
)

SELECT
    customer_id,
    name,
    total_spent,
    DENSE_RANK() OVER (
        ORDER BY total_spent DESC
    ) AS spending_rank
FROM customer_spending;


-- Question 34
-- For each customer, return their:
-- customer_id
-- customer name
-- most_recent_order_date
-- most_recent_order_amount
--
-- Include customers who have never placed an order.
--
-- Only non-cancelled orders should be considered when
-- determining the most recent order.
WITH order_recency_ranked AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        orders.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY orders.customer_id
            ORDER BY orders.order_date DESC, orders.order_id DESC
        ) AS recency_rank,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id,
        orders.order_date
)

SELECT
    customers.customer_id,
    customers.name,
    order_recency_ranked.order_date AS most_recent_order_date,
    order_recency_ranked.order_total AS most_recent_order_amount
FROM customers
LEFT OUTER JOIN order_recency_ranked
    ON
        customers.customer_id = order_recency_ranked.customer_id
        AND order_recency_ranked.recency_rank = 1;

-- Question 35
-- For each customer who has placed at least two orders,
-- show their:
-- customer_id
-- customer name
-- order_id
-- order_date
-- order_total
-- previous_order_total
--
-- previous_order_total should represent the amount of the
-- customer's immediately previous order.
--
-- Only non-cancelled orders should be considered.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        orders.order_date,
        SUM(order_items.quantity * order_items.unit_price) AS order_total,
        COUNT(*) OVER (
            PARTITION BY orders.customer_id
        ) AS customer_order_count
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id,
        orders.order_date
)

SELECT
    customers.customer_id,
    customers.name,
    order_totals.order_id,
    order_totals.order_date,
    order_totals.order_total,
    LAG(order_totals.order_total) OVER (
        PARTITION BY order_totals.customer_id
        ORDER BY order_totals.order_id
    ) AS previous_order_total
FROM customers
INNER JOIN order_totals
    ON customers.customer_id = order_totals.customer_id
WHERE order_totals.customer_order_count > 1;


-- Question 36
-- For each customer who has placed at least two non-cancelled orders,
-- calculate the difference between each order and the customer's
-- previous order.
--
-- Return:
-- customer_id
-- customer name
-- order_id
-- order_date
-- order_total
-- previous_order_total
-- order_difference
--
-- A positive order_difference means the current order was larger
-- than the previous order.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        orders.order_date,
        SUM(order_items.quantity * order_items.unit_price) AS order_total,
        COUNT(*) OVER (
            PARTITION BY orders.customer_id
        ) AS customer_order_count
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id,
        orders.order_date
),

order_history AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        order_total,
        customer_order_count,
        LAG(order_total) OVER (
            PARTITION BY customer_id
            ORDER BY order_id
        ) AS previous_order_total
    FROM order_totals
)

SELECT
    order_history.customer_id,
    customers.name,
    order_history.order_id,
    order_history.order_date,
    order_history.order_total,
    order_history.previous_order_total,
    order_history.order_total - order_history.previous_order_total
        AS order_difference
FROM order_history
INNER JOIN customers
    ON order_history.customer_id = customers.customer_id
WHERE order_history.customer_order_count >= 2;


-- Question 37
-- What percentage of non-cancelled revenue was generated by
-- customers who placed more than one non-cancelled order?
--
-- Return:
-- repeat_customer_revenue
-- total_revenue
-- repeat_customer_revenue_percentage
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total,
        COUNT(*) OVER (
            PARTITION BY orders.customer_id
        ) AS order_count
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
),

revenue_amounts AS (
    SELECT
        SUM(CASE
            WHEN order_count > 1
                THEN order_total
            ELSE 0
        END) AS repeat_customer_revenue,
        SUM(order_total) AS total_revenue
    FROM order_totals
)

SELECT
    repeat_customer_revenue,
    total_revenue,
    repeat_customer_revenue * 100.0
        / total_revenue AS repeat_customer_revenue_percentage
FROM revenue_amounts;


-- Question 38
-- For each customer, calculate their percentage of total
-- non-cancelled revenue.
--
-- Return:
-- customer_id
-- customer name
-- total_spent
-- revenue_percentage
--
-- Order from highest-spending customer to lowest-spending customer.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
),

customer_totals AS (
    SELECT
        order_totals.customer_id,
        customers.name,
        SUM(order_totals.order_total) AS total_spent
    FROM order_totals
    INNER JOIN customers
        ON order_totals.customer_id = customers.customer_id
    GROUP BY
        order_totals.customer_id,
        customers.name
)

SELECT
    customer_id,
    name,
    total_spent,
    total_spent * 100.0 / SUM(total_spent) OVER () AS revenue_percentage
FROM customer_totals
ORDER BY total_spent DESC;


-- Question 39
-- Identify customers whose most recent non-cancelled order
-- was larger than their previous non-cancelled order.
--
-- Return:
-- customer_id
-- customer name
-- previous_order_amount
-- most_recent_order_amount
-- increase_amount
--
-- Only include customers with at least two non-cancelled orders.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        orders.order_date,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id,
        orders.order_date
),

order_summary AS (
    SELECT
        order_totals.customer_id,
        customers.name,
        order_totals.order_id,
        order_totals.order_total,
        ROW_NUMBER() OVER (
            PARTITION BY order_totals.customer_id
            ORDER BY order_totals.order_date DESC, order_totals.order_id DESC
        ) AS recency_rank,
        LAG(order_totals.order_total) OVER (
            PARTITION BY order_totals.customer_id
            ORDER BY order_totals.order_date ASC, order_totals.order_id ASC
        ) AS previous_order_amount
    FROM order_totals
    INNER JOIN customers
        ON order_totals.customer_id = customers.customer_id
)

SELECT
    customer_id,
    name,
    previous_order_amount,
    order_total AS most_recent_order_amount,
    order_total - previous_order_amount AS increase_amount
FROM order_summary
WHERE recency_rank = 1 AND order_total - previous_order_amount > 0;


-- Question 40
-- Identify the top 3 customers by total non-cancelled spending.
--
-- Return:
-- customer_id
-- customer name
-- total_spent
-- spending_rank
--
-- If multiple customers tie for third place, include all
-- customers tied for that rank.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
),

customer_total_spending AS (
    SELECT
        order_totals.customer_id,
        customers.name,
        SUM(order_totals.order_total) AS total_spent
    FROM order_totals
    INNER JOIN customers
        ON order_totals.customer_id = customers.customer_id
    GROUP BY
        order_totals.customer_id,
        customers.name
),

customers_ranked AS (
    SELECT
        customer_id,
        name,
        total_spent,
        DENSE_RANK() OVER (
            ORDER BY total_spent DESC
        ) AS spending_rank
    FROM customer_total_spending
)

SELECT
    customer_id,
    name,
    total_spent,
    spending_rank
FROM customers_ranked
WHERE spending_rank <= 3;

-- ============================================
-- Stage 6: Independent Business Analysis
-- ============================================

-- Question 41
-- Management wants to understand customer purchasing behavior.
--
-- Divide customers into two groups:
--   1. One-time customers: exactly one non-cancelled order
--   2. Repeat customers: more than one non-cancelled order
--
-- For each group, calculate:
-- customer_type
-- customer_count
-- total_revenue
-- average_revenue_per_customer
--
-- Exclude customers who have never placed a non-cancelled order.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total,
        COUNT(*) OVER (
            PARTITION BY orders.customer_id
        ) AS order_count
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
),

customer_summary AS (
    SELECT
        customer_id,
        CASE
            WHEN order_count > 1
                THEN 'Repeat'
            ELSE 'One-Time'
        END AS customer_type,
        SUM(order_total) AS customer_revenue
    FROM order_totals
    GROUP BY
        customer_id,
        customer_type
)

SELECT
    customer_type,
    COUNT(*) AS customer_count,
    SUM(customer_revenue) AS total_revenue,
    AVG(customer_revenue) AS average_revenue_per_customer
FROM customer_summary
GROUP BY customer_type;


-- Question 42
-- Management wants to know which product categories are
-- especially dependent on repeat customers.
--
-- For each category, calculate:
-- category_name
-- total_revenue
-- repeat_customer_revenue
-- repeat_customer_revenue_percentage
--
-- A repeat customer is a customer with more than one
-- non-cancelled order.

WITH product_sales AS (
    SELECT
        order_items.product_id,
        categories.category_id,
        categories.category_name,
        order_items.order_id,
        orders.customer_id,
        order_items.quantity * order_items.unit_price AS product_total
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    INNER JOIN products
        ON order_items.product_id = products.product_id
    INNER JOIN categories
        ON products.category_id = categories.category_id
    WHERE orders.status <> 'Cancelled'
),

customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM orders
    WHERE status <> 'Cancelled'
    GROUP BY customer_id
),

category_summary AS (
    SELECT
        product_sales.category_id,
        product_sales.category_name,
        SUM(product_sales.product_total) AS total_revenue,
        SUM(CASE
            WHEN customer_order_counts.order_count > 1
                THEN product_sales.product_total
            ELSE 0
        END) AS repeat_customer_revenue
    FROM product_sales
    INNER JOIN customer_order_counts
        ON product_sales.customer_id = customer_order_counts.customer_id
    GROUP BY
        product_sales.category_id,
        product_sales.category_name
)

SELECT
    category_name,
    total_revenue,
    repeat_customer_revenue,
    repeat_customer_revenue * 100.0
        / total_revenue AS repeat_customer_revenue_percentage
FROM category_summary;


-- Question 43
-- Identify customers whose total non-cancelled spending
-- is above the average spending of customers who have
-- at least one non-cancelled order.
--
-- Return:
-- customer_id
-- customer name
-- total_spent
--
-- Order from highest spender to lowest spender.
WITH order_totals AS (
    SELECT
        orders.customer_id,
        orders.order_id,
        SUM(order_items.quantity * order_items.unit_price) AS order_total
    FROM orders
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        orders.customer_id,
        orders.order_id
),

customer_summary AS (
    SELECT
        customers.customer_id,
        customers.name,
        SUM(order_totals.order_total) AS total_spent
    FROM customers
    INNER JOIN order_totals
        ON customers.customer_id = order_totals.customer_id
    GROUP BY
        customers.customer_id,
        customers.name
)

SELECT
    cs.customer_id,
    cs.name,
    cs.total_spent
FROM customer_summary AS cs
WHERE
    cs.total_spent > (
        SELECT AVG(avg_cs.total_spent)
        FROM customer_summary AS avg_cs
    )
ORDER BY cs.total_spent DESC;


-- Question 44
-- Management wants to identify products that have generated
-- revenue despite being purchased by relatively few customers.
--
-- For each product, calculate:
-- product_id
-- product_name
-- unique_customer_count
-- total_revenue
--
-- Only include non-cancelled orders.
--
-- Return products purchased by 2 or fewer distinct customers,
-- ordered by total_revenue from highest to lowest.
WITH customer_product_sales AS (
    SELECT
        order_items.product_id,
        products.product_name,
        orders.customer_id,
        SUM(order_items.quantity * order_items.unit_price)
            AS customer_product_revenue
    FROM order_items
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    INNER JOIN products
        ON order_items.product_id = products.product_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        order_items.product_id,
        products.product_name,
        orders.customer_id
)

SELECT
    product_id,
    product_name,
    COUNT(DISTINCT customer_id) AS unique_customer_count,
    SUM(customer_product_revenue) AS total_revenue
FROM customer_product_sales
GROUP BY
    product_id,
    product_name
HAVING unique_customer_count <= 2
ORDER BY total_revenue DESC;


-- Question 45
-- Identify the month in which each category generated its
-- highest revenue.
--
-- Return:
-- category_name
-- year_month
-- monthly_revenue
--
-- If a category has multiple months tied for its highest
-- revenue, return all tied months.
--
-- Only include non-cancelled orders.
WITH monthly_product_revenues AS (
    SELECT
        order_items.product_id,
        products.category_id,
        STRFTIME('%Y-%m', orders.order_date) AS year_month,
        SUM(order_items.quantity * order_items.unit_price)
            AS monthly_product_revenue
    FROM products
    INNER JOIN order_items
        ON products.product_id = order_items.product_id
    INNER JOIN orders
        ON order_items.order_id = orders.order_id
    WHERE orders.status <> 'Cancelled'
    GROUP BY
        order_items.product_id,
        products.category_id,
        STRFTIME('%Y-%m', orders.order_date)
),

monthly_category_revenues_ranked AS (
    SELECT
        monthly_product_revenues.category_id,
        categories.category_name,
        monthly_product_revenues.year_month,
        SUM(monthly_product_revenues.monthly_product_revenue)
            AS monthly_revenue,
        DENSE_RANK() OVER (
            PARTITION BY monthly_product_revenues.category_id
            ORDER BY SUM(monthly_product_revenues.monthly_product_revenue) DESC
        ) AS month_ranking
    FROM monthly_product_revenues
    INNER JOIN categories
        ON monthly_product_revenues.category_id = categories.category_id
    GROUP BY
        monthly_product_revenues.category_id,
        categories.category_name,
        monthly_product_revenues.year_month
)

SELECT
    category_name,
    year_month,
    monthly_revenue
FROM monthly_category_revenues_ranked
WHERE month_ranking = 1;

-- Question 46
-- Final open-ended analysis:
--
-- Management wants to identify their most valuable customers.
--
-- Define "valuable" using at least TWO measurable characteristics
-- from the database.
--
-- Return a customer-level result that supports your definition.
--
-- Your analysis should:
-- 1. Clearly define what makes a customer "valuable".
-- 2. Use SQL to calculate the relevant metrics.
-- 3. Explain why those metrics support your definition.


-- Customer value definition:
-- A valuable customer is defined using two measurable characteristics:
-- 1. Total spending from non-cancelled orders.
-- 2. Number of non-cancelled orders placed.
--
-- Customers who spend more and place more orders receive stronger
-- rankings in the composite value score.
-- 2. 
WITH order_totals AS (
    SELECT
        orders.order_id,
        customers.customer_id,
        customers.name,
        COALESCE(SUM(order_items.quantity * order_items.unit_price), 0)
            AS order_total,
        COUNT(orders.order_id) OVER (
            PARTITION BY customers.customer_id
        ) AS customer_order_count
    FROM customers
    LEFT OUTER JOIN orders
        ON
            customers.customer_id = orders.customer_id
            AND orders.status <> 'Cancelled'
    LEFT OUTER JOIN order_items
        ON orders.order_id = order_items.order_id
    GROUP BY
        orders.order_id,
        customers.customer_id
),

customer_spending AS (
    SELECT
        order_totals.customer_id,
        order_totals.name,
        order_totals.customer_order_count,
        SUM(order_totals.order_total) AS total_spending
    FROM order_totals
    GROUP BY
        order_totals.customer_id,
        order_totals.name,
        order_totals.customer_order_count
),

customer_ranking AS (
    SELECT
        customer_id,
        name,
        total_spending,
        customer_order_count,
        DENSE_RANK() OVER (
            ORDER BY total_spending DESC
        ) AS spending_rank,
        DENSE_RANK() OVER (
            ORDER BY customer_order_count DESC
        ) AS order_rank
    FROM customer_spending
)

SELECT
    customer_id,
    name,
    total_spending,
    spending_rank,
    customer_order_count,
    order_rank,
    spending_rank + (0.5 * order_rank) AS value_score
FROM customer_ranking
ORDER BY value_score;

-- Interpretation:
-- The composite score combines spending rank and order-frequency rank.
-- Lower scores indicate stronger performance across both measures.
-- Total spending receives greater weight than order frequency.
-- This score is an analytical measure of customer value, not 
-- an objective definition.
