-- Weekly cohort retention matrix.
-- Athena→Snowflake diffs used here:
--   date_trunc('week', x)        → DATE_TRUNC('week', x)   (same, but returns DATE not timestamp)
--   date_diff('day', a, b)       → DATEDIFF('day', a, b)
--   approx_distinct(x)           → APPROX_COUNT_DISTINCT(x)
--   no MSCK REPAIR / partitions  → micro-partitions are automatic

WITH cohorts AS (
  SELECT
    user_id,
    DATE_TRUNC('week', signup_date) AS cohort_week
  FROM users
),
activity AS (
  SELECT DISTINCT
    e.user_id,
    FLOOR(DATEDIFF('day', c.cohort_week, e.event_date) / 7) AS week_n
  FROM activity_events e
  JOIN cohorts c USING (user_id)
  WHERE e.event_date >= c.cohort_week
)
SELECT
  c.cohort_week,
  APPROX_COUNT_DISTINCT(c.user_id)                                        AS cohort_size,
  ROUND(COUNT(DISTINCT IFF(a.week_n = 1, a.user_id, NULL))
        / NULLIF(APPROX_COUNT_DISTINCT(c.user_id), 0) * 100, 1)           AS w1_pct,
  ROUND(COUNT(DISTINCT IFF(a.week_n = 2, a.user_id, NULL))
        / NULLIF(APPROX_COUNT_DISTINCT(c.user_id), 0) * 100, 1)           AS w2_pct,
  ROUND(COUNT(DISTINCT IFF(a.week_n = 4, a.user_id, NULL))
        / NULLIF(APPROX_COUNT_DISTINCT(c.user_id), 0) * 100, 1)           AS w4_pct
FROM cohorts c
LEFT JOIN activity a USING (user_id)
GROUP BY 1
ORDER BY 1;
