/* =========================
   Sakila SQL Analytics (SQLite)
   Base view: v_rental_detail (created by bootstrap_sakila.sql)
   ========================= */

/* 0) Sanity */
PRAGMA table_info('v_rental_detail');
SELECT COUNT(*) AS rows FROM v_rental_detail;
SELECT MIN(rental_day) AS min_d, MAX(rental_day) AS max_d FROM v_rental_detail;

/* 1) Monthly revenue + MoM */
WITH m AS (
  SELECT ym, ROUND(SUM(revenue), 2) AS revenue
  FROM v_rental_detail
  GROUP BY ym
)
SELECT
  ym,
  revenue,
  ROUND((revenue - LAG(revenue) OVER (ORDER BY ym))
        / NULLIF(LAG(revenue) OVER (ORDER BY ym), 0), 4) AS mom
FROM m
ORDER BY ym;

/* 2) Top customers (orders, revenue, AOV) */
WITH orders AS (
  SELECT rental_id, customer_id, customer_name, SUM(revenue) AS order_value
  FROM v_rental_detail
  GROUP BY rental_id, customer_id, customer_name
)
SELECT
  customer_id, customer_name,
  COUNT(*)                       AS orders,
  ROUND(SUM(order_value), 2)     AS revenue,
  ROUND(AVG(order_value), 2)     AS aov
FROM orders
GROUP BY customer_id, customer_name
ORDER BY revenue DESC
LIMIT 20;

/* 3) Category revenue share */
WITH c AS (
  SELECT category, SUM(revenue) AS revenue
  FROM v_rental_detail
  GROUP BY category
),
t AS (SELECT SUM(revenue) AS total FROM c)
SELECT
  category,
  ROUND(revenue, 2)                   AS revenue,
  ROUND(revenue * 1.0 / t.total, 4)   AS share
FROM c, t
ORDER BY revenue DESC;

/* 4) Store performance */
SELECT
  store_id,
  COUNT(DISTINCT rental_id)         AS rentals,
  ROUND(SUM(revenue), 2)            AS revenue,
  ROUND(AVG(rental_days), 2)        AS avg_rental_days
FROM v_rental_detail
GROUP BY store_id
ORDER BY revenue DESC;

/* 5) Staff performance (who handled rentals) */
SELECT
  staff_id, staff_name,
  COUNT(DISTINCT rental_id)         AS rentals,
  ROUND(SUM(revenue), 2)            AS revenue
FROM v_rental_detail
GROUP BY staff_id, staff_name
ORDER BY revenue DESC;

/* 6) Top films (by revenue and rentals) */
SELECT
  film_id, title, category,
  COUNT(DISTINCT rental_id)         AS rentals,
  ROUND(SUM(revenue), 2)            AS revenue
FROM v_rental_detail
GROUP BY film_id, title, category
ORDER BY revenue DESC, rentals DESC
LIMIT 20;

/* 7) Country → revenue breakdown */
SELECT
  country,
  COUNT(DISTINCT customer_id)       AS customers,
  COUNT(DISTINCT rental_id)         AS rentals,
  ROUND(SUM(revenue), 2)            AS revenue,
  ROUND(SUM(revenue)*1.0/COUNT(DISTINCT customer_id), 2) AS rev_per_customer
FROM v_rental_detail
GROUP BY country
ORDER BY revenue DESC;

/* 8) Shipping-like KPI: late rate vs film rental_duration */
SELECT
  ROUND(AVG(rental_days), 2) AS avg_days,
  ROUND(SUM(CASE WHEN rental_days > rental_duration THEN 1 ELSE 0 END)*1.0
        / COUNT(*), 4)       AS late_rate
FROM v_rental_detail
WHERE rental_days IS NOT NULL;

