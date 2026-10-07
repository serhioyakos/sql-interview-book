-- Problem 1.1
SELECT order_id,
       amount,
       amount * 1.2 AS amount_with_tax
FROM orders
WHERE status = 'completed'
  AND amount * 1.2 > 350
ORDER BY amount_with_tax DESC, order_id;

-- Problem 1.2
SELECT c.country,
       COUNT(*) AS completed_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.country
HAVING COUNT(*) >= 20
ORDER BY completed_orders DESC;

-- Problem 1.3
SELECT COUNT(*) FILTER (WHERE referred_by = NULL)  AS wrong_way,
       COUNT(*) FILTER (WHERE referred_by IS NULL) AS right_way
FROM customers;

-- Problem 1.4
SELECT c.customer_id,
       c.name,
       c.country
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM customers r
    WHERE r.referred_by = c.customer_id
)
ORDER BY c.customer_id;

-- Problem 1.5
SELECT COUNT(*)                    AS all_customers,
       COUNT(referred_by)          AS with_referrer,
       COUNT(DISTINCT referred_by) AS distinct_referrers,
       COUNT(DISTINCT country)     AS countries
FROM customers;

-- Problem 1.6
SELECT CASE
           WHEN amount < 50  THEN 'small'
           WHEN amount < 150 THEN 'medium'
           ELSE 'large'
       END AS size_bucket,
       COUNT(*)    AS orders,
       SUM(amount) AS revenue
FROM orders
WHERE status = 'completed'
GROUP BY size_bucket
ORDER BY MIN(amount);

-- Problem 1.7
SELECT COUNT(*)                            AS orders,
       COUNT(discount)                     AS with_discount,
       ROUND(AVG(discount), 2)             AS avg_ignoring_nulls,
       ROUND(AVG(COALESCE(discount, 0)), 2) AS avg_over_all_orders
FROM orders
WHERE status = 'completed';

-- Problem 1.8
SELECT c.country,
       COUNT(DISTINCT c.customer_id) AS customers,
       COUNT(*)                      AS joined_rows
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN products p     ON p.product_id  = oi.product_id
WHERE p.category = 'Electronics'
  AND o.status = 'completed'
GROUP BY c.country
ORDER BY c.country;

-- Problem 1.9
SELECT order_id,
       amount
FROM orders
WHERE status = 'completed'
  AND amount >= (
      SELECT amount
      FROM orders
      WHERE status = 'completed'
      ORDER BY amount DESC
      LIMIT 1 OFFSET 4
  )
ORDER BY amount DESC, order_id;

-- Problem 1.10
SELECT COUNT(*) FILTER (
           WHERE created_at BETWEEN '2025-03-01' AND '2025-03-07'
       ) AS using_between,
       COUNT(*) FILTER (
           WHERE created_at >= '2025-03-01'
             AND created_at <  '2025-03-08'
       ) AS half_open_range
FROM orders;

-- Problem 2.1
SELECT c.name,
       c.country,
       COUNT(o.order_id) AS completed_orders
FROM customers c
LEFT JOIN orders o
       ON o.customer_id = c.customer_id
      AND o.status = 'completed'
GROUP BY c.customer_id, c.name, c.country
ORDER BY completed_orders, c.name, c.customer_id
LIMIT 5;

-- Problem 2.2
SELECT
    (SELECT COUNT(DISTINCT c.customer_id)
     FROM customers c
     LEFT JOIN orders o
            ON o.customer_id = c.customer_id
           AND o.status = 'completed') AS filter_in_on,
    (SELECT COUNT(DISTINCT c.customer_id)
     FROM customers c
     LEFT JOIN orders o
            ON o.customer_id = c.customer_id
     WHERE o.status = 'completed')     AS filter_in_where;

-- Problem 2.3
SELECT c.customer_id,
       c.name,
       c.country
FROM customers c
LEFT JOIN orders o
       ON o.customer_id = c.customer_id
      AND o.status = 'completed'
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- Problem 2.4
SELECT c.country,
       COUNT(*) AS book_buyers
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.customer_id = c.customer_id
      AND o.status = 'completed'
      AND p.category = 'Books'
)
GROUP BY c.country
ORDER BY c.country;

-- Problem 2.5
SELECT c.name    AS customer,
       c.country,
       r.name    AS referrer,
       r.country AS referrer_country
FROM customers c
JOIN customers r ON r.customer_id = c.referred_by
ORDER BY c.customer_id;

-- Problem 2.6
SELECT p.category,
       SUM(o.amount)                    AS summed_order_amount,
       SUM(oi.quantity * oi.unit_price) AS item_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY p.category;

