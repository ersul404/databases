-- Exercise 0
SELECT (SELECT COUNT(*) FROM stations) AS stations,
       (SELECT COUNT(*) FROM bikes) AS bikes,
       (SELECT COUNT(*) FROM members) AS members,
       (SELECT COUNT(*) FROM rentals) AS rentals;

-- PART 2

-- Worked example
CREATE OR REPLACE FUNCTION inc(val INTEGER) RETURNS INTEGER AS $$
DECLARE
    result INTEGER;
BEGIN
    result := val + 1;
    RETURN result;
END; $$
LANGUAGE plpgsql;

SELECT inc(10);

-- Exercise 2.1
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;
    RETURN v_days;
END; $$
LANGUAGE plpgsql;

SELECT rental_days(2) AS rental_2, rental_days(11) AS rental_11, rental_days(19) AS rental_19, rental_days(999) AS rental_999;

-- Exercise 2.2
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
DECLARE
    v_cnt INT;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM rentals
    WHERE member_id = p_member_id;
    RETURN v_cnt;
END; $$
LANGUAGE plpgsql;

SELECT member_rental_count(1) AS m1, member_rental_count(5) AS m5, member_rental_count(6) AS m6, member_rental_count(99) AS m99;

-- Exercise 2.3
CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city INTO v_city
    FROM stations
    WHERE station_id = p_station_id;
    RETURN v_city;
END; $$
LANGUAGE plpgsql;

SELECT station_city(30) AS station_30, station_city(77) AS station_77;

-- Exercise 2.4
SELECT rental_id, member_id, rental_days(rental_id) AS days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY days DESC, rental_id;

-- PART 3

-- Exercise 3.1
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100), 2);
END; $$
LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);

-- Exercise 3.2
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE)
AS $$
BEGIN
    SELECT COUNT(*), COALESCE(SUM(fee), 0), MAX(start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals
    WHERE member_id = p_member_id;
END; $$
LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);

-- Exercise 3.3
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
AS $$
BEGIN
    p_fee := p_fee + 5.00;
END; $$
LANGUAGE plpgsql;

SELECT apply_late_fee(fee) AS fee_with_late_charge FROM rentals WHERE rental_id = 1;

-- Exercise 3.4
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC)
AS $$
BEGIN
    SELECT SUM(p_fees[i]), ROUND(AVG(p_fees[i]), 2), MAX(p_fees[i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) g(i);
END; $$
LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
SELECT * FROM fee_summary();

-- Exercise 3.5

-- PART 4

-- Exercise 4.1
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1) AS member_1, total_fees(6) AS member_6;

-- Exercise 4.2
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01') AS from_2024, total_fees(1, DATE '2025-01-01') AS from_2025;

SELECT proname, pg_get_function_identity_arguments(oid) AS signature
FROM pg_proc WHERE proname = 'total_fees' ORDER BY 2;

-- Exercise 4.3
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT,
                                      p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1);

-- Exercise 4.4
DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1);

-- Exercise 4.5
CREATE OR REPLACE FUNCTION total_fees(p_name VARCHAR) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0) INTO v_total
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    WHERE m.full_name = p_name;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
SELECT total_fees(1);

SELECT proname, pg_get_function_identity_arguments(oid) AS signature
FROM pg_proc WHERE proname = 'total_fees' ORDER BY 2;

-- PART 5

-- Exercise 5.1
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (found_id INT, found_model VARCHAR, found_rate NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model, b.daily_rate
    FROM bikes b
    WHERE b.model ILIKE p_pattern
    ORDER BY b.bike_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');

-- Exercise 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (h_rental_id INT, h_model VARCHAR, h_station VARCHAR, h_days INT, h_fee NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id, b.model, s.station_name, (r.end_date - r.start_date), r.fee
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    LEFT JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END; $$
LANGUAGE plpgsql;

SELECT * FROM member_history(3);

-- Exercise 5.3
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Exercise 5.3, fix 1
DROP FUNCTION bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Exercise 5.3, fix 2
DROP FUNCTION bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT b.bike_id, b.model FROM bikes b WHERE b.station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Exercise 5.4
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name, COUNT(b.bike_id), s.capacity - COUNT(b.bike_id)
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');

-- Exercise 5.4, fixed
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           COUNT(b.bike_id)::INT,
           (s.capacity - COUNT(b.bike_id))::INT
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');

-- PART 6

-- Exercise 6.1
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;

-- Exercise 6.1, question
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END wrong_label $$;

-- Exercise 6.2
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
    fee_total NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    SELECT SUM(fee) INTO fee_total FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
    RAISE NOTICE '1) outer fee_total before the subblock: %', fee_total;

    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT SUM(fee) INTO fee_total FROM rentals WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE '2) subblock fee_total (own variable): %', fee_total;
        RAISE NOTICE '3) outer fee_total via the label: %', rental_report.fee_total;
    END;

    RAISE NOTICE '4) outer fee_total after the subblock: %', fee_total;
END rental_report $$;

-- Exercise 6.3
DO $$
<<rental_report>>
BEGIN
    DECLARE
        inner_cnt INTEGER;
    BEGIN
        SELECT COUNT(*) INTO inner_cnt FROM rentals;
        RAISE NOTICE 'first subblock: inner_cnt = %', inner_cnt;
    END;

    BEGIN
        RAISE NOTICE 'second subblock: inner_cnt = %', inner_cnt;
    END;
END rental_report $$;

-- Exercise 6.3, fixed
DO $$
<<rental_report>>
DECLARE
    shared_cnt INTEGER;
BEGIN
    BEGIN
        SELECT COUNT(*) INTO shared_cnt FROM rentals;
        RAISE NOTICE 'first subblock: shared_cnt = %', shared_cnt;
    END;

    BEGIN
        RAISE NOTICE 'second subblock: shared_cnt = %', shared_cnt;
    END;
END rental_report $$;

-- Exercise 6.4
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee) FILTER (WHERE start_date <  p_from_date), 0),
           COALESCE(SUM(fee) FILTER (WHERE start_date >= p_from_date), 0)
    INTO before_total, after_total
    FROM rentals;
