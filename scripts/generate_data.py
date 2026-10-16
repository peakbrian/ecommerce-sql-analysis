import sqlite3
import random
from pathlib import Path
from datetime import date, timedelta 

PROJECT_ROOT = Path(__file__).resolve().parents[1]

SETUP_FILE = PROJECT_ROOT / "setup.sql"
DATABASE_FILE = PROJECT_ROOT / "data" / "ecommerce.db"

NUM_CUSTOMERS = 400
RANDOM_SEED = 42

random.seed(RANDOM_SEED)

if DATABASE_FILE.exists():
    DATABASE_FILE.unlink()

with open(SETUP_FILE, "r", encoding="utf-8") as file:
    setup_sql = file.read()
    

connection = sqlite3.connect(DATABASE_FILE)

connection.execute("PRAGMA foreign_keys = ON;")

connection.executescript(setup_sql)

connection.execute("DELETE FROM order_items;")
connection.execute("DELETE FROM orders;")
connection.execute("DELETE FROM customers;")

CITIES = [
    "Seattle",
    "Spokane",
    "Tacoma",
    "Bellevue",
    "Vancouver",
    "Shoreline",
    "Olympia",
    "Bothell",
    "Kirkland",
    "Lynnwood",
    "Renton",
    "Federal Way"
]

FIRST_NAMES = [
    "Alice",
    "Bob",
    "Carol",
    "David",
    "Eugene",
    "Frank",
    "Gary",
    "Henry",
    "Ivy",
    "Julia",
    "Kristin",
    "Louis",
    "Mary",
    "Nigel",
    "Oscar",
    "Peter",
    "Quincy",
    "Ruth",
    "Sophie",
    "Tyler"
]

LAST_NAMES = [
    "Smith",
    "Johnson",
    "Williams",
    "Brown",
    "Jones",
    "Garcia",
    "Miller",
    "Davis",
    "Martinez",
    "Wong",
    "Lopez",
    "Wan",
    "Wilson",
    "Anderson",
    "Thomas",
    "Lee",
    "Harris",
    "Perez",
    "Clark",
    "Young"
]

name_combinations = [
    f"{first} {last}"
    for first in FIRST_NAMES
    for last in LAST_NAMES
]

if NUM_CUSTOMERS > len(name_combinations):
    raise ValueError("NUM_CUSTOMERS exceeds the number of unique name combinations.")

random.shuffle(name_combinations)

customers = []

start_date = date(2024, 1, 1)
end_date = date(2026, 1, 1)

date_range_days = (end_date - start_date).days

for customer_id in range(1, NUM_CUSTOMERS + 1):
    name = name_combinations.pop()
    city = random.choice(CITIES)
    
    random_days = random.randint(0, date_range_days)
    signup_date = (start_date + timedelta(days=random_days)).isoformat()
    
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

connection.commit()

result = connection.execute(
    "SELECT COUNT(*) FROM customers;"
).fetchone()

print(f"Customers inserted: {result[0]}")

customer_stats = connection.execute(
    """
    SELECT
        COUNT(*) AS customer_count,
        COUNT(DISTINCT name) AS unique_names,
        MIN(signup_date) AS earliest_signup,
        MAX(signup_date) AS latest_signup
    FROM customers;
    """
).fetchone()

print(f"Customer count: {customer_stats[0]}")
print(f"Unique names: {customer_stats[1]}")
print(f"Earliest signup: {customer_stats[2]}")
print(f"Latest signup: {customer_stats[3]}")

connection.close()

print(f"Created database: {DATABASE_FILE}")