-- Problem 2.7
WITH spend AS (
    SELECT customer_id,
           SUM(amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),
variety AS (
    SELECT o.customer_id,
           COUNT(DISTINCT oi.product_id) AS distinct_products
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
)
SELECT c.name,
       s.revenue,
       v.distinct_products
FROM customers c
JOIN spend s   ON s.customer_id = c.customer_id
JOIN variety v ON v.customer_id = c.customer_id
ORDER BY s.revenue DESC, c.name, c.customer_id
LIMIT 5;

-- Problem 2.8
WITH first_days AS (
    SELECT p.name AS product,
           SUM(oi.quantity) AS units
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
      AND o.order_date BETWEEN DATE '2025-03-01' AND DATE '2025-03-03'
    GROUP BY p.name
),
last_days AS (
    SELECT p.name AS product,
           SUM(oi.quantity) AS units
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
      AND o.order_date BETWEEN DATE '2025-03-29' AND DATE '2025-03-31'
    GROUP BY p.name
)
SELECT COALESCE(f.product, l.product) AS product,
       f.units                        AS units_mar_1_3,
       l.units                        AS units_mar_29_31
FROM first_days f
FULL OUTER JOIN last_days l ON l.product = f.product
ORDER BY product;

-- Problem 2.9
WITH days AS (
    SELECT CAST(d AS DATE) AS day
    FROM generate_series(DATE '2025-03-01', DATE '2025-03-07',
                         INTERVAL '1 day') AS g(d)
),
countries AS (
    SELECT DISTINCT country FROM customers
),
daily AS (
    SELECT c.country, o.order_date, SUM(o.amount) AS revenue
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
    GROUP BY c.country, o.order_date
)
SELECT k.country,
       d.day,
       COALESCE(x.revenue, 0) AS revenue
FROM countries k
CROSS JOIN days d
LEFT JOIN daily x
       ON x.country = k.country
      AND x.order_date = d.day
ORDER BY k.country, d.day;

-- Problem 2.10
WITH bands (band, min_amount, max_amount) AS (
    VALUES ('under 50',   0,   50),
           ('50 to 149',  50,  150),
           ('150 to 299', 150, 300),
           ('300 to 999', 300, 1000),
           ('1000 plus',  1000, 100000)
)
SELECT b.band,
       COUNT(o.order_id) AS orders
FROM bands b
LEFT JOIN orders o
       ON o.amount >= b.min_amount
      AND o.amount <  b.max_amount
      AND o.status = 'completed'
GROUP BY b.band, b.min_amount
ORDER BY b.min_amount;

-- Problem 2.11
SELECT c.name,
       c.country,
       last_o.order_date AS last_order_date,
       last_o.amount     AS last_amount
FROM customers c
LEFT JOIN LATERAL (
    SELECT o.order_date, o.amount
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.status = 'completed'
    ORDER BY o.order_date DESC, o.order_id DESC
    LIMIT 1
) AS last_o ON TRUE
ORDER BY last_order_date NULLS FIRST, c.name, c.customer_id
LIMIT 5;

-- Problem 2.12
SELECT p1.name  AS product_a,
       p2.name  AS product_b,
       COUNT(*) AS orders_together
FROM order_items a
JOIN order_items b ON b.order_id = a.order_id
                  AND b.product_id > a.product_id
JOIN orders o      ON o.order_id = a.order_id
JOIN products p1   ON p1.product_id = a.product_id
JOIN products p2   ON p2.product_id = b.product_id
WHERE o.status = 'completed'
GROUP BY p1.name, p2.name
ORDER BY orders_together DESC, product_a, product_b
LIMIT 5;

-- Problem 2.13
SELECT a.name,
       a.customer_id AS id_1,
       a.country     AS country_1,
       b.customer_id AS id_2,
       b.country     AS country_2
FROM customers a
JOIN customers b ON b.name = a.name
                AND b.customer_id > a.customer_id
ORDER BY a.name, id_1;

-- Problem 2.14
WITH spend AS (
    SELECT c.customer_id, c.name, c.country,
           SUM(o.amount) AS total
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id, c.name, c.country
),
country_avg AS (
    SELECT country, AVG(total) AS avg_total
    FROM spend
    GROUP BY country
)
SELECT s.country,
       s.name,
       s.total,
       ROUND(a.avg_total, 2) AS country_avg
FROM spend s
JOIN country_avg a ON a.country = s.country
WHERE s.total > a.avg_total
ORDER BY s.country, s.total DESC, s.name;

-- Problem 3.1
SELECT c.country,
       COUNT(*)                AS orders,
       SUM(o.amount)           AS revenue,
       ROUND(AVG(o.amount), 2) AS avg_order_value
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.country
ORDER BY revenue DESC;

-- Problem 3.2
SELECT c.country,
       COUNT(*) AS all_orders,
       COUNT(*) FILTER (WHERE o.status = 'cancelled') AS cancelled,
       ROUND(100.0 * COUNT(*) FILTER (WHERE o.status = 'cancelled')
             / COUNT(*), 1) AS cancel_rate_pct
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.country
ORDER BY cancel_rate_pct DESC;

-- Problem 3.3
SELECT c.country,
       SUM(CASE WHEN p.category = 'Books'
                THEN oi.quantity * oi.unit_price ELSE 0 END) AS books,
       SUM(CASE WHEN p.category = 'Electronics'
                THEN oi.quantity * oi.unit_price ELSE 0 END)
           AS electronics,
       SUM(CASE WHEN p.category = 'Home'
                THEN oi.quantity * oi.unit_price ELSE 0 END) AS home
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE o.status = 'completed'
GROUP BY c.country
ORDER BY c.country;

-- Problem 3.4
SELECT CAST(DATE_TRUNC('week', order_date) AS DATE) AS week_start,
       COUNT(DISTINCT order_date)                   AS days_with_orders,
       SUM(amount)                                  AS revenue
FROM orders
WHERE status = 'completed'
GROUP BY week_start
ORDER BY week_start;

-- Problem 3.5
SELECT c.name,
       c.country,
       COUNT(*)                AS orders,
       ROUND(AVG(o.amount), 2) AS avg_order_value
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name, c.country
HAVING COUNT(*) >= 5
   AND AVG(o.amount) > 130
ORDER BY avg_order_value DESC;

-- Problem 3.6
SELECT p.category,
       COUNT(DISTINCT oi.product_id) AS products_sold,
       COUNT(DISTINCT o.customer_id) AS buyers,
       SUM(oi.quantity)              AS units
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY p.category;

-- Problem 3.7
WITH by_country AS (
    SELECT c.country,
           AVG(o.amount) AS country_avg
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
    GROUP BY c.country
)
SELECT (SELECT ROUND(AVG(amount), 2)
        FROM orders
        WHERE status = 'completed')  AS avg_over_orders,
       ROUND(AVG(country_avg), 2)    AS avg_of_country_avgs
FROM by_country;

-- Problem 3.8
SELECT o.order_id,
       COUNT(*) AS items,
       STRING_AGG(p.name, ', ' ORDER BY p.name) AS products
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE o.order_id <= 5
GROUP BY o.order_id
ORDER BY o.order_id;

-- Problem 3.9
SELECT CASE WHEN GROUPING(c.country) = 1
            THEN 'ALL' ELSE c.country END        AS country,
       CASE WHEN GROUPING(p.category) = 1
            THEN 'subtotal' ELSE p.category END  AS category,
       SUM(oi.quantity * oi.unit_price)          AS revenue
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE o.status = 'completed'
GROUP BY ROLLUP (c.country, p.category)
ORDER BY GROUPING(c.country), c.country,
         GROUPING(p.category), p.category;

-- Problem 3.10
SELECT DISTINCT ON (c.country)
       c.country,
       c.name,
       o.order_id,
       o.amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
ORDER BY c.country, o.amount DESC, o.order_id;

-- Problem 3.11
SELECT user_id,
       login_date,
       COUNT(*) AS copies
FROM logins
GROUP BY user_id, login_date
HAVING COUNT(*) > 1
ORDER BY user_id, login_date;

-- Problem 3.12
SELECT p.name AS product
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o       ON o.order_id = oi.order_id
JOIN customers c    ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY p.product_id, p.name
HAVING COUNT(DISTINCT c.country) = (
    SELECT COUNT(DISTINCT country) FROM customers
)
ORDER BY p.name;

-- Problem 4.1
SELECT COUNT(*)    AS orders_above_avg,
       SUM(amount) AS revenue_above_avg,
       ROUND(100.0 * SUM(amount) / (
           SELECT SUM(amount) FROM orders WHERE status = 'completed'
       ), 1)        AS pct_of_revenue
FROM orders
WHERE status = 'completed'
  AND amount > (
      SELECT AVG(amount) FROM orders WHERE status = 'completed'
  );

-- Problem 4.2
SELECT o.order_id,
       o.customer_id,
       o.amount
FROM orders o
WHERE o.status = 'completed'
  AND o.amount > (
      SELECT AVG(i.amount)
      FROM orders i
      WHERE i.customer_id = o.customer_id
        AND i.status = 'completed'
  )
ORDER BY o.customer_id, o.order_id;

-- Problem 4.3
SELECT c.customer_id,
       c.name,
       c.country
FROM customers c
WHERE c.customer_id IN (
    SELECT o.customer_id
    FROM orders o
    WHERE o.status = 'completed'
      AND o.order_date >= DATE '2025-03-25'
)
ORDER BY c.customer_id;

-- Problem 4.4
SELECT tier,
       COUNT(*)   AS customers,
       SUM(total) AS revenue
FROM (
    SELECT customer_id,
           SUM(amount) AS total,
           CASE
               WHEN SUM(amount) >= 700 THEN 'high'
               WHEN SUM(amount) >= 400 THEN 'mid'
               ELSE 'low'
           END AS tier
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
) AS per_customer
GROUP BY tier
ORDER BY MIN(total) DESC;

-- Problem 4.5
WITH daily AS (
    SELECT c.country,
           o.order_date,
           SUM(o.amount) AS revenue
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
    GROUP BY c.country, o.order_date
),
best AS (
    SELECT country, MAX(revenue) AS best_revenue
    FROM daily
    GROUP BY country
)
SELECT d.country,
       d.order_date,
       d.revenue
FROM daily d
JOIN best b ON b.country = d.country
           AND b.best_revenue = d.revenue
ORDER BY d.country, d.order_date;

-- Problem 4.6
SELECT MAX(amount) AS second_highest
FROM orders
WHERE status = 'completed'
  AND amount < (
      SELECT MAX(amount)
      FROM orders
      WHERE status = 'completed'
  );

-- Problem 4.7
WITH RECURSIVE chain AS (
    SELECT customer_id,
           name,
           name AS root_referrer,
           0    AS depth
    FROM customers
    WHERE referred_by IS NULL
  UNION ALL
    SELECT c.customer_id,
           c.name,
           ch.root_referrer,
           ch.depth + 1
    FROM customers c
    JOIN chain ch ON c.referred_by = ch.customer_id
)
SELECT name,
       root_referrer,
       depth
FROM chain
WHERE depth > 0
ORDER BY depth DESC, name;

-- Problem 4.8
WITH RECURSIVE days AS (
    SELECT DATE '2025-03-01' AS day
  UNION ALL
    SELECT CAST(day + INTERVAL '1 day' AS DATE)
    FROM days
    WHERE day < DATE '2025-03-31'
)
SELECT COUNT(*) AS days_without_cancellations
FROM days d
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.order_date = d.day
      AND o.status = 'cancelled'
);

-- Problem 4.9
SELECT p.name AS product
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    JOIN orders o    ON o.order_id = oi.order_id
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE oi.product_id = p.product_id
      AND c.country = 'US'
      AND o.status = 'completed'
)
ORDER BY p.name;

-- Problem 4.10
SELECT c.name,
       (SELECT COUNT(*)
        FROM orders o
        WHERE o.customer_id = c.customer_id
          AND o.status = 'completed')  AS completed_orders,
       (SELECT MAX(o.order_date)
        FROM orders o
        WHERE o.customer_id = c.customer_id
          AND o.status = 'completed')  AS last_order
FROM customers c
WHERE c.country = 'US'
ORDER BY c.name;

