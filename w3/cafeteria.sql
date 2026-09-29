-- Task 1

CREATE DATABASE cafeteria_db
WITH
    TEMPLATE = template0
    ENCODING = 'UTF8'
    CONNECTION LIMIT = 20;


-- Task 2

CREATE TABLE menu_items (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(60),
    category CHAR(10),
    price DECIMAL(6,2),
    calories SMALLINT,
    is_vegetarian BOOLEAN DEFAULT FALSE,
    added_at TIMESTAMP
);

-- Task 3

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    item_id INTEGER,
    quantity SMALLINT,
    order_time TIMESTAMP WITH TIME ZONE,
    prep_time INTERVAL
);

-- Task 4

ALTER TABLE menu_items ALTER COLUMN category TYPE VARCHAR(20);

ALTER TABLE menu_items ADD COLUMN discount DECIMAL(10,2) DEFAULT 0.00;

ALTER TABLE orders ALTER COLUMN quantity SET DEFAULT 1;

ALTER TABLE orders DROP COLUMN prep_time;

ALTER TABLE orders ADD COLUMN is_paid BOOLEAN DEFAULT FALSE;


-- Task 5

DROP TABLE IF EXISTS orders CASCADE;