# snowflake-port — Athena/Presto analytics patterns on Snowflake

Analytics query patterns I use daily on AWS Athena, ported to Snowflake
dialect and runnable end-to-end on a free trial. All data is synthetic
(generated in `setup.sql`) — the point is the patterns and the dialect,
not the numbers.

## Run it (free trial, ~5 min)

```
1. signup.snowflake.com  (30-day free trial, no card)
2. open a worksheet, paste setup.sql, run all      → warehouse + 3 tables
3. run queries/01..04 in order
```

`AUTO_SUSPEND = 60` keeps the XSMALL warehouse from eating trial credits.

## The queries

| # | Pattern | The analytical point |
|---|---|---|
| 01 | Weekly cohort retention matrix | cohort discipline; `APPROX_COUNT_DISTINCT` for big-cardinality counts |
| 02 | Trial→paid conversion by channel | denominator discipline — only trials old enough to convert count (measurement-lag correction) |
| 03 | Conversion maturity curve | cumulative % of eventual conversions by day N — how to read immature cohorts honestly |
| 04 | Weighted vs unweighted averages | aggregation bias made visible: both computed side by side with the delta |

## Athena → Snowflake dialect cheat sheet (what actually changed)

| Athena / Presto | Snowflake |
|---|---|
| `date_diff('day', a, b)` | `DATEDIFF('day', a, b)` |
| `date_add('day', n, d)` / `d + interval 'n' day` | `DATEADD('day', n, d)` |
| `approx_distinct(x)` | `APPROX_COUNT_DISTINCT(x)` |
| `UNNEST(sequence(0, 21))` | `TABLE(GENERATOR(ROWCOUNT => 22))` + `seq4()` |
| `if(cond, a, b)` | `IFF(cond, a, b)` |
| partition projection / `MSCK REPAIR` | nothing — micro-partitions are automatic |
| partition pruning by `dt` column | clustering keys (only if needed; not at this scale) |
| pay per TB scanned | pay per warehouse-second → `AUTO_SUSPEND` matters |

The last two rows are the real mental-model shift: Athena performance work is
*layout* work (partitions, projection), Snowflake performance work is
*compute* work (warehouse sizing, suspend policy, pruning via clustering).

## Status

**Ran live on a Snowflake trial (2026-07-07).** Setup built the warehouse +
3 synthetic tables (50,000 users / 475,466 events / 3,960 subscriptions).
Verified live results:

- **01 cohort retention** — 27 weekly cohorts with W1/W2/W4 retention
  (first cohort 68.1% / 69.4% / 70.1%), 360 ms on an XSMALL warehouse.
- **04 weighted vs unweighted** — per-country averages with the bias delta
  computed side by side (5 countries), 1.1 s.

Queries also parse clean as Snowflake dialect (sqlglot-checked offline).