-- Problem 5.1
WITH daily AS (
    SELECT order_date, SUM(amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY order_date
)
SELECT order_date,
       revenue,
       SUM(revenue) OVER (ORDER BY order_date) AS running_total
FROM daily
ORDER BY order_date;

-- Problem 5.2
SELECT c.country,
       c.name,
       SUM(o.amount) AS total_spend,
       RANK()       OVER w AS spend_rank,
       DENSE_RANK() OVER w AS dense_rank,
       ROW_NUMBER() OVER (
           PARTITION BY c.country
           ORDER BY SUM(o.amount) DESC, c.name
       ) AS row_num
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY c.country, c.name
WINDOW w AS (PARTITION BY c.country ORDER BY SUM(o.amount) DESC)
ORDER BY c.country, row_num;

-- Problem 5.3
WITH product_revenue AS (
    SELECT p.category,
           p.name AS product,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY p.category, p.name
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY category
               ORDER BY revenue DESC, product
           ) AS rn
    FROM product_revenue
)
SELECT category, product, revenue
FROM ranked
WHERE rn <= 3
ORDER BY category, rn;

-- Problem 5.4
WITH ranked AS (
    SELECT customer_id, order_date, amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY order_date, order_id
           ) AS rn
    FROM orders
    WHERE status = 'completed'
)
SELECT c.name,
       c.country,
       r.order_date                 AS first_order_date,
       r.amount                     AS first_order_amount,
       r.order_date - c.signup_date AS days_to_first_order
FROM ranked r
JOIN customers c ON c.customer_id = r.customer_id
WHERE r.rn = 1
ORDER BY days_to_first_order DESC, c.name
LIMIT 5;

-- Problem 5.5
WITH daily AS (
    SELECT order_date, SUM(amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY order_date
)
SELECT order_date,
       revenue,
       revenue - LAG(revenue) OVER w AS change,
       ROUND(100.0 * (revenue - LAG(revenue) OVER w)
             / LAG(revenue) OVER w, 1) AS pct_change
FROM daily
WINDOW w AS (ORDER BY order_date)
ORDER BY order_date;

-- Problem 5.6
WITH daily AS (
    SELECT order_date, SUM(amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY order_date
)
SELECT order_date,
       revenue,
       ROUND(AVG(revenue) OVER (
           ORDER BY order_date
           ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ), 2) AS moving_avg_7d
FROM daily
ORDER BY order_date;

-- Problem 5.7
WITH category_revenue AS (
    SELECT p.category,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY p.category
)
SELECT category,
       revenue,
       ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)
           AS pct_of_total
FROM category_revenue
ORDER BY revenue DESC;

-- Problem 5.8
WITH days AS (
    SELECT DISTINCT user_id, login_date
    FROM logins
),
grouped AS (
    SELECT user_id,
           login_date,
           login_date - CAST(ROW_NUMBER() OVER (
               PARTITION BY user_id ORDER BY login_date
           ) AS INTEGER) AS grp
    FROM days
),
streaks AS (
    SELECT user_id,
           MIN(login_date) AS start_date,
           MAX(login_date) AS end_date,
           COUNT(*)        AS streak_days
    FROM grouped
    GROUP BY user_id, grp
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY streak_days DESC, start_date
           ) AS rn
    FROM streaks
)
SELECT user_id,
       streak_days AS longest_streak,
       start_date,
       end_date
FROM ranked
WHERE rn = 1
ORDER BY longest_streak DESC, user_id;

-- Problem 5.9
WITH flagged AS (
    SELECT user_id,
           event_time,
           CASE
               WHEN LAG(event_time) OVER w IS NULL THEN 1
               WHEN event_time - LAG(event_time) OVER w
                    > INTERVAL '30 minutes' THEN 1
               ELSE 0
           END AS is_new_session
    FROM events
    WINDOW w AS (PARTITION BY user_id ORDER BY event_time)
),
numbered AS (
    SELECT user_id,
           event_time,
           SUM(is_new_session) OVER (
               PARTITION BY user_id
               ORDER BY event_time
               ROWS UNBOUNDED PRECEDING
           ) AS session_id
    FROM flagged
)
SELECT user_id,
       session_id,
       MIN(event_time) AS session_start,
       MAX(event_time) AS session_end,
       COUNT(*)        AS events
FROM numbered
GROUP BY user_id, session_id
ORDER BY user_id, session_id;

-- Problem 5.10
WITH ranked AS (
    SELECT c.country,
           o.amount,
           ROW_NUMBER() OVER (PARTITION BY c.country
                              ORDER BY o.amount) AS rn,
           COUNT(*) OVER (PARTITION BY c.country) AS cnt
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
)
SELECT country,
       ROUND(AVG(amount), 2) AS median_amount
FROM ranked
WHERE rn IN (FLOOR((cnt + 1) / 2.0), FLOOR((cnt + 2) / 2.0))
GROUP BY country
ORDER BY country;

-- Problem 6.1
SELECT EXTRACT(ISODOW FROM order_date) AS iso_weekday,
       COUNT(*)                         AS orders,
       SUM(amount)                      AS revenue
FROM orders
WHERE status = 'completed'
GROUP BY iso_weekday
ORDER BY iso_weekday;

-- Problem 6.2
SELECT EXTRACT(HOUR FROM created_at) AS hour_utc,
       COUNT(*)                       AS orders
FROM orders
GROUP BY hour_utc
ORDER BY orders DESC, hour_utc
LIMIT 5;

-- Problem 6.3
SELECT COUNT(*)           AS active_subscriptions,
       SUM(monthly_price) AS mrr
FROM subscriptions
WHERE start_date <= DATE '2025-01-01'
  AND (end_date IS NULL OR end_date > DATE '2025-01-01');

-- Problem 6.4
WITH months AS (
    SELECT CAST(m AS DATE) AS month_start
    FROM generate_series(DATE '2024-01-01', DATE '2024-12-01',
                         INTERVAL '1 month') AS g(m)
)
SELECT m.month_start,
       COUNT(s.sub_id)                 AS active_subscriptions,
       COALESCE(SUM(s.monthly_price), 0) AS mrr
FROM months m
LEFT JOIN subscriptions s
       ON s.start_date <= m.month_start
      AND (s.end_date IS NULL OR s.end_date > m.month_start)
GROUP BY m.month_start
ORDER BY m.month_start;

-- Problem 6.5
WITH months AS (
    SELECT CAST(m AS DATE) AS month_start
    FROM generate_series(DATE '2024-01-01', DATE '2024-12-01',
                         INTERVAL '1 month') AS g(m)
),
new_subs AS (
    SELECT CAST(DATE_TRUNC('month', start_date) AS DATE)
               AS month_start,
           COUNT(*) AS new_subs
    FROM subscriptions
    GROUP BY 1
),
churned AS (
    SELECT CAST(DATE_TRUNC('month', end_date) AS DATE)
               AS month_start,
           COUNT(*) AS churned
    FROM subscriptions
    WHERE end_date IS NOT NULL
    GROUP BY 1
)
SELECT m.month_start,
       COALESCE(n.new_subs, 0) AS new_subs,
       COALESCE(c.churned, 0)  AS churned,
       COALESCE(n.new_subs, 0)
         - COALESCE(c.churned, 0) AS net_change
FROM months m
LEFT JOIN new_subs n ON n.month_start = m.month_start
LEFT JOIN churned c  ON c.month_start = m.month_start
ORDER BY m.month_start;

-- Problem 6.6
WITH months AS (
    SELECT CAST(m AS DATE) AS month_start
    FROM generate_series(DATE '2024-01-01', DATE '2024-12-01',
                         INTERVAL '1 month') AS g(m)
),
active AS (
    SELECT m.month_start,
           COUNT(s.sub_id) AS active_subs
    FROM months m
    LEFT JOIN subscriptions s
           ON s.start_date <= m.month_start
          AND (s.end_date IS NULL OR s.end_date > m.month_start)
    GROUP BY m.month_start
)
SELECT month_start,
       active_subs,
       ROUND(100.0 * (active_subs - LAG(active_subs) OVER w)
             / NULLIF(LAG(active_subs) OVER w, 0), 1)
           AS growth_pct
FROM active
WINDOW w AS (ORDER BY month_start)
ORDER BY month_start;

-- Problem 6.7
SELECT a.user_id,
       a.sub_id     AS first_sub,
       a.start_date AS first_start,
       a.end_date   AS first_end,
       b.sub_id     AS second_sub,
       b.start_date AS second_start
