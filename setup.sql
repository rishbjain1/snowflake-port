-- snowflake-port — setup: warehouse, database, synthetic event data.
-- Runs on a free Snowflake trial as-is. All data is generated; nothing real.

CREATE WAREHOUSE IF NOT EXISTS demo_wh
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60          -- suspend after 60s idle: trial credits last
  AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS analytics_demo;
CREATE SCHEMA IF NOT EXISTS analytics_demo.events;
USE WAREHOUSE demo_wh;
USE SCHEMA analytics_demo.events;

-- Users: 50k synthetic signups over ~180 days across 4 channels.
CREATE OR REPLACE TABLE users AS
SELECT
  seq4()                                                   AS user_id,
  DATEADD('day', -UNIFORM(0, 180, RANDOM()), CURRENT_DATE) AS signup_date,
  ARRAY_CONSTRUCT('organic','paid_social','referral','search')[
    UNIFORM(0, 3, RANDOM())]::STRING                       AS channel,
  ARRAY_CONSTRUCT('US','IN','BR','DE','JP')[
    UNIFORM(0, 4, RANDOM())]::STRING                       AS country
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

-- Events: ~600k activity rows, activity decaying with account age.
CREATE OR REPLACE TABLE activity_events AS
SELECT
  u.user_id,
  DATEADD('day', UNIFORM(0, 60, RANDOM()), u.signup_date)  AS event_date,
  ARRAY_CONSTRUCT('session_start','watch_together','invite_sent',
                  'upgrade_view')[UNIFORM(0, 3, RANDOM())]::STRING AS event_name
FROM users u,
     TABLE(GENERATOR(ROWCOUNT => 12))
WHERE UNIFORM(0, 100, RANDOM()) < 80;   -- drop ~20% to vary per-user volume

-- Subscriptions: ~8% of users start a trial; ~35% of trials convert, with lag.
CREATE OR REPLACE TABLE subscriptions AS
SELECT
  user_id,
  DATEADD('day', UNIFORM(0, 14, RANDOM()), signup_date)    AS trial_start,
  IFF(UNIFORM(0, 100, RANDOM()) < 35,
      DATEADD('day', UNIFORM(1, 21, RANDOM()),
              DATEADD('day', UNIFORM(0, 14, RANDOM()), signup_date)),
      NULL)                                                AS first_payment_date
FROM users
WHERE UNIFORM(0, 100, RANDOM()) < 8;