/* 9) RFM (1..5) by customer */
WITH base AS (
  SELECT
    customer_id, customer_name,
    MAX(rental_day)                      AS last_day,
    COUNT(DISTINCT rental_id)            AS freq,
    SUM(revenue)                         AS monetary
  FROM v_rental_detail
  GROUP BY customer_id, customer_name
),
dated AS (
  SELECT *,
         CAST(julianday((SELECT MAX(rental_day) FROM v_rental_detail)) - julianday(last_day) AS INT) AS recency_days
  FROM base
),
scores AS (
  SELECT *,
         (6 - NTILE(5) OVER (ORDER BY recency_days ASC)) AS R,
         NTILE(5) OVER (ORDER BY freq DESC)              AS F,
         NTILE(5) OVER (ORDER BY monetary DESC)          AS M
  FROM dated
)
SELECT
  customer_id, customer_name, recency_days, freq,
  ROUND(monetary, 2) AS monetary,
  R||F||M            AS RFM,
  (R+F+M)            AS RFM_score
FROM scores
ORDER BY RFM_score DESC, monetary DESC
LIMIT 20;

/* 10) Cohort: next-month retention from first rental */
WITH firsts AS (
  SELECT customer_id, strftime('%Y-%m', MIN(rental_day)) AS cohort
  FROM v_rental_detail
  GROUP BY customer_id
),
sizes AS (SELECT cohort, COUNT(*) AS cohort_size FROM firsts GROUP BY cohort),
ret AS (
  SELECT f.cohort, COUNT(DISTINCT v.customer_id) AS kept
  FROM firsts f
  JOIN v_rental_detail v
    ON v.customer_id = f.customer_id
   AND strftime('%Y-%m', v.rental_day) = strftime('%Y-%m', date(f.cohort||'-01','+1 month'))
  GROUP BY f.cohort
)
SELECT s.cohort, s.cohort_size,
       COALESCE(r.kept, 0) AS retained_next_month,
       ROUND(COALESCE(r.kept,0)*1.0/s.cohort_size, 3) AS retention_rate
FROM sizes s
LEFT JOIN ret r USING(cohort)
ORDER BY cohort;

/* 11) Heatmap grid: category × month revenue */
SELECT
  ym, category,
  ROUND(SUM(revenue), 2) AS revenue
FROM v_rental_detail
GROUP BY ym, category
ORDER BY ym, revenue DESC;

/* 12) ABC analysis of films by revenue (A≈80%) */
WITH prod AS (
  SELECT film_id, title, SUM(revenue) AS revenue
  FROM v_rental_detail
  GROUP BY film_id, title
),
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn,
         SUM(revenue) OVER ()                      AS total_rev,
         SUM(revenue) OVER (ORDER BY revenue DESC) AS cum_rev
  FROM prod
)
SELECT
  film_id, title,
  ROUND(revenue, 2)                 AS revenue,
  ROUND(cum_rev*1.0/total_rev, 4)   AS cum_share,
  CASE
    WHEN cum_rev/total_rev <= 0.80 THEN 'A'
    WHEN cum_rev/total_rev <= 0.95 THEN 'B'
    ELSE 'C'
  END AS abc_class
FROM ranked
ORDER BY revenue DESC;

/* 13) “Basket” pairs: films rented together */
WITH pairs AS (
  SELECT a.film_id AS f1, b.film_id AS f2
  FROM v_rental_detail a
  JOIN v_rental_detail b
    ON a.rental_id = b.rental_id AND a.film_id < b.film_id
)
SELECT
  f1, f.title  AS film1,
  f2, g.title  AS film2,
  COUNT(*)     AS together_count
FROM pairs
JOIN film f ON f.film_id = f1
JOIN film g ON g.film_id = f2
GROUP BY f1, f2
ORDER BY together_count DESC
LIMIT 20;

/* 14) Utilization: rentals per film length bucket */
WITH buckets AS (
  SELECT
    CASE
      WHEN length <  60 THEN '<60m'
      WHEN length <  90 THEN '60–89m'
      WHEN length < 120 THEN '90–119m'
      WHEN length < 150 THEN '120–149m'
      ELSE '>=150m'
    END AS len_bucket,
    rental_id
  FROM v_rental_detail
)
SELECT len_bucket,
       COUNT(DISTINCT rental_id) AS rentals
FROM buckets
GROUP BY len_bucket
ORDER BY rentals DESC;

/* 15) City × month activity (rentals) */
SELECT
  ym, city,
  COUNT(DISTINCT rental_id) AS rentals
FROM v_rental_detail
GROUP BY ym, city
ORDER BY ym, rentals DESC;