FROM subscriptions a
JOIN subscriptions b
  ON b.user_id = a.user_id
 AND b.sub_id > a.sub_id
 AND a.start_date < COALESCE(b.end_date, DATE '9999-12-31')
 AND b.start_date < COALESCE(a.end_date, DATE '9999-12-31')
ORDER BY a.user_id, a.sub_id, b.sub_id;

-- Problem 6.8
SELECT sub_id,
       start_date,
       end_date,
       (EXTRACT(YEAR FROM end_date)
          - EXTRACT(YEAR FROM start_date)) * 12
     + (EXTRACT(MONTH FROM end_date)
          - EXTRACT(MONTH FROM start_date))
     - CASE WHEN EXTRACT(DAY FROM end_date)
                 < EXTRACT(DAY FROM start_date)
            THEN 1 ELSE 0 END                 AS full_months,
       end_date - start_date                   AS days
FROM subscriptions
WHERE end_date IS NOT NULL
ORDER BY full_months DESC, sub_id
LIMIT 6;

-- Problem 6.9
SELECT sub_id,
       start_date,
       CAST(DATE_TRUNC('month', start_date)
            + INTERVAL '1 month'
            - INTERVAL '1 day' AS DATE) AS month_end
FROM subscriptions
WHERE start_date > CAST(DATE_TRUNC('month', start_date)
                        + INTERVAL '1 month'
                        - INTERVAL '4 days' AS DATE)
ORDER BY start_date;

-- Problem 6.10
SELECT order_id,
       created_at AS created_utc,
       (created_at AT TIME ZONE 'UTC')
           AT TIME ZONE 'Europe/Berlin' AS created_berlin
FROM orders
WHERE CAST((created_at AT TIME ZONE 'UTC')
           AT TIME ZONE 'Europe/Berlin' AS DATE)
      <> CAST(created_at AS DATE)
ORDER BY created_at;

-- Problem 6.11
WITH days AS (
    SELECT CAST(d AS DATE) AS day
    FROM generate_series(DATE '2025-03-01', DATE '2025-03-20',
                         INTERVAL '1 day') AS g(d)
)
SELECT d.day,
       COUNT(DISTINCT l.user_id)
           FILTER (WHERE l.login_date = d.day) AS dau,
       COUNT(DISTINCT l.user_id)               AS active_7d
FROM days d
LEFT JOIN logins l
       ON l.login_date >  d.day - 7
      AND l.login_date <= d.day
GROUP BY d.day
ORDER BY d.day;

-- Problem 6.12
WITH gaps AS (
    SELECT customer_id,
           order_date - LAG(order_date) OVER (
               PARTITION BY customer_id
               ORDER BY order_date, order_id
           ) AS gap_days
    FROM orders
    WHERE status = 'completed'
)
SELECT customer_id,
       COUNT(*)                 AS orders,
       ROUND(AVG(gap_days), 1)  AS avg_days_between
FROM gaps
GROUP BY customer_id
HAVING COUNT(*) >= 5
ORDER BY avg_days_between, customer_id
LIMIT 5;

-- Problem 7.1
SELECT order_id + 1           AS gap_start,
       next_id - 1            AS gap_end,
       next_id - order_id - 1 AS missing_ids
FROM (
    SELECT order_id,
           LEAD(order_id) OVER (ORDER BY order_id) AS next_id
    FROM orders
) AS t
WHERE next_id - order_id > 1
ORDER BY gap_start;

-- Problem 7.2
SELECT DISTINCT o.customer_id,
       o.order_date AS first_day
FROM orders o
WHERE o.status = 'completed'
  AND EXISTS (
      SELECT 1
      FROM orders n
      WHERE n.customer_id = o.customer_id
        AND n.status = 'completed'
        AND n.order_date = o.order_date + 1
  )
ORDER BY o.customer_id, first_day;

-- Problem 7.3
WITH days AS (
    SELECT CAST(d AS DATE) AS day
    FROM generate_series(DATE '2025-03-01', DATE '2025-03-31',
                         INTERVAL '1 day') AS g(d)
),
calm AS (
    SELECT day,
           day - CAST(ROW_NUMBER() OVER (ORDER BY day)
                      AS INTEGER) AS grp
    FROM days d
    WHERE NOT EXISTS (
        SELECT 1 FROM orders o
        WHERE o.order_date = d.day
          AND o.status = 'cancelled'
    )
)
SELECT MIN(day) AS run_start,
       MAX(day) AS run_end,
       COUNT(*) AS days
FROM calm
GROUP BY grp
ORDER BY days DESC, run_start
LIMIT 3;

-- Problem 7.4
WITH seq AS (
    SELECT customer_id,
           status,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY order_date, order_id)
         - ROW_NUMBER() OVER (PARTITION BY customer_id, status
                              ORDER BY order_date, order_id)
             AS grp
    FROM orders
),
runs AS (
    SELECT customer_id, COUNT(*) AS run_length
    FROM seq
    WHERE status = 'completed'
    GROUP BY customer_id, grp
)
SELECT customer_id,
       MAX(run_length) AS longest_completed_run
FROM runs
GROUP BY customer_id
ORDER BY longest_completed_run DESC, customer_id
LIMIT 5;

-- Problem 7.5
WITH days AS (
    SELECT DISTINCT user_id, login_date
    FROM logins
),
nxt AS (
    SELECT user_id,
           login_date,
           LEAD(login_date) OVER (
               PARTITION BY user_id ORDER BY login_date
           ) AS next_login
    FROM days
)
SELECT user_id,
       login_date              AS last_before_gap,
       next_login,
       next_login - login_date AS gap_days
FROM nxt
WHERE next_login - login_date > 3
ORDER BY gap_days DESC, user_id;

-- Problem 7.6
WITH s AS (
    SELECT user_id,
           start_date,
           COALESCE(end_date, DATE '9999-12-31') AS end_d
    FROM subscriptions
    WHERE user_id IN (SELECT user_id FROM subscriptions
                      GROUP BY user_id HAVING COUNT(*) > 1)
),
flagged AS (
    SELECT *,
           CASE WHEN start_date <= MAX(end_d) OVER (
                    PARTITION BY user_id
                    ORDER BY start_date
                    ROWS BETWEEN UNBOUNDED PRECEDING
                             AND 1 PRECEDING)
                THEN 0 ELSE 1 END AS new_period
    FROM s
),
numbered AS (
    SELECT *,
           SUM(new_period) OVER (
               PARTITION BY user_id
               ORDER BY start_date
               ROWS UNBOUNDED PRECEDING
           ) AS period_id
    FROM flagged
)
SELECT user_id,
       period_id,
       MIN(start_date)                         AS covered_from,
       NULLIF(MAX(end_d), DATE '9999-12-31')   AS covered_until,
       COUNT(*)                                AS subscriptions
FROM numbered
GROUP BY user_id, period_id
ORDER BY user_id, period_id;

-- Problem 7.7
WITH daily AS (
    SELECT order_date, SUM(amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY order_date
),
flagged AS (
    SELECT order_date,
           CASE WHEN revenue > LAG(revenue)
                               OVER (ORDER BY order_date)
                THEN 1 ELSE 0 END AS up
    FROM daily
),
grouped AS (
    SELECT order_date,
           up,
           ROW_NUMBER() OVER (ORDER BY order_date)
         - ROW_NUMBER() OVER (PARTITION BY up
                              ORDER BY order_date) AS grp
    FROM flagged
)
SELECT MIN(order_date) AS first_up_day,
       MAX(order_date) AS last_up_day,
       COUNT(*)        AS days_up
FROM grouped
WHERE up = 1
GROUP BY grp
HAVING COUNT(*) >= 3
ORDER BY first_up_day;

-- Problem 7.8
WITH days AS (
    SELECT CAST(d AS DATE) AS day
    FROM generate_series(DATE '2025-03-01', DATE '2025-03-10',
                         INTERVAL '1 day') AS g(d)
),
br AS (
    SELECT o.order_date, SUM(o.amount) AS revenue
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
      AND c.country = 'BR'
    GROUP BY o.order_date
),
joined AS (
    SELECT d.day,
           b.revenue,
           COUNT(b.revenue) OVER (ORDER BY d.day) AS grp
    FROM days d
    LEFT JOIN br b ON b.order_date = d.day
)
SELECT day,
       revenue                               AS actual,
       MAX(revenue) OVER (PARTITION BY grp)  AS last_known
FROM joined
ORDER BY day;

-- Problem 7.9
WITH numbered AS (
    SELECT customer_id,
           order_date,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY order_date, order_id
           ) AS n,
           MIN(order_date) OVER (PARTITION BY customer_id)
               AS first_date
    FROM orders
    WHERE status = 'completed'
)
SELECT customer_id,
       order_date              AS third_order_date,
       order_date - first_date AS days_from_first
