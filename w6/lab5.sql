-- Name: Mergaliyev Yersultan
-- Student ID: 25B031386
-- Failed statements are commented out; uncomment one to see its error.

DROP SCHEMA IF EXISTS ecommerce CASCADE;
DROP TABLE IF EXISTS
    order_items, products_fk, categories, orders, books, publishers, authors,
    employees_dept, student_courses, departments, course_enrollments, users,
    inventory, customers, bookings, products_catalog, employees
CASCADE;

-- =========================== PART 1: CHECK ===========================
-- 1.1 CHECK on age (18..65) and salary (> 0)
CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

-- 1.2 Named CHECK: prices positive and discount below regular price
CREATE TABLE products_catalog
(
    product_id INTEGER PRIMARY KEY,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- 1.3 CHECK on guests count and on date order (two columns compared)
CREATE TABLE bookings
(
    booking_id INTEGER PRIMARY KEY,
    check_in_date DATE,
    check_out_date DATE CHECK (check_out_date > check_in_date),
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10)
);

-- 1.4 Tests
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES (1, 'Alice', 'Smith', 30, 50000);
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES (2, 'Bob', 'Jones', 45, 75000);
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES (3, 'Charlie', 'Brown', 17, 40000);
--   FAIL: violates check constraint "employees_age_check" (age 17 < 18)
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES (4, 'Dana', 'White', 30, 0);
--   FAIL: violates check constraint "employees_salary_check" (salary must be > 0)

INSERT INTO products_catalog VALUES (1, 'Laptop', 1000, 800);
INSERT INTO products_catalog VALUES (2, 'Mouse', 50, 40);
-- INSERT INTO products_catalog VALUES (3, 'Phone', 300, 350);
--   FAIL: violates check constraint "valid_discount" (discount_price >= regular_price)
-- INSERT INTO products_catalog VALUES (4, 'Tablet', 0, 10);
--   FAIL: violates check constraint "valid_discount" (regular_price must be > 0)

INSERT INTO bookings VALUES (1, '2025-01-01', '2025-01-05', 2);
INSERT INTO bookings VALUES (2, '2025-02-01', '2025-02-03', 4);
-- INSERT INTO bookings VALUES (3, '2025-03-05', '2025-03-01', 2);
--   FAIL: violates check constraint "bookings_check" (check_out_date must be after check_in_date)
-- INSERT INTO bookings VALUES (4, '2025-04-01', '2025-04-05', 11);
--   FAIL: violates check constraint "bookings_num_guests_check" (max 10 guests)

-- ========================== PART 2: NOT NULL ==========================
-- 2.1 phone is the only nullable column
CREATE TABLE customers
(
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- 2.2 NOT NULL combined with CHECK
CREATE TABLE inventory
(
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- 2.3 Tests
INSERT INTO customers VALUES (1, 'alice@gmail.com', '9843315', '2025-03-12');
INSERT INTO customers VALUES (2, 'bob@gmail.com', '9843316', '2025-03-13');
INSERT INTO customers VALUES (5, 'dana@example.com', NULL, '2025-04-01'); -- OK: phone is nullable
-- INSERT INTO customers VALUES (NULL, 'charlie@example.com', '555-9999', '2025-03-01');
--   FAIL: null value in column "customer_id" violates not-null constraint
-- INSERT INTO customers VALUES (4, NULL, '555-9999', '2025-03-01');
--   FAIL: null value in column "email" violates not-null constraint

INSERT INTO inventory VALUES (1, 'Widget', 100, 9.99, '2025-01-01 10:00:00');
INSERT INTO inventory VALUES (2, 'Gadget', 50, 19.99, '2025-01-02 10:00:00');
-- INSERT INTO inventory VALUES (3, NULL, 50, 5.00, '2025-01-03 12:00:00');
--   FAIL: null value in column "item_name" violates not-null constraint
-- INSERT INTO inventory VALUES (4, 'Gizmo', 50, 5.00, NULL);
--   FAIL: null value in column "last_updated" violates not-null constraint
-- (inventory has no nullable columns, so the nullable test is done on customers.phone)

-- =========================== PART 3: UNIQUE ===========================
-- 3.1
CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP
);

-- 3.2 The COMBINATION of 3 columns must be unique
CREATE TABLE course_enrollments
(
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

-- 3.3 Named UNIQUE constraints on users
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);
INSERT INTO users VALUES (1, 'Walter White', 'walterreal@gmail.com', '2024-12-12');
-- INSERT INTO users VALUES (2, 'Walter White', 'walternotreal@gmail.com', '2025-01-02');
--   FAIL: duplicate key value violates unique constraint "unique_username"
-- INSERT INTO users VALUES (3, 'jesse', 'walterreal@gmail.com', '2025-01-03');
--   FAIL: duplicate key value violates unique constraint "unique_email"

-- ======================== PART 4: PRIMARY KEY =========================
-- 4.1 PRIMARY KEY = UNIQUE + NOT NULL
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);
INSERT INTO departments VALUES
(1, 'Engineering', 'Building A'),
(2, 'Sales', 'Building B'),
(3, 'HR', 'Building C');
-- INSERT INTO departments VALUES (1, 'Marketing', 'Building D');
--   FAIL: duplicate key value violates unique constraint "departments_pkey"
-- INSERT INTO departments VALUES (NULL, 'Finance', 'Building E');
--   FAIL: null value in column "dept_id" violates not-null constraint

