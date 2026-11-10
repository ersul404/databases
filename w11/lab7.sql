-- Part 1: Database Setup
SET search_path TO lab6;


-- Part 2: Creating Basic Views

-- Exercise 2.1
CREATE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- Exercise 2.2
CREATE VIEW dept_statistics AS
SELECT d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       ROUND(AVG(e.salary), 2) AS avg_salary,
       MAX(e.salary) AS max_salary,
       MIN(e.salary) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;

-- Exercise 2.3
CREATE VIEW project_overview AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       COUNT(e.emp_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name, d.location;

SELECT * FROM project_overview;

-- Exercise 2.4
CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;


-- Part 3: Modifying and Managing Views

-- Exercise 3.1
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- Exercise 3.2
ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;

-- Exercise 3.3
CREATE VIEW temp_view AS
SELECT * FROM employees WHERE salary < 50000;

DROP VIEW temp_view;


-- Part 4: Updatable Views

-- Exercise 4.1
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- Exercise 4.2
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT * FROM employees WHERE emp_name = 'John Smith';

-- Exercise 4.3
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees;

-- Exercise 4.4
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Bob Wilson', 103, 60000);


-- Part 5: Materialized Views

-- Exercise 5.1
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       COALESCE(e.total_employees, 0) AS total_employees,
       COALESCE(e.total_salaries, 0) AS total_salaries,
       COALESCE(p.total_projects, 0) AS total_projects,
       COALESCE(p.total_budget, 0) AS total_project_budget
FROM departments d
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS total_employees, SUM(salary) AS total_salaries
    FROM employees
    GROUP BY dept_id
) e ON d.dept_id = e.dept_id
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS total_projects, SUM(budget) AS total_budget
    FROM projects
    GROUP BY dept_id
) p ON d.dept_id = p.dept_id
WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- Exercise 5.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

REFRESH MATERIALIZED VIEW dept_summary_mv;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- Exercise 5.3
CREATE UNIQUE INDEX idx_dept_summary_mv_dept_id
ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

-- Exercise 5.4
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       COUNT(e.emp_id) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
WITH NO DATA;

SELECT * FROM project_stats_mv;

REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;


-- Part 6: Database Roles

-- Exercise 6.1
CREATE ROLE analyst;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE USER report_user PASSWORD 'report456';

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

-- Exercise 6.2
CREATE ROLE db_creator LOGIN CREATEDB PASSWORD 'creator789';
CREATE ROLE user_manager LOGIN CREATEROLE PASSWORD 'manager101';
CREATE ROLE admin_user LOGIN SUPERUSER PASSWORD 'admin999';

-- Exercise 6.3
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- Exercise 6.4
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE USER hr_user1 PASSWORD 'hr001';
CREATE USER hr_user2 PASSWORD 'hr002';
CREATE USER finance_user1 PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- Exercise 6.5
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- Exercise 6.6
ALTER ROLE analyst LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager SUPERUSER;
ALTER ROLE analyst PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;


-- Part 7: Advanced Role Management

-- Exercise 7.1
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA lab6 TO read_only;

CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- Exercise 7.2
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'lab6';

SELECT viewname, viewowner
FROM pg_views
WHERE schemaname = 'lab6';

-- Exercise 7.3
CREATE ROLE temp_owner LOGIN;

CREATE TABLE temp_table (id INT);

ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

-- Exercise 7.4
CREATE VIEW hr_employee_view AS
SELECT * FROM employees WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;


-- Part 8: Practical Scenarios

-- Exercise 8.1
CREATE VIEW dept_dashboard AS
SELECT d.dept_name,
       d.location,
       COALESCE(e.employee_count, 0) AS employee_count,
       COALESCE(ROUND(e.avg_salary, 2), 0) AS avg_salary,
       COALESCE(p.project_count, 0) AS active_projects,
       COALESCE(p.total_budget, 0) AS total_project_budget,
       CASE
           WHEN COALESCE(e.employee_count, 0) = 0 THEN 0
           ELSE ROUND(COALESCE(p.total_budget, 0) / e.employee_count, 2)
       END AS budget_per_employee
FROM departments d
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS employee_count, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
) e ON d.dept_id = e.dept_id
LEFT JOIN (
    SELECT dept_id, COUNT(*) AS project_count, SUM(budget) AS total_budget
    FROM projects
    GROUP BY dept_id
) p ON d.dept_id = p.dept_id;

SELECT * FROM dept_dashboard;

-- Exercise 8.2
ALTER TABLE projects
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;

-- Exercise 8.3
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA lab6 TO viewer_role;

CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

CREATE USER alice PASSWORD 'alice123';
CREATE USER bob PASSWORD 'bob123';
CREATE USER charlie PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;