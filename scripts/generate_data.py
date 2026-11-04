import sqlite3
import random

from pathlib import Path
from datetime import date, timedelta

# Project Config

PROJECT_ROOT = Path(__file__).resolve().parents[1]

SETUP_FILE = PROJECT_ROOT / "setup.sql"
DATABASE_FILE = PROJECT_ROOT / "data" / "ecommerce.db"

NUM_CUSTOMERS = 400
NUM_ORDERS = 1500

RANDOM_SEED = 42

# The generated order dates will not go beyond this date.
END_DATE = date(2026, 9, 1)

random.seed(RANDOM_SEED)


# Database Setup

# Ensure the database folder exists.
DATABASE_FILE.parent.mkdir(parents=True, exist_ok=True)

if DATABASE_FILE.exists():
    DATABASE_FILE.unlink()

with open(SETUP_FILE, "r", encoding="utf-8") as file:
    setup_sql = file.read()

connection = sqlite3.connect(DATABASE_FILE)

try:
    # Enable foreign-key enforcement for this connection.
    connection.execute("PRAGMA foreign_keys = ON;")

    # Create tables and insert the initial reference data.
    connection.executescript(setup_sql)

    # Remove the sample transactional data.
    # Keep categories and products because we need them later.
    connection.execute("DELETE FROM order_items;")
    connection.execute("DELETE FROM orders;")
    connection.execute("DELETE FROM customers;")


    # Customer generation

    CITIES = [
        "Seattle", "Spokane", "Tacoma", "Bellevue", "Vancouver",
        "Shoreline", "Olympia", "Bothell", "Kirkland", "Lynnwood",
        "Renton", "Federal Way"
    ]

    FIRST_NAMES = [
        "Alice", "Bob", "Carol", "David", "Eugene", "Frank", "Gary",
        "Henry", "Ivy", "Julia", "Kristin", "Louis", "Mary", "Nigel",
        "Oscar", "Peter", "Quincy", "Ruth", "Sophie", "Tyler"
    ]

    LAST_NAMES = [
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia",
        "Miller", "Davis", "Martinez", "Wong", "Lopez", "Wan",
        "Wilson", "Anderson", "Thomas", "Lee", "Harris", "Perez",
        "Clark", "Young"
    ]

    # Create every possible first-name / last-name combination.
    name_combinations = [
        f"{first} {last}"
        for first in FIRST_NAMES
        for last in LAST_NAMES
    ]

    if NUM_CUSTOMERS > len(name_combinations):
        raise ValueError(
            "NUM_CUSTOMERS exceeds the number of unique name combinations"
        )

    random.shuffle(name_combinations)

    customers = []

    start_date = date(2024, 1, 1)
    end_date = date(2026, 9, 1)

    date_range_days = (end_date - start_date).days

    for customer_id in range(1, NUM_CUSTOMERS + 1):
        name = name_combinations.pop()
        city = random.choice(CITIES)

        random_days = random.randint(0, date_range_days)
        signup_date = (
            start_date + timedelta(days=random_days)
        ).isoformat()

        customer = (
            customer_id,
            name,
            city,
            signup_date
        )

        customers.append(customer)

    connection.executemany(
        """
        INSERT INTO customers
            (customer_id, name, city, signup_date)
        VALUES (?, ?, ?, ?)
        """,
        customers
    )

    print(f"Customers generated: {len(customers):,}")


    # Retrieve customer IDs and signup dates.
    customer_records = connection.execute(
        """
        SELECT
            customer_id,
            signup_date
        FROM customers;
        """
    ).fetchall()

    # Retrieve product IDs and their current catalog prices.
    product_records = connection.execute(
        """
        SELECT
            product_id,
            unit_price
        FROM products;
        """
    ).fetchall()

    if not customer_records:
        raise ValueError("No customers available for order generation.")

    if not product_records:
        raise ValueError("No products available for order generation.")


    # Order generation

    orders = []
    order_items = []

    for _ in range(NUM_ORDERS):

        # Choose an existing customer.
        customer_id, signup_date_text = random.choice(customer_records)

        # Convert the signup date string into a date
        signup_date = date.fromisoformat(signup_date_text)

        # An order cannot occur before the customer's signup date.
        if signup_date > END_DATE:
            raise ValueError(
                f"Customer {customer_id} signed up after END_DATE."
            )

        # Generate an order date between signup and END_DATE.
        days_available = (END_DATE - signup_date).days

        random_days = random.randint(0, days_available)

        order_date = (
            signup_date + timedelta(days=random_days)
        ).isoformat()

        # Assign a status using weighted probabilities.
        status = random.choices(
            population=["Completed", "Shipped", "Cancelled"],
            weights=[70, 20, 10],
            k=1
        )[0]

        # Insert the order and retrieve its automatically generated ID.
        cursor = connection.execute(
            """
            INSERT INTO orders
                (customer_id, order_date, status)
            VALUES (?, ?, ?)
            """,
            (customer_id, order_date, status)
        )

        order_id = cursor.lastrowid

        orders.append(
            (order_id, customer_id, order_date, status)
        )


        # Order item generation

        # Each order contains between 1 and 5 distinct products.
        number_of_items = random.randint(
            1,
            min(5, len(product_records))
        )

        # random.sample selects products without replacement.
        selected_products = random.sample(
            product_records,
            number_of_items
        )

        for product_id, unit_price in selected_products:

            quantity = random.randint(1, 4)

            order_item = (
                order_id,
                product_id,
                quantity,
                unit_price
            )

            order_items.append(order_item)


    # Insert all generated order items.
    connection.executemany(
        """
        INSERT INTO order_items
            (order_id, product_id, quantity, unit_price)
        VALUES (?, ?, ?, ?)
        """,
        order_items
    )

    # Save all generated records.
    connection.commit()

    print(f"Orders generated: {len(orders):,}")
    print(f"Order items generated: {len(order_items):,}")


    # Data validation after generation

    # Count customers, unique names, orders, and order items.
    customer_count = connection.execute(
        "SELECT COUNT(*) FROM customers;"
    ).fetchone()[0]

    unique_names = connection.execute(
        "SELECT COUNT(DISTINCT name) FROM customers;"
    ).fetchone()[0]

    order_count = connection.execute(
        "SELECT COUNT(*) FROM orders;"
    ).fetchone()[0]

    order_item_count = connection.execute(
        "SELECT COUNT(*) FROM order_items;"
    ).fetchone()[0]


    # Retrieve the earliest and latest order dates.
    order_date_range = connection.execute(
        """
        SELECT
            MIN(order_date),
            MAX(order_date)
        FROM orders;
        """
    ).fetchone()


    # Check for orders occurring before customer signup.
    orders_before_signup = connection.execute(
        """
        SELECT COUNT(*)
        FROM orders AS o
        JOIN customers AS c
            ON o.customer_id = c.customer_id
        WHERE o.order_date < c.signup_date;
        """
    ).fetchone()[0]


    # Check for orders that do not contain any order items.
    orders_without_items = connection.execute(
        """
        SELECT COUNT(*)
        FROM orders AS o
        LEFT JOIN order_items AS oi
            ON o.order_id = oi.order_id
        WHERE oi.order_id IS NULL;
        """
    ).fetchone()[0]


    # Check for foreign-key violations.
    foreign_key_violations = connection.execute(
        "PRAGMA foreign_key_check;"
    ).fetchall()


    # Retrieve order counts by status.
    status_counts = connection.execute(
        """
        SELECT
            status,
            COUNT(*) AS order_count
        FROM orders
        GROUP BY status
        ORDER BY status;
        """
    ).fetchall()

    # Print validation report

    print("\n" + "=" * 45)
    print("DATA GENERATION VALIDATION")
    print("=" * 45)

    print(f"Customers: {customer_count:,}")
    print(f"Unique customer names: {unique_names:,}")
    print(f"Orders: {order_count:,}")
    print(f"Order items: {order_item_count:,}")

    print(f"Earliest order date: {order_date_range[0]}")
    print(f"Latest order date: {order_date_range[1]}")

    print(f"Orders before signup: {orders_before_signup}")
    print(f"Orders without items: {orders_without_items}")
    print(f"Foreign-key violations: {len(foreign_key_violations)}")

    print("\nOrders by status:")

    for status, count in status_counts:
        print(f"  {status}: {count:,}")

    if customer_count != NUM_CUSTOMERS:
        raise RuntimeError("Customer count does not match expected count.")

    if unique_names != customer_count:
        raise RuntimeError("Duplicate customer names detected.")

    if order_count != NUM_ORDERS:
        raise RuntimeError("Order count does not match expected count.")

    if orders_before_signup != 0:
        raise RuntimeError("Some orders occur before customer signup.")

    if orders_without_items != 0:
        raise RuntimeError("Some orders have no associated order items.")

    if foreign_key_violations:
        raise RuntimeError("Foreign-key violations detected.")

    if order_item_count < order_count:
        raise RuntimeError("Unexpected order-item count.")

    print("\nAll critical validation checks passed.")


finally:
    connection.close()


print(f"\nCreated database: {DATABASE_FILE}")