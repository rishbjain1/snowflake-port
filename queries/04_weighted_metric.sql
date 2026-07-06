-- Weighted vs unweighted averages — the aggregation-bias check.
-- Pattern: any "average position/score/rate" reported per group must be
-- weighted by volume, or small-volume groups distort the headline.
-- Here: average events-per-active-day by country, both ways, with the delta.

WITH per_user AS (
  SELECT
    u.country,
    e.user_id,
    COUNT(*)                          AS events,
    COUNT(DISTINCT e.event_date)      AS active_days,
    COUNT(*) / NULLIF(COUNT(DISTINCT e.event_date), 0) AS events_per_day
  FROM activity_events e
  JOIN users u USING (user_id)
  GROUP BY 1, 2
)
SELECT
  country,
  ROUND(AVG(events_per_day), 2)                                   AS unweighted_avg,
  ROUND(SUM(events) / NULLIF(SUM(active_days), 0), 2)             AS weighted_avg,
  ROUND(ABS(AVG(events_per_day)
        - SUM(events) / NULLIF(SUM(active_days), 0)), 2)          AS bias_delta
FROM per_user
GROUP BY 1
ORDER BY bias_delta DESC;
