-- Part A

CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name  VARCHAR(50),
    department VARCHAR(50),
    salary     INTEGER,
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50),
    budget     INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- Part B

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1001, 'Aida', 'Nurlanova', 'IT'),
       (1002, 'Dana', 'Serik',     'HR');

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Timur', 'Bekov', 'IT', DEFAULT, '2021-03-15', DEFAULT);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT',    150000, 1001),
       ('Sales',  90000, NULL),
       ('HR',     60000, 1002);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Ruslan', 'Omarov', 'Sales', 50000 * 1.1, CURRENT_DATE);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Aigerim',   'Sadykova', 'IT',    85000, '2018-06-01', 'Active'),
       ('Nurlan',    'Abenov',   'IT',    62000, '2019-09-10', 'Active'),
       ('Madina',    'Kairat',   'Sales', 45000, '2022-02-20', 'Active'),
       ('Yerlan',    'Zhaksy',   'Sales', 70000, '2017-11-05', 'Inactive'),
       ('Saltanat',  'Amir',     'HR',    38000, '2023-05-12', 'Inactive'),
       ('Bauyrzhan', 'Tolegen',  'IT',    30000, '2023-08-01', 'Terminated'),
       ('Kamila',    'Dosym',    NULL,    35000, '2023-09-15', 'Active');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Website Redesign', 1, '2022-01-01', '2022-12-31',  80000),
       ('Mobile App',       1, '2023-03-01', '2024-06-30', 120000),
       ('Sales Campaign',   2, '2022-05-01', '2022-11-30',  40000),
       ('HR Portal',        3, '2023-06-01', '2024-03-31',  55000);

CREATE TEMPORARY TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT * FROM employees
WHERE department = 'IT';

-- Part C

UPDATE employees
SET salary = salary * 1.10;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
                     WHEN salary > 80000 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE employees
SET department = CASE
                     WHEN last_name IN ('Nurlanova', 'Bekov', 'Sadykova', 'Abenov', 'Tolegen') THEN 'IT'
                     WHEN last_name IN ('Omarov', 'Kairat', 'Zhaksy') THEN 'Sales'
                     WHEN last_name IN ('Serik', 'Amir') THEN 'HR'
                     ELSE NULL
                 END;

UPDATE departments d
SET budget = (SELECT AVG(e.salary) * 1.2
              FROM employees e
              WHERE e.department = d.dept_name)
WHERE EXISTS (SELECT 1
              FROM employees e
              WHERE e.department = d.dept_name
                AND e.salary IS NOT NULL);

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- Part D

DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('Legal', 20000, NULL);

DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- Part E

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Alikhan', 'Nurgaliev', NULL, NULL, '2024-01-10');

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- Part F

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zhanar', 'Ibragim', 'IT', 60000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees e
SET salary = e.salary + 5000
FROM (SELECT emp_id, salary AS old_salary
      FROM employees
      WHERE department = 'IT') AS old_data
WHERE e.emp_id = old_data.emp_id
RETURNING e.emp_id, old_data.old_salary, e.salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- Part G

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Arman', 'Kasymov', 'IT', 58000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Arman'
                    AND last_name  = 'Kasymov');

UPDATE departments SET budget = 150000 WHERE dept_name = 'IT';

UPDATE employees e
SET salary = e.salary * CASE
                            WHEN (SELECT d.budget
                                  FROM departments d
                                  WHERE d.dept_name = e.department) > 100000
                                THEN 1.10
                            ELSE 1.05
                        END;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bulk1', 'Batch', 'IT', 50000, CURRENT_DATE),
       ('Bulk2', 'Batch', 'IT', 51000, CURRENT_DATE),
       ('Bulk3', 'Batch', 'IT', 52000, CURRENT_DATE),
       ('Bulk4', 'Batch', 'IT', 53000, CURRENT_DATE),
       ('Bulk5', 'Batch', 'IT', 54000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.10
WHERE last_name = 'Batch';

CREATE TABLE employee_archive (LIKE employees INCLUDING DEFAULTS);

UPDATE employees SET status = 'Inactive' WHERE first_name IN ('Bulk1', 'Bulk2');

BEGIN;

INSERT INTO employee_archive
SELECT * FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

COMMIT;

UPDATE projects p
SET end_date = p.end_date + 30
WHERE p.budget > 50000
  AND (SELECT COUNT(*)
       FROM employees e
       JOIN departments d ON d.dept_name = e.department
       WHERE d.dept_id = p.dept_id) > 3;

-- Проверка

SELECT * FROM projects;