END; $$
LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');

SELECT before_total, after_total, before_total + after_total AS sum_of_parts,
       (SELECT SUM(fee) FROM rentals) AS table_total,
       before_total + after_total = (SELECT SUM(fee) FROM rentals) AS they_match
FROM fee_split(DATE '2025-01-01');

-- PART 7

-- Exercise 7.1
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC)
AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT capacity INTO v_capacity
    FROM stations
    WHERE station_id = p_station_id;

    SELECT COUNT(*) INTO bikes_parked
    FROM bikes
    WHERE station_id = p_station_id;

    IF v_capacity IS NULL OR v_capacity = 0 THEN
        capacity_pct := NULL;
    ELSE
        capacity_pct := ROUND(100.0 * bikes_parked / v_capacity, 1);
    END IF;
END; $$
LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l
ORDER BY s.station_id;

-- Exercise 7.2
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (member_name VARCHAR, rental_cnt INT, total_spent NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY COALESCE(SUM(r.fee), 0) DESC, m.full_name
    LIMIT p_limit;
END; $$
LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);

-- Exercise 7.3
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (member_name VARCHAR, bike_model VARCHAR, days INT, amount_owed NUMERIC, status VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           b.model,
           (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT,
           ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2),
           (CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END)::VARCHAR
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id;
END; $$
LANGUAGE plpgsql STABLE;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);
SELECT fee AS stored_fee FROM rentals WHERE rental_id = 11;
SELECT CURRENT_DATE AS run_date;

-- Exercise 7.4
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (member_cnt INT, rental_cnt INT, revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (member_cnt INT, rental_cnt INT, revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
                       AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END; $$
LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Astana');
SELECT * FROM city_report('Shymkent');
SELECT * FROM city_report('Almaty', DATE '2025-10-01');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');

-- Exercise 7.4, question
SELECT COUNT(DISTINCT m.member_id) AS members_date_in_on
FROM members m
LEFT JOIN rentals r ON r.member_id = m.member_id AND r.start_date >= DATE '2025-10-01'
WHERE m.city = 'Almaty';

SELECT COUNT(DISTINCT m.member_id) AS members_date_in_where
FROM members m
LEFT JOIN rentals r ON r.member_id = m.member_id
WHERE m.city = 'Almaty' AND r.start_date >= DATE '2025-10-01';

-- Lab question 2
CREATE OR REPLACE FUNCTION status_label(p_end DATE) RETURNS TEXT AS $$
BEGIN
    IF p_end IS NULL THEN
        RETURN 'it''s still OPEN';
    END IF;
    RETURN 'CLOSED';
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION status_label_quoted(p_end DATE) RETURNS TEXT AS
'BEGIN
    IF p_end IS NULL THEN
        RETURN ''it''''s still OPEN'';
    END IF;
    RETURN ''CLOSED'';
END;' LANGUAGE plpgsql;

SELECT status_label(NULL) AS a_dollar, status_label_quoted(NULL) AS b_quoted, status_label(DATE '2025-01-01') AS closed;

-- Lab question 10
CREATE OR REPLACE FUNCTION inc(val INTEGER) RETURNS INTEGER AS $$
BEGIN RETURN val + 1; END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION inc(val NUMERIC) RETURNS NUMERIC AS $$
BEGIN RETURN val + 100; END; $$ LANGUAGE plpgsql;

SELECT proname, pg_get_function_identity_arguments(oid) AS signature
FROM pg_proc WHERE proname = 'inc' ORDER BY 2;

SELECT inc(10) AS int_call, inc(10.0) AS numeric_call;