FROM numbered
WHERE n = 3
ORDER BY days_from_first, customer_id
LIMIT 6;

-- Problem 7.10
WITH days AS (
    SELECT DISTINCT user_id, login_date
    FROM logins
),
grouped AS (
    SELECT user_id,
           login_date,
           login_date - CAST(ROW_NUMBER() OVER (
               PARTITION BY user_id ORDER BY login_date
           ) AS INTEGER) AS grp
    FROM days
),
runs AS (
    SELECT user_id,
           CAST(EXTRACT(DAY FROM MIN(login_date)) AS INTEGER)
               AS d1,
           CAST(EXTRACT(DAY FROM MAX(login_date)) AS INTEGER)
               AS d2
    FROM grouped
    GROUP BY user_id, grp
)
SELECT user_id,
       STRING_AGG(CASE WHEN d1 = d2 THEN CAST(d1 AS TEXT)
                       ELSE d1 || ' to ' || d2 END,
                  ', ' ORDER BY d1) AS march_login_days
FROM runs
GROUP BY user_id
ORDER BY user_id;

-- Problem 8.1
SELECT event_name AS step,
       COUNT(DISTINCT user_id) AS users,
       ROUND(100.0 * COUNT(DISTINCT user_id)
             / (SELECT COUNT(*) FROM app_users), 1)
           AS pct_of_signups
FROM app_events
WHERE event_name IN ('signup', 'view_item',
                     'add_to_cart', 'purchase')
GROUP BY event_name
ORDER BY CASE event_name
             WHEN 'signup'      THEN 1
             WHEN 'view_item'   THEN 2
             WHEN 'add_to_cart' THEN 3
             ELSE 4
         END;

-- Problem 8.2
WITH s AS (
    SELECT user_id, MIN(event_time) AS t
    FROM app_events WHERE event_name = 'signup'
    GROUP BY user_id
),
v AS (
    SELECT e.user_id, MIN(e.event_time) AS t
    FROM app_events e
    JOIN s ON s.user_id = e.user_id AND e.event_time > s.t
    WHERE e.event_name = 'view_item'
    GROUP BY e.user_id
),
c AS (
    SELECT e.user_id, MIN(e.event_time) AS t
    FROM app_events e
    JOIN v ON v.user_id = e.user_id AND e.event_time > v.t
    WHERE e.event_name = 'add_to_cart'
    GROUP BY e.user_id
),
p AS (
    SELECT e.user_id, MIN(e.event_time) AS t
    FROM app_events e
    JOIN c ON c.user_id = e.user_id AND e.event_time > c.t
    WHERE e.event_name = 'purchase'
    GROUP BY e.user_id
)
SELECT (SELECT COUNT(*) FROM s) AS signed_up,
       (SELECT COUNT(*) FROM v) AS viewed,
       (SELECT COUNT(*) FROM c) AS carted,
       (SELECT COUNT(*) FROM p) AS purchased;

-- Problem 8.3
WITH buyers AS (
    SELECT DISTINCT user_id
    FROM app_events
    WHERE event_name = 'purchase'
)
SELECT u.channel,
       COUNT(*)          AS users,
       COUNT(b.user_id)  AS buyers,
       ROUND(100.0 * COUNT(b.user_id) / COUNT(*), 1)
           AS conversion_pct
FROM app_users u
LEFT JOIN buyers b ON b.user_id = u.user_id
GROUP BY u.channel
ORDER BY conversion_pct DESC;

-- Problem 8.4
WITH first_buy AS (
    SELECT p.user_id,
           MIN(p.event_time) AS bought_at
    FROM app_events p
    JOIN app_events s ON s.user_id = p.user_id
                     AND s.event_name = 'signup'
                     AND p.event_time > s.event_time
    WHERE p.event_name = 'purchase'
    GROUP BY p.user_id
),
hours AS (
    SELECT u.channel,
           EXTRACT(EPOCH FROM f.bought_at - s.event_time) / 3600
               AS hours_to_buy
    FROM first_buy f
    JOIN app_events s ON s.user_id = f.user_id
                     AND s.event_name = 'signup'
    JOIN app_users u ON u.user_id = f.user_id
)
SELECT channel,
       COUNT(*) AS buyers,
       ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP
                  (ORDER BY hours_to_buy) AS NUMERIC), 1)
           AS median_hours,
       ROUND(CAST(AVG(hours_to_buy) AS NUMERIC), 1) AS avg_hours
FROM hours
GROUP BY channel
ORDER BY channel;

-- Problem 8.5
SELECT CAST(DATE_TRUNC('week', signup_date) AS DATE)
           AS cohort_week,
       COUNT(*) AS signups,
       SUM(COUNT(*)) OVER (
           ORDER BY DATE_TRUNC('week', signup_date)
       ) AS running_signups,
       ROUND(100.0 * COUNT(*) FILTER (WHERE channel = 'ads')
             / COUNT(*), 1) AS ads_share_pct
FROM app_users
GROUP BY DATE_TRUNC('week', signup_date)
ORDER BY cohort_week;

-- Problem 8.6
WITH cohorts AS (
    SELECT user_id,
           signup_date,
           CAST(DATE_TRUNC('week', signup_date) AS DATE)
               AS cohort_week
    FROM app_users
),
activity AS (
    SELECT DISTINCT e.user_id,
           CAST(FLOOR((CAST(e.event_time AS DATE)
                       - c.signup_date) / 7.0) AS INTEGER)
               AS week_n
    FROM app_events e
    JOIN cohorts c ON c.user_id = e.user_id
    WHERE e.event_name = 'session'
)
SELECT c.cohort_week,
       COUNT(DISTINCT c.user_id) AS users,
       ROUND(100.0 * COUNT(DISTINCT a.user_id)
                 FILTER (WHERE a.week_n = 1)
             / COUNT(DISTINCT c.user_id), 1) AS week_1,
       ROUND(100.0 * COUNT(DISTINCT a.user_id)
                 FILTER (WHERE a.week_n = 2)
             / COUNT(DISTINCT c.user_id), 1) AS week_2,
       ROUND(100.0 * COUNT(DISTINCT a.user_id)
                 FILTER (WHERE a.week_n = 4)
             / COUNT(DISTINCT c.user_id), 1) AS week_4
FROM cohorts c
LEFT JOIN activity a ON a.user_id = c.user_id
GROUP BY c.cohort_week
ORDER BY c.cohort_week;

-- Problem 8.7
WITH weeks AS (
    SELECT CAST(g.n AS INTEGER) AS n
    FROM generate_series(1, 4) AS g(n)
),
eligible AS (
    SELECT w.n, u.user_id, u.signup_date
    FROM weeks w
    JOIN app_users u
      ON u.signup_date + 7 * (w.n + 1) <= DATE '2025-03-09'
),
active AS (
    SELECT DISTINCT el.n, el.user_id
    FROM eligible el
    JOIN app_events e
      ON e.user_id = el.user_id
     AND e.event_name = 'session'
     AND CAST(e.event_time AS DATE)
             >= el.signup_date + 7 * el.n
     AND CAST(e.event_time AS DATE)
             <  el.signup_date + 7 * (el.n + 1)
     AND e.event_time < TIMESTAMP '2025-03-09'
)
SELECT el.n AS week_n,
       COUNT(DISTINCT el.user_id) AS eligible_users,
       COUNT(DISTINCT a.user_id)  AS retained,
       ROUND(100.0 * COUNT(DISTINCT a.user_id)
             / COUNT(DISTINCT el.user_id), 1) AS retention_pct
FROM eligible el
LEFT JOIN active a ON a.n = el.n AND a.user_id = el.user_id
GROUP BY el.n
ORDER BY el.n;

-- Problem 8.8
WITH s AS (
    SELECT user_id, event_time AS signed_up_at
    FROM app_events
    WHERE event_name = 'signup'
)
SELECT CAST(DATE_TRUNC('week', u.signup_date) AS DATE)
           AS cohort_week,
       COUNT(*) AS users,
       ROUND(100.0 * COUNT(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM app_events c
           WHERE c.user_id = s.user_id
             AND c.event_name = 'add_to_cart'
             AND c.event_time >  s.signed_up_at
             AND c.event_time <= s.signed_up_at
                                 + INTERVAL '24 hours'
       )) / COUNT(*), 1) AS activated_24h_pct
FROM app_users u
JOIN s ON s.user_id = u.user_id
GROUP BY cohort_week
ORDER BY cohort_week;

-- Problem 8.9
WITH carted AS (
    SELECT DISTINCT user_id
    FROM app_events
    WHERE event_name = 'add_to_cart'
),
per_group AS (
    SELECT a.ab_group,
           COUNT(*)         AS users,
           COUNT(c.user_id) AS carted,
           1.0 * COUNT(c.user_id) / COUNT(*) AS rate
    FROM ab_assignments a
    LEFT JOIN carted c ON c.user_id = a.user_id
    GROUP BY a.ab_group
)
SELECT ab_group,
       users,
       carted,
       ROUND(100 * rate, 1) AS cart_rate_pct,
       ROUND(100 * (rate / FIRST_VALUE(rate)
                               OVER (ORDER BY ab_group)
                    - 1), 1) AS lift_vs_a_pct
FROM per_group
ORDER BY ab_group;

-- Problem 8.10
WITH carted AS (
    SELECT DISTINCT user_id
    FROM app_events
    WHERE event_name = 'add_to_cart'
),
g AS (
    SELECT a.ab_group,
           COUNT(*) AS n,
           1.0 * COUNT(c.user_id) / COUNT(*) AS p
    FROM ab_assignments a
    LEFT JOIN carted c ON c.user_id = a.user_id
    GROUP BY a.ab_group
),
pooled AS (
    SELECT SUM(p * n) / SUM(n) AS p_all FROM g
)
SELECT ROUND(b.p - a.p, 3) AS diff,
       ROUND((b.p - a.p)
             / SQRT(pl.p_all * (1 - pl.p_all)
                    * (1.0 / a.n + 1.0 / b.n)), 2) AS z_score
FROM g a
JOIN g b ON a.ab_group = 'A' AND b.ab_group = 'B'
CROSS JOIN pooled pl;

-- Problem 8.11
WITH weeks_active AS (
    SELECT u.user_id,
           COUNT(DISTINCT CAST(FLOOR(
               (CAST(e.event_time AS DATE) - u.signup_date)
               / 7.0
           ) AS INTEGER)) AS active_weeks
    FROM app_users u
    LEFT JOIN app_events e
           ON e.user_id = u.user_id
          AND e.event_name = 'session'
          AND CAST(e.event_time AS DATE) < u.signup_date + 56
    GROUP BY u.user_id
)
SELECT active_weeks,
       COUNT(*) AS users,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
           AS pct_users
FROM weeks_active
GROUP BY active_weeks
ORDER BY active_weeks;

-- Problem 8.12
SELECT p.user_id,
       p.event_time AS purchase_time,
       (SELECT MIN(s.event_time) FROM app_events s
        WHERE s.user_id = p.user_id
          AND s.event_name = 'signup') AS signup_time
FROM app_events p
WHERE p.event_name = 'purchase'
  AND NOT EXISTS (
      SELECT 1 FROM app_events c
      WHERE c.user_id = p.user_id
        AND c.event_name = 'add_to_cart'
        AND c.event_time < p.event_time
  )
ORDER BY p.user_id, p.event_time;

-- Problem 8.13
WITH weeks AS (
    SELECT CAST(w AS DATE) AS week_start
    FROM generate_series(DATE '2025-01-13', DATE '2025-03-03',
                         INTERVAL '7 days') AS g(w)
),
active AS (
    SELECT DISTINCT user_id,
           CAST(DATE_TRUNC('week', event_time) AS DATE)
               AS week_start
    FROM app_events
),
first_week AS (
    SELECT user_id, MIN(week_start) AS first_week
    FROM active
    GROUP BY user_id
),
labeled AS (
    SELECT w.week_start,
           a.user_id,
           CASE
               WHEN f.first_week = w.week_start THEN 'new'
               WHEN EXISTS (
                   SELECT 1 FROM active p
                   WHERE p.user_id = a.user_id
                     AND p.week_start = w.week_start - 7
               ) THEN 'retained'
               ELSE 'resurrected'
           END AS state
    FROM weeks w
    JOIN active a     ON a.week_start = w.week_start
    JOIN first_week f ON f.user_id = a.user_id
)
SELECT w.week_start,
       COUNT(*) FILTER (WHERE l.state = 'new') AS new_users,
       COUNT(*) FILTER (WHERE l.state = 'retained')
           AS retained,
       COUNT(*) FILTER (WHERE l.state = 'resurrected')
           AS resurrected,
       (SELECT COUNT(*) FROM active p
        WHERE p.week_start = w.week_start - 7
          AND NOT EXISTS (SELECT 1 FROM active c
                          WHERE c.user_id = p.user_id
                            AND c.week_start = w.week_start))
           AS churned
FROM weeks w
LEFT JOIN labeled l ON l.week_start = w.week_start
GROUP BY w.week_start
ORDER BY w.week_start;

-- Problem 8.14
WITH per_user AS (
    SELECT user_id, COUNT(*) AS sessions
    FROM app_events
    WHERE event_name = 'session'
    GROUP BY user_id
),
ranked AS (
    SELECT user_id,
           sessions,
           NTILE(5) OVER (ORDER BY sessions DESC, user_id)
               AS quintile
    FROM per_user
)
SELECT quintile,
       COUNT(*)      AS users,
       SUM(sessions) AS sessions,
       ROUND(100.0 * SUM(sessions)
             / SUM(SUM(sessions)) OVER (), 1) AS pct_of_sessions
FROM ranked
GROUP BY quintile
ORDER BY quintile;

-- Problem 9.1
SELECT customer_id,
       COUNT(DISTINCT country) AS countries,
       STRING_AGG(DISTINCT country, ', ' ORDER BY country)
           AS values_found
FROM sales_flat
GROUP BY customer_id
HAVING COUNT(DISTINCT country) > 1;

-- Problem 9.2
SELECT COUNT(*)                 AS row_count,
       COUNT(DISTINCT order_id) AS distinct_orders,
       COUNT(DISTINCT (order_id, product_name))
           AS distinct_order_product,
       COUNT(DISTINCT (order_id, customer_id))
           AS distinct_order_customer
FROM sales_flat;

-- Problem 9.3
SELECT product_id,
       new_price  AS price,
       changed_on AS valid_from,
       LEAD(changed_on) OVER w                   AS valid_to,
       LEAD(changed_on) OVER w IS NULL           AS is_current
FROM price_changes
WHERE product_id IN (6, 8, 12)
WINDOW w AS (PARTITION BY product_id ORDER BY changed_on)
ORDER BY product_id, valid_from;

-- Problem 9.4
WITH history AS (
    SELECT product_id,
           new_price  AS price,
           changed_on AS valid_from,
           LEAD(changed_on) OVER (
               PARTITION BY product_id ORDER BY changed_on
           ) AS valid_to
    FROM price_changes
)
SELECT oi.product_id,
       COUNT(*) AS lines,
       SUM((oi.unit_price - h.price) * oi.quantity)
           AS charged_minus_valid
FROM order_items oi
JOIN orders o  ON o.order_id = oi.order_id
JOIN history h ON h.product_id = oi.product_id
              AND o.order_date >= h.valid_from
              AND (h.valid_to IS NULL
                   OR o.order_date < h.valid_to)
WHERE o.status = 'completed'
  AND oi.unit_price <> h.price
GROUP BY oi.product_id
ORDER BY oi.product_id;

-- Problem 9.5
WITH history AS (
    SELECT product_id,
           new_price  AS price,
           changed_on AS valid_from,
           LEAD(changed_on) OVER (
               PARTITION BY product_id ORDER BY changed_on
           ) AS valid_to
    FROM price_changes
),
dates AS (
    SELECT DATE '2025-02-01' AS as_of
    UNION ALL SELECT DATE '2025-03-12'
    UNION ALL SELECT DATE '2025-03-31'
)
SELECT d.as_of,
       h.product_id,
       h.price
FROM dates d
JOIN history h
  ON h.valid_from <= d.as_of
 AND (h.valid_to IS NULL OR h.valid_to > d.as_of)
WHERE h.product_id IN (6, 8, 12)
ORDER BY d.as_of, h.product_id;

