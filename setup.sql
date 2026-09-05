-- E-commerce SQL project setup (SQLite)
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    signup_date TEXT NOT NULL
);

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    status TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO customers (customer_id, name, city, signup_date) VALUES
    (1, 'Alice Johnson', 'Seattle', '2025-01-05'),
    (2, 'Brian Lee', 'Bellevue', '2025-01-09'),
    (3, 'Carla Gomez', 'Tacoma', '2025-01-14'),
    (4, 'Daniel Kim', 'Seattle', '2025-01-20'),
    (5, 'Emily Chen', 'Redmond', '2025-02-01'),
    (6, 'Frank Wilson', 'Seattle', '2025-02-08'),
    (7, 'Grace Patel', 'Kirkland', '2025-02-18'),
    (8, 'Henry Davis', 'Bellevue', '2025-03-02'),
    (9, 'Irene Nguyen', 'Seattle', '2025-03-10'),
    (10, 'Jack Brown', 'Tacoma', '2025-03-22'),
    (11, 'Karen Smith', 'Redmond', '2025-04-01'),
    (12, 'Leo Martinez', 'Seattle', '2025-04-15'),
    (13, 'Maya Thompson', 'Kirkland', '2025-05-03'),
    (14, 'Noah Clark', 'Bellevue', '2025-05-18'),
    (15, 'Olivia Wang', 'Seattle', '2025-06-05');

INSERT INTO categories (category_id, category_name) VALUES
    (1, 'Electronics'),
    (2, 'Home Office'),
    (3, 'Accessories'),
    (4, 'Outdoor');

INSERT INTO products (product_id, product_name, category_id, unit_price) VALUES
    (1, 'Wireless Mouse', 1, 29.99),
    (2, 'Mechanical Keyboard', 1, 89.99),
    (3, 'USB-C Hub', 1, 49.99),
    (4, 'Laptop Stand', 2, 59.99),
    (5, 'Desk Lamp', 2, 39.99),
    (6, 'Notebook Set', 2, 19.99),
    (7, 'Webcam', 1, 79.99),
    (8, 'Headphones', 1, 129.99),
    (9, 'Water Bottle', 4, 24.99),
    (10, 'Backpack', 4, 74.99),
    (11, 'Phone Case', 3, 19.99),
    (12, 'Charging Cable', 3, 14.99);

