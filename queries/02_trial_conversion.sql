-- Trial→paid conversion by signup channel, denominator-disciplined:
-- the denominator is trials *old enough to have converted* (21-day window),
-- so recent cohorts don't drag the rate down (measurement-lag correction).
-- Athena→Snowflake: current_date - interval '21' day → DATEADD('day', -21, CURRENT_DATE)

WITH mature_trials AS (
  SELECT
    s.user_id,
    u.channel,
    s.trial_start,
    s.first_payment_date
  FROM subscriptions s
  JOIN users u USING (user_id)
  WHERE s.trial_start <= DATEADD('day', -21, CURRENT_DATE)
)
SELECT
  channel,
  COUNT(*)                                                      AS mature_trials,
  COUNT(first_payment_date)                                     AS conversions,
  ROUND(COUNT(first_payment_date) / NULLIF(COUNT(*), 0) * 100, 1) AS cvr_pct,
  ROUND(AVG(DATEDIFF('day', trial_start, first_payment_date)), 1) AS avg_days_to_convert
FROM mature_trials
GROUP BY 1
ORDER BY cvr_pct DESC;