-- Problem 9.6
WITH item_revenue AS (
    SELECT oi.product_id,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY oi.product_id
)
SELECT COALESCE(pt.tag, '(no tag)') AS tag,
       SUM(r.revenue)               AS revenue,
       ROUND(100.0 * SUM(r.revenue)
             / (SELECT SUM(revenue) FROM item_revenue), 1)
           AS pct_of_total
FROM item_revenue r
LEFT JOIN product_tags pt ON pt.product_id = r.product_id
GROUP BY COALESCE(pt.tag, '(no tag)')
ORDER BY revenue DESC;

-- Problem 9.7
SELECT p.product_id,
       p.name
FROM products p
JOIN product_tags pt ON pt.product_id = p.product_id
WHERE pt.tag IN ('gift', 'bestseller')
GROUP BY p.product_id, p.name
HAVING COUNT(DISTINCT pt.tag) = 2
ORDER BY p.product_id;

-- Problem 9.8
WITH wide AS (
    SELECT product_id,
           MAX(CASE WHEN attr = 'color' THEN value END)
               AS color,
           CAST(MAX(CASE WHEN attr = 'weight_g' THEN value END)
                AS INTEGER) AS weight_g,
           CAST(MAX(CASE WHEN attr = 'warranty_months'
                         THEN value END)
                AS INTEGER) AS warranty_months
    FROM product_attributes
    GROUP BY product_id
)
SELECT w.product_id,
       p.name,
       w.color,
       w.weight_g,
       w.warranty_months
FROM wide w
JOIN products p ON p.product_id = w.product_id
WHERE w.weight_g > 1000
ORDER BY w.weight_g DESC;

-- Problem 9.9
WITH RECURSIVE tree AS (
    SELECT emp_id,
           name,
           title,
           0                    AS depth,
           CAST(name AS TEXT)   AS path
    FROM employees
    WHERE manager_id IS NULL
  UNION ALL
    SELECT e.emp_id,
           e.name,
           e.title,
           t.depth + 1,
           t.path || ' > ' || e.name
    FROM employees e
    JOIN tree t ON e.manager_id = t.emp_id
)
SELECT name, title, depth, path
FROM tree
ORDER BY path;

-- Problem 9.10
WITH target AS (
    SELECT country, SUM(target) AS target
    FROM daily_targets
    GROUP BY country
),
actual AS (
    SELECT c.country, SUM(o.amount) AS actual
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
      AND o.order_date BETWEEN DATE '2025-03-01'
                           AND DATE '2025-03-07'
    GROUP BY c.country
)
SELECT t.country,
       t.target,
       COALESCE(a.actual, 0) AS actual,
       ROUND(100.0 * COALESCE(a.actual, 0) / t.target, 1)
           AS pct_of_target
FROM target t
LEFT JOIN actual a ON a.country = t.country
ORDER BY t.country;

-- Problem 10.1

-- Before
CREATE INDEX ix_created ON big_orders (created_at);
SELECT COUNT(*)    AS orders,
       SUM(amount) AS revenue
FROM big_orders
WHERE CAST(created_at AS DATE) = DATE '2024-06-01';

-- After
CREATE INDEX ix_created ON big_orders (created_at);
SELECT COUNT(*)    AS orders,
       SUM(amount) AS revenue
FROM big_orders
WHERE created_at >= TIMESTAMP '2024-06-01 00:00'
  AND created_at <  TIMESTAMP '2024-06-02 00:00';

-- Problem 10.2

-- Before
CREATE INDEX ix_email ON big_customers (email);
SELECT customer_id, email, country
FROM big_customers
WHERE LOWER(email) = 'user4821@mail.example';

-- After
CREATE INDEX ix_email_lower ON big_customers (LOWER(email));
SELECT customer_id, email, country
FROM big_customers
WHERE LOWER(email) = 'user4821@mail.example';

-- Problem 10.3

-- Before
CREATE INDEX ix_status_created ON big_orders (status, created_at);
SELECT COUNT(*) AS orders
FROM big_orders
WHERE created_at >= TIMESTAMP '2024-06-01'
  AND created_at <  TIMESTAMP '2024-06-08';

-- After
CREATE INDEX ix_created_status ON big_orders (created_at, status);
SELECT COUNT(*) AS orders
FROM big_orders
WHERE created_at >= TIMESTAMP '2024-06-01'
  AND created_at <  TIMESTAMP '2024-06-08';

-- Problem 10.4

-- Before
CREATE INDEX ix_cust ON big_orders (customer_id);
SELECT COUNT(*)    AS orders,
       SUM(amount) AS total
FROM big_orders
WHERE customer_id = 777;

-- After
CREATE INDEX ix_cust_amount ON big_orders (customer_id) INCLUDE (amount);
SELECT COUNT(*)    AS orders,
       SUM(amount) AS total
FROM big_orders
WHERE customer_id = 777;

-- Problem 10.5

-- Before
SET work_mem = '64kB';
SELECT COUNT(*) AS customers_without_december_order
FROM big_customers c
WHERE c.customer_id NOT IN (
    SELECT o.customer_id
    FROM big_orders o
    WHERE o.status = 'completed'
      AND o.created_at >= TIMESTAMP '2024-12-01'
);

-- After
SET work_mem = '64kB';
SELECT COUNT(*) AS customers_without_december_order
FROM big_customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM big_orders o
    WHERE o.customer_id = c.customer_id
      AND o.status = 'completed'
      AND o.created_at >= TIMESTAMP '2024-12-01'
);

-- Problem 10.6

-- Before
SELECT COUNT(*) AS orders_above_own_avg
FROM big_orders o
WHERE o.customer_id <= 500
  AND o.amount > (
      SELECT AVG(i.amount)
      FROM big_orders i
      WHERE i.customer_id = o.customer_id
  );

-- After
SELECT COUNT(*) AS orders_above_own_avg
FROM (
    SELECT amount,
           AVG(amount) OVER (PARTITION BY customer_id) AS own_avg
    FROM big_orders
    WHERE customer_id <= 500
) AS t
WHERE amount > own_avg;

-- Problem 10.7

-- Before
SELECT order_id, customer_id, amount
FROM big_orders
ORDER BY order_id
LIMIT 5 OFFSET 150000;

-- After
SELECT order_id, customer_id, amount
FROM big_orders
WHERE order_id > 150000
ORDER BY order_id
LIMIT 5;

-- Problem 10.8

-- Before
SELECT c.customer_id, c.email, c.country,
       SUM(o.amount) AS revenue
FROM big_orders o
JOIN big_customers c ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.email, c.country
ORDER BY revenue DESC, c.customer_id
LIMIT 10;

-- After
WITH top_customers AS (
    SELECT customer_id, SUM(amount) AS revenue
    FROM big_orders
    WHERE status = 'completed'
    GROUP BY customer_id
    ORDER BY revenue DESC, customer_id
    LIMIT 10
)
SELECT c.customer_id, c.email, c.country,
       t.revenue
FROM top_customers t
JOIN big_customers c ON c.customer_id = t.customer_id
ORDER BY t.revenue DESC, c.customer_id;

-- Problem 10.9

-- Before
CREATE INDEX ix_status ON big_orders (status);
SELECT COUNT(*) AS pending_last_week
FROM big_orders
WHERE status = 'pending'
  AND created_at >= TIMESTAMP '2024-12-24';

-- After
CREATE INDEX ix_pending ON big_orders (created_at) WHERE status = 'pending';
SELECT COUNT(*) AS pending_last_week
FROM big_orders
WHERE status = 'pending'
  AND created_at >= TIMESTAMP '2024-12-24';

-- Problem 10.10

-- Before
SELECT COUNT(*) AS orders
FROM (
    SELECT order_id FROM big_orders
    WHERE created_at <  TIMESTAMP '2024-02-01'
  UNION
    SELECT order_id FROM big_orders
    WHERE created_at >= TIMESTAMP '2024-02-01'
      AND created_at <  TIMESTAMP '2024-03-01'
) AS t;

-- After
SELECT COUNT(*) AS orders
FROM (
    SELECT order_id FROM big_orders
    WHERE created_at <  TIMESTAMP '2024-02-01'
  UNION ALL
    SELECT order_id FROM big_orders
    WHERE created_at >= TIMESTAMP '2024-02-01'
      AND created_at <  TIMESTAMP '2024-03-01'
) AS t;

-- Problem 11.1
SELECT c.country,
       COUNT(*)              AS orders,
       SUM(o.amount)         AS revenue,
       ROUND(AVG(o.amount), 1) AS avg_order,
       ROUND(100.0 * SUM(o.amount)
             / SUM(SUM(o.amount)) OVER (), 1) AS pct_of_revenue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.country