-- 4.2 Composite PK: pair (student_id, course_id) must be unique
CREATE TABLE student_courses
(
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- 4.3
-- 1. PRIMARY KEY uniquely identifies each row and forbids NULLs, while a UNIQUE constraint also enforces uniqueness but allows NULL values and a table can have many of them.
-- 2. Use a single-column primary key when one column alone uniquely identifies each row, and use a composite primary key when uniqueness only exists in the combination of two or more columns (like student_id + course_id).
-- 3. A table can have only one PRIMARY KEY because it defines the single, main row identifier and cannot allow NULLs, whereas multiple UNIQUE constraints can coexist because they are just additional uniqueness rules that permit NULLs and don't define the row's primary identity.

-- ======================== PART 5: FOREIGN KEY =========================
-- 5.1 employees_dept.dept_id must exist in departments
CREATE TABLE employees_dept
(
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments (dept_id),
    hire_date DATE
);
INSERT INTO employees_dept VALUES (1, 'Alice Smith', 1, '2025-01-15');
INSERT INTO employees_dept VALUES (2, 'Bob Jones', 2, '2025-01-20');
-- INSERT INTO employees_dept VALUES (3, 'Charlie Brown', 99, '2025-02-01');
--   FAIL: violates foreign key constraint "employees_dept_dept_id_fkey" (dept 99 not in departments)

-- 5.2 Library schema
CREATE TABLE authors
(
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);
CREATE TABLE publishers
(
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);
CREATE TABLE books
(
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors (author_id),
    publisher_id INTEGER REFERENCES publishers (publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);
INSERT INTO authors VALUES
(1, 'George Orwell', 'United Kingdom'),
(2, 'J.K. Rowling', 'United Kingdom');
INSERT INTO publishers VALUES
(1, 'Secker & Warburg', 'London'),
(2, 'Bloomsbury', 'London');
INSERT INTO books VALUES
(1, 'Nineteen Eighty-Four', 1, 1, 1949, '978-0451524935'),
(2, 'Harry Potter', 2, 2, 1997, '978-0747532699');
-- INSERT INTO books VALUES (3, 'Copy', 1, 1, 2000, '978-0451524935');
--   FAIL: duplicate key value violates unique constraint "books_isbn_key"

-- 5.3 ON DELETE behaviors
CREATE TABLE categories
(
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);
CREATE TABLE products_fk
(
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories (category_id) ON DELETE RESTRICT
);
CREATE TABLE orders
(
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);
CREATE TABLE order_items
(
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders (order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk (product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO categories VALUES (2, 'Books');
INSERT INTO products_fk VALUES (1, 'Laptop', 1);
INSERT INTO products_fk VALUES (2, 'Phone', 1);
INSERT INTO orders VALUES (1, '2025-01-10');
INSERT INTO order_items VALUES (1, 1, 1, 2);
INSERT INTO order_items VALUES (2, 1, 2, 1);

-- Scenario 1 (RESTRICT): category 1 still has products
-- DELETE FROM categories WHERE category_id = 1;
--   FAIL: update or delete on table "categories" violates foreign key constraint
--   "products_fk_category_id_fkey" on table "products_fk". Nothing is deleted.
DELETE FROM categories WHERE category_id = 2;  -- OK: Books has no products

-- Scenario 2 (CASCADE)
SELECT * FROM order_items;                      -- 2 rows
DELETE FROM orders WHERE order_id = 1;
SELECT * FROM order_items;                      -- 0 rows: removed together with order 1

-- ====================== PART 6: E-COMMERCE ============================
-- Separate schema: customers and orders names were already used above,
-- so earlier demo tables stay intact.
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce;

CREATE TABLE customers
(
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,                 -- one account per email
    phone TEXT,
    registration_date DATE NOT NULL
);
CREATE TABLE products
(
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);
CREATE TABLE orders
(
    order_id INTEGER PRIMARY KEY,
    -- RESTRICT: a customer with orders cannot be deleted (order history must be kept)
    customer_id INTEGER NOT NULL REFERENCES customers (customer_id) ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);
CREATE TABLE order_details
(
    order_detail_id INTEGER PRIMARY KEY,
    -- CASCADE: lines belong to the order and are deleted with it
    order_id INTEGER NOT NULL REFERENCES orders (order_id) ON DELETE CASCADE,
    -- RESTRICT: a product that was sold cannot be deleted
    product_id INTEGER NOT NULL REFERENCES products (product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO customers VALUES
(1, 'Alice Smith', 'alice@example.com', '555-1111', '2025-01-01'),
(2, 'Bob Jones', 'bob@example.com', '555-2222', '2025-01-05'),
(3, 'Charlie Brown', 'charlie@example.com', '555-3333', '2025-01-10'),
(4, 'Dana White', 'dana@example.com', NULL, '2025-02-01'),
(5, 'Eve Black', 'eve@example.com', '555-5555', '2025-02-15');

INSERT INTO products VALUES
(1, 'Laptop', '14-inch laptop', 1000, 50),
(2, 'Mouse', 'Wireless mouse', 25, 200),
(3, 'Keyboard', 'Mechanical keyboard', 75, 100),
(4, 'Monitor', '27-inch monitor', 300, 30),
(5, 'Headset', 'Noise-cancelling', 150, 0);

INSERT INTO orders VALUES
(1, 1, '2025-03-01', 1025, 'pending'),
(2, 2, '2025-03-02', 75, 'processing'),
(3, 3, '2025-03-03', 300, 'shipped'),
(4, 4, '2025-03-04', 150, 'delivered'),
(5, 5, '2025-03-05', 50, 'cancelled');

INSERT INTO order_details VALUES
(1, 1, 1, 1, 1000),
(2, 1, 2, 1, 25),
(3, 2, 3, 1, 75),
(4, 3, 4, 1, 300),
(5, 4, 5, 1, 150),
(6, 5, 2, 2, 25);   -- order 5: 2 mice = 50 (matches total_amount)

-- ---------- Test queries ----------
SELECT * FROM customers;                         -- 5 rows
SELECT * FROM products WHERE stock_quantity = 0; -- Headset

-- UNIQUE
-- INSERT INTO customers VALUES (6, 'Frank Green', 'alice@example.com', '555-6666', '2025-03-10');
--   FAIL: duplicate key value violates unique constraint "customers_email_key"
-- PRIMARY KEY
-- INSERT INTO products VALUES (1, 'Dup', 'x', 10, 1);
--   FAIL: duplicate key value violates unique constraint "products_pkey"
-- NOT NULL
-- INSERT INTO customers VALUES (7, NULL, 'n@example.com', NULL, '2025-03-10');
--   FAIL: null value in column "name" violates not-null constraint
-- CHECK price >= 0
-- INSERT INTO products VALUES (6, 'Tablet', '10-inch tablet', -100, 20);
--   FAIL: violates check constraint "products_price_check"
-- CHECK stock_quantity >= 0
-- INSERT INTO products VALUES (7, 'Tablet', '10-inch tablet', 100, -1);
--   FAIL: violates check constraint "products_stock_quantity_check"
-- CHECK status
-- INSERT INTO orders VALUES (6, 1, '2025-03-11', 500, 'unknown');
--   FAIL: violates check constraint "orders_status_check"
-- CHECK quantity > 0
-- INSERT INTO order_details VALUES (7, 1, 1, 0, 1000);
--   FAIL: violates check constraint "order_details_quantity_check"
-- FOREIGN KEY: non-existent customer / product
-- INSERT INTO orders VALUES (6, 99, '2025-03-11', 500, 'pending');
--   FAIL: violates foreign key constraint "orders_customer_id_fkey"
-- INSERT INTO order_details VALUES (7, 1, 99, 1, 10);
--   FAIL: violates foreign key constraint "order_details_product_id_fkey"
-- ON DELETE RESTRICT: customer with orders / sold product
-- DELETE FROM customers WHERE customer_id = 1;
--   FAIL: violates foreign key constraint "orders_customer_id_fkey" on table "orders"
-- DELETE FROM products WHERE product_id = 1;
--   FAIL: violates foreign key constraint "order_details_product_id_fkey" on table "order_details"

-- ON DELETE CASCADE (succeeds)
DELETE FROM orders WHERE order_id = 1;
SELECT * FROM order_details WHERE order_id = 1;  -- 0 rows: lines deleted with the order

RESET search_path;