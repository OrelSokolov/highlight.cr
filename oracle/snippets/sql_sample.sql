-- Отчёт по пользователям
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    age INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    data JSONB
);

CREATE INDEX idx_users_name ON users (name);

INSERT INTO users (name, email, age, data)
VALUES ('Олег', 'oleg@example.com', 30, '{"tags": ["a", "b"]}'::jsonb);

WITH active AS (
    SELECT u.id, u.name, COUNT(p.id) AS posts
    FROM users u
    LEFT JOIN posts p ON p.user_id = u.id AND p.deleted_at IS NULL
    WHERE u.age >= 18 AND u.name ILIKE '%ле%'
    GROUP BY u.id, u.name
    HAVING COUNT(p.id) > 0
)
UPDATE users SET age = age + 1 WHERE id IN (SELECT id FROM active);

SELECT u.name,
       COALESCE(SUM(p.views), 0) AS total,
       ROW_NUMBER() OVER (PARTITION BY u.name ORDER BY p.created_at DESC) AS rn
FROM users u JOIN posts p USING (user_id)
ORDER BY total DESC LIMIT 10;

DELETE FROM posts WHERE created_at < '2020-01-01';