ORDER BY revenue DESC;

-- Problem 11.2
WITH halves AS (
    SELECT oi.product_id,
           SUM(oi.quantity * oi.unit_price)
               FILTER (WHERE o.order_date <= DATE '2025-03-15')
               AS first_half,
           SUM(oi.quantity * oi.unit_price)
               FILTER (WHERE o.order_date >  DATE '2025-03-15')
               AS second_half
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY oi.product_id
)
SELECT p.name,
       COALESCE(h.first_half, 0)  AS first_half,
       COALESCE(h.second_half, 0) AS second_half,
       ROUND(100.0 * (COALESCE(h.second_half, 0) - h.first_half)
             / h.first_half, 1) AS change_pct
FROM halves h
JOIN products p ON p.product_id = h.product_id
WHERE COALESCE(h.second_half, 0) < h.first_half
ORDER BY change_pct, p.name
LIMIT 5;

-- Problem 11.3
WITH ranked AS (
    SELECT customer_id,
           order_date,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY order_date, order_id
           ) AS n
    FROM orders
    WHERE status = 'completed'
),
per_customer AS (
    SELECT customer_id,
           MAX(CASE WHEN n = 1 THEN order_date END) AS first_date,
           MAX(CASE WHEN n = 2 THEN order_date END) AS second_date
    FROM ranked
    GROUP BY customer_id
)
SELECT COUNT(*)            AS buyers,
       COUNT(second_date)  AS repeat_buyers,
       ROUND(100.0 * COUNT(second_date) / COUNT(*), 1)
           AS pct_repeat,
       ROUND(AVG(second_date - first_date), 1)
           AS avg_days_to_second
FROM per_customer;

-- Problem 11.4
WITH revenue AS (
    SELECT customer_id, SUM(amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT ref.name                      AS referrer,
       COUNT(*)                      AS referred,
       COUNT(rv.customer_id)         AS referred_buyers,
       COALESCE(SUM(rv.revenue), 0)  AS referred_revenue
FROM customers c
JOIN customers ref ON ref.customer_id = c.referred_by
LEFT JOIN revenue rv ON rv.customer_id = c.customer_id
GROUP BY ref.customer_id, ref.name
ORDER BY referred_revenue DESC, ref.customer_id;

-- Problem 11.5
SELECT city,
       COUNT(*) AS requests,
       ROUND(100.0 * COUNT(*) FILTER (
                 WHERE status = 'cancelled_by_rider')
             / COUNT(*), 1) AS rider_cancel_pct,
       ROUND(100.0 * COUNT(*) FILTER (
                 WHERE status = 'cancelled_by_driver')
             / COUNT(*), 1) AS driver_cancel_pct,
       ROUND(100.0 * COUNT(*) FILTER (
                 WHERE status <> 'completed')
             / COUNT(*), 1) AS total_cancel_pct
FROM trips
GROUP BY city
ORDER BY total_cancel_pct DESC;

-- Problem 11.6
WITH first_trip AS (
    SELECT driver_id,
           MIN(CAST(requested_at AS DATE)) AS first_day
    FROM trips
    WHERE status = 'completed'
    GROUP BY driver_id
)
SELECT d.city,
       COUNT(*)            AS drivers,
       COUNT(f.driver_id)  AS activated,
       ROUND(AVG(f.first_day - d.signup_date), 1)
           AS avg_days_to_first_trip
FROM drivers d
LEFT JOIN first_trip f ON f.driver_id = d.driver_id
GROUP BY d.city
ORDER BY d.city;

-- Problem 11.7
WITH by_hour AS (
    SELECT city,
           EXTRACT(HOUR FROM requested_at) AS hour,
           COUNT(*) AS requests
    FROM trips
    GROUP BY city, EXTRACT(HOUR FROM requested_at)
),
ranked AS (
    SELECT city, hour, requests,
           RANK() OVER (
               PARTITION BY city ORDER BY requests DESC
           ) AS rnk
    FROM by_hour
)
SELECT city,
       CAST(hour AS INTEGER) AS hour,
       requests
FROM ranked
WHERE rnk = 1
ORDER BY city, hour;

-- Problem 11.8
WITH rated AS (
    SELECT driver_id,
           rating,
           ROW_NUMBER() OVER (
               PARTITION BY driver_id
               ORDER BY requested_at DESC
           ) AS recent
    FROM trips
    WHERE status = 'completed'
      AND rating IS NOT NULL
)
SELECT driver_id,
       COUNT(*)              AS rated_trips_used,
       ROUND(AVG(rating), 2) AS avg_last_5
FROM rated
WHERE recent <= 5
GROUP BY driver_id
HAVING AVG(rating) < 4.0
ORDER BY avg_last_5, driver_id;

-- Problem 11.9
WITH net AS (
    SELECT order_id,
           SUM(CASE WHEN status = 'succeeded' THEN amount
                    WHEN status = 'refunded'  THEN -amount
                    ELSE 0 END) AS net_paid
    FROM payments
    GROUP BY order_id
)
SELECT o.order_id,
       o.status,
       o.amount,
       COALESCE(n.net_paid, 0) AS net_paid,
       CASE WHEN o.status = 'completed'
            THEN 'completed, not paid'
            ELSE 'cancelled, money kept' END AS problem
FROM orders o
LEFT JOIN net n ON n.order_id = o.order_id
WHERE (o.status = 'completed' AND COALESCE(n.net_paid, 0) = 0)
   OR (o.status = 'cancelled' AND COALESCE(n.net_paid, 0) > 0)
ORDER BY o.order_id;

-- Problem 11.10
WITH charges AS (
    SELECT payment_id,
           order_id,
           paid_at,
           amount,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY paid_at, payment_id
           ) AS n,
           FIRST_VALUE(paid_at) OVER (
               PARTITION BY order_id
               ORDER BY paid_at, payment_id
           ) AS first_paid_at
    FROM payments
    WHERE status = 'succeeded'
)
SELECT order_id,
       payment_id AS duplicate_payment,
       amount,
       CAST(EXTRACT(EPOCH FROM paid_at - first_paid_at) / 60
            AS INTEGER) AS minutes_after_first
FROM charges
WHERE n > 1
ORDER BY order_id, payment_id;

-- Problem 11.11
WITH net AS (
    SELECT order_id,
           SUM(CASE WHEN status = 'succeeded' THEN amount
                    WHEN status = 'refunded'  THEN -amount
                    ELSE 0 END) AS net_paid
    FROM payments
    GROUP BY order_id
),
checked AS (
    SELECT o.order_id,
           o.amount,
           COALESCE(n.net_paid, 0) AS net_paid,
           CASE
               WHEN COALESCE(n.net_paid, 0) = 0        THEN 'unpaid'
               WHEN COALESCE(n.net_paid, 0) < o.amount THEN 'underpaid'
               WHEN COALESCE(n.net_paid, 0) > o.amount THEN 'overpaid'
               ELSE 'paid'
           END AS result
    FROM orders o
    LEFT JOIN net n ON n.order_id = o.order_id
    WHERE o.status = 'completed'
)
SELECT result,
       COUNT(*)                   AS orders,
       SUM(net_paid - amount)     AS paid_minus_due
FROM checked
GROUP BY result
ORDER BY orders DESC, result;

-- Problem 11.12
WITH days AS (
    SELECT CAST(d AS DATE) AS day
    FROM generate_series(DATE '2025-03-01', DATE '2025-03-07',
                         INTERVAL '1 day') AS g(d)
),
booked AS (
    SELECT order_date AS day, SUM(amount) AS booked
    FROM orders
    WHERE status = 'completed'
    GROUP BY order_date
),
cash AS (
    SELECT CAST(paid_at AS DATE) AS day,
           SUM(CASE WHEN status = 'succeeded' THEN amount
                    WHEN status = 'refunded'  THEN -amount
                    ELSE 0 END) AS cash_in
    FROM payments
    GROUP BY CAST(paid_at AS DATE)
)
SELECT d.day,
       COALESCE(b.booked, 0)  AS booked,
       COALESCE(c.cash_in, 0) AS cash_in,
       SUM(COALESCE(c.cash_in, 0) - COALESCE(b.booked, 0))
           OVER (ORDER BY d.day) AS running_gap
FROM days d
LEFT JOIN booked b ON b.day = d.day
LEFT JOIN cash c   ON c.day = d.day
ORDER BY d.day;

