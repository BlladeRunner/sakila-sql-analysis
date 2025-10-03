/* Sakila bootstrap (SQLite): helper view + indexes */

-- Sakila bootstrap: helper view for analytics (SQLite)

DROP VIEW IF EXISTS v_rental_detail;

CREATE VIEW v_rental_detail AS
WITH pay AS (
  SELECT rental_id, SUM(amount) AS revenue
  FROM payment
  GROUP BY rental_id
)
SELECT
  r.rental_id,
  r.rental_date,
  date(r.rental_date)                          AS rental_day,
  strftime('%Y-%m', r.rental_date)             AS ym,
  r.return_date,
  CAST(julianday(r.return_date) - julianday(r.rental_date) AS INT) AS rental_days,

  -- Клиент и география
  r.customer_id,
  c.first_name || ' ' || c.last_name          AS customer_name,
  c.store_id                                   AS customer_store_id,
  a.address                                    AS customer_address,
  ci.city                                      AS city,
  co.country                                   AS country,

  -- Сотрудник, оформивший прокат
  r.staff_id,
  st.first_name || ' ' || st.last_name        AS staff_name,

  -- Магазин / экземпляр / фильм
  i.inventory_id,
  s.store_id                                   AS store_id,
  f.film_id,
  f.title,
  f.length,
  f.rental_duration,
  f.rental_rate,
  f.replacement_cost,
  cat.category_id,
  cat.name                                     AS category,

  -- Деньги
  COALESCE(pay.revenue, 0.0)                   AS revenue
FROM rental            r
JOIN inventory         i   ON i.inventory_id   = r.inventory_id
JOIN film              f   ON f.film_id        = i.film_id
LEFT JOIN film_category fc  ON fc.film_id      = f.film_id
LEFT JOIN category     cat ON cat.category_id  = fc.category_id
JOIN customer          c   ON c.customer_id    = r.customer_id
JOIN address           a   ON a.address_id     = c.address_id
JOIN city              ci  ON ci.city_id       = a.city_id
JOIN country           co  ON co.country_id    = ci.country_id
JOIN staff             st  ON st.staff_id      = r.staff_id
JOIN store             s   ON s.store_id       = i.store_id
LEFT JOIN pay          pay ON pay.rental_id    = r.rental_id
;

-- Полезные индексы (если их нет)
CREATE INDEX IF NOT EXISTS idx_rental_date     ON rental(rental_date);
CREATE INDEX IF NOT EXISTS idx_payment_rental  ON payment(rental_id);
CREATE INDEX IF NOT EXISTS idx_inventory_store ON inventory(store_id);
CREATE INDEX IF NOT EXISTS idx_inventory_film  ON inventory(film_id);
