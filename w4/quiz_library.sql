-- Task 1

INSERT INTO books (title, genre, price, copies)
VALUES ('Python Basics', 'Science', 7500.00, 3),
       ('Kazakh Legends', DEFAULT, 4200.00, DEFAULT)
RETURNING book_id, title, genre, copies;

-- Task 2

UPDATE books
SET price = price * 1.15
WHERE genre = 'Science' AND copies > 2
RETURNING title, price;

-- Task 3

UPDATE books
SET status = CASE
    WHEN copies = 0        THEN 'Out'
    WHEN copies BETWEEN 1 AND 2 THEN 'Limited'
    ELSE 'Available'
END;

-- Task 4

UPDATE books
SET copies = copies - (
    SELECT COUNT(*)
    FROM loans
    WHERE loans.book_id = books.book_id
        AND loans.return_date is NULL
)
WHERE book_id IN (
    SELECT book_id
    FROM loans
    WHERE return_date is NULL
    );