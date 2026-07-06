-- Cumulative conversion maturity curve: what % of a cohort's eventual
-- conversions have landed by day N after trial start. This is the
-- "measurement lag" view — read a cohort's day-7 number against the curve
-- instead of comparing immature cohorts to mature ones.
-- Athena→Snowflake: sequences via UNNEST(sequence(...)) → GENERATOR + seq4().

WITH days AS (
  SELECT seq4() AS day_n
  FROM TABLE(GENERATOR(ROWCOUNT => 22))          -- 0..21
),
converted AS (
  SELECT
    user_id,
    DATEDIFF('day', trial_start, first_payment_date) AS days_to_convert
  FROM subscriptions
  WHERE first_payment_date IS NOT NULL
)
SELECT
  d.day_n,
  COUNT(IFF(c.days_to_convert <= d.day_n, 1, NULL))              AS conversions_by_day,
  ROUND(COUNT(IFF(c.days_to_convert <= d.day_n, 1, NULL))
        / NULLIF((SELECT COUNT(*) FROM converted), 0) * 100, 1)  AS pct_of_eventual
FROM days d
CROSS JOIN converted c
GROUP BY 1
ORDER BY 1;