INSERT INTO orders (order_id, customer_id, order_date, status) VALUES
    (1007, 2, '2025-01-30', 'Completed'),
    (1026, 11, '2025-02-19', 'Completed'),
    (1033, 15, '2025-02-20', 'Shipped'),
    (1022, 10, '2025-02-24', 'Shipped'),
    (1028, 11, '2025-02-24', 'Completed'),
    (1017, 9, '2025-03-05', 'Completed'),
    (1004, 1, '2025-03-08', 'Cancelled'),
    (1001, 1, '2025-03-13', 'Completed'),
    (1021, 10, '2025-03-19', 'Completed'),
    (1015, 7, '2025-04-04', 'Completed'),
    (1034, 15, '2025-04-12', 'Shipped'),
    (1025, 11, '2025-04-23', 'Cancelled'),
    (1010, 4, '2025-04-26', 'Cancelled'),
    (1008, 2, '2025-05-06', 'Completed'),
    (1012, 4, '2025-05-07', 'Completed'),
    (1003, 1, '2025-05-09', 'Completed'),
    (1027, 11, '2025-05-11', 'Completed'),
    (1035, 15, '2025-05-20', 'Completed'),
    (1019, 9, '2025-05-30', 'Completed'),
    (1032, 14, '2025-05-31', 'Cancelled'),
    (1037, 15, '2025-06-02', 'Cancelled'),
    (1002, 1, '2025-06-04', 'Completed'),
    (1029, 13, '2025-06-06', 'Completed'),
    (1023, 10, '2025-06-14', 'Cancelled'),
    (1016, 7, '2025-07-06', 'Completed'),
    (1018, 9, '2025-07-10', 'Shipped'),
    (1030, 13, '2025-07-20', 'Completed'),
    (1031, 13, '2025-07-23', 'Completed'),
    (1006, 2, '2025-08-19', 'Completed'),
    (1014, 6, '2025-08-19', 'Completed'),
    (1020, 10, '2025-09-07', 'Shipped'),
    (1036, 15, '2025-09-08', 'Completed'),
    (1009, 2, '2025-09-30', 'Shipped'),
    (1005, 1, '2025-10-21', 'Completed'),
    (1011, 4, '2025-10-21', 'Completed'),
    (1013, 4, '2025-11-12', 'Completed'),
    (1024, 10, '2025-11-27', 'Completed');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1007, 11, 1, 19.99),
    (1007, 6, 1, 19.99),
    (1026, 6, 2, 19.99),
    (1033, 2, 3, 89.99),
    (1033, 4, 2, 59.99),
    (1033, 10, 1, 74.99),
    (1022, 7, 2, 79.99),
    (1022, 11, 1, 19.99),
    (1022, 8, 1, 129.99),
    (1022, 3, 3, 49.99),
    (1028, 12, 3, 14.99),
    (1028, 10, 2, 74.99),
    (1028, 7, 2, 79.99),
    (1017, 3, 2, 49.99),
    (1017, 9, 1, 24.99),
    (1004, 2, 1, 89.99),
    (1001, 11, 3, 19.99),
    (1001, 7, 1, 79.99),
    (1021, 7, 2, 79.99),
    (1021, 10, 3, 74.99),
    (1021, 8, 1, 129.99),
    (1021, 9, 3, 24.99),
    (1015, 11, 3, 19.99),
    (1034, 11, 2, 19.99),
    (1034, 6, 2, 19.99),
    (1034, 2, 1, 89.99),
    (1025, 1, 3, 29.99),
    (1025, 5, 1, 39.99),
    (1025, 9, 3, 24.99),
    (1025, 3, 2, 49.99),
    (1010, 3, 1, 49.99),
    (1010, 6, 3, 19.99),
    (1008, 10, 2, 74.99),
    (1012, 1, 1, 29.99),
    (1012, 2, 1, 89.99),
    (1012, 6, 1, 19.99),
    (1012, 5, 3, 39.99),
    (1003, 2, 3, 89.99),
    (1027, 2, 3, 89.99),
    (1027, 9, 2, 24.99),
    (1027, 3, 3, 49.99),
    (1027, 10, 1, 74.99),
    (1035, 9, 1, 24.99),
    (1035, 10, 3, 74.99),
    (1035, 7, 3, 79.99),
    (1019, 12, 2, 14.99),
    (1019, 5, 3, 39.99),
    (1032, 8, 1, 129.99),
    (1032, 9, 1, 24.99),
    (1032, 12, 1, 14.99),
    (1037, 6, 1, 19.99),
    (1002, 10, 1, 74.99),
    (1002, 4, 1, 59.99),
    (1029, 4, 1, 59.99),
    (1023, 6, 1, 19.99),
    (1016, 5, 2, 39.99),
    (1016, 11, 1, 19.99),
    (1018, 12, 3, 14.99),
    (1018, 10, 2, 74.99),
    (1030, 8, 1, 129.99),
    (1030, 7, 1, 79.99),
    (1031, 11, 2, 19.99),
    (1006, 7, 3, 79.99),
    (1006, 12, 1, 14.99),
    (1006, 8, 3, 129.99),
    (1014, 1, 2, 29.99),
    (1020, 2, 1, 89.99),
    (1020, 4, 3, 59.99),
    (1020, 11, 2, 19.99),
    (1036, 7, 2, 79.99),
    (1036, 3, 2, 49.99),
    (1009, 2, 3, 89.99),
    (1009, 8, 1, 129.99),
    (1005, 11, 3, 19.99),
    (1011, 2, 1, 89.99),
    (1013, 7, 2, 79.99),
    (1013, 8, 1, 129.99),
    (1024, 1, 2, 29.99),
    (1024, 3, 2, 49.99),
    (1024, 7, 2, 79.99),
    (1024, 12, 2, 14.99);
