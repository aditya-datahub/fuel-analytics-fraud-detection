-- ============================================================
--  FUEL STATION ANALYTICS
--  Database: fuel_analytics
-- ============================================================

-- ── Drop tables if they exist (clean slate) ─────────────────
DROP TABLE IF EXISTS sensor_data;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS stations;


-- ── Create Tables ────────────────────────────────────────────
CREATE TABLE transactions (
    transaction_id        INT,
    customer_id           INT,
    station_id            INT,
    txn_timestamp         TIMESTAMP,
    fuel_requested_liters FLOAT,
    fuel_dispensed_liters FLOAT,
    wait_time_minutes     FLOAT,
    amount_paid           FLOAT,
    fuel_diff             FLOAT,
    fraud_flag            BOOLEAN,
    customer_type         VARCHAR(20),
    repeat_customer       BOOLEAN,
    hour                  INT,
    day                   DATE
);

CREATE TABLE customers (
    customer_id   INT,
    customer_type VARCHAR(20),
    signup_date   DATE
);

CREATE TABLE stations (
    station_id       INT,
    city             VARCHAR(50),
    num_pumps        INT,
    staff_count      INT,
    quality_score    FLOAT,
    fraud_prone_flag INT
);

CREATE TABLE sensor_data (
    transaction_id INT,
    expected_fuel  FLOAT,
    actual_fuel    FLOAT
);


-- ── Verify tables created ────────────────────────────────────
SELECT 'transactions' AS tbl, COUNT(*) FROM transactions
UNION ALL
SELECT 'customers',            COUNT(*) FROM customers
UNION ALL
SELECT 'stations',             COUNT(*) FROM stations
UNION ALL
SELECT 'sensor_data',          COUNT(*) FROM sensor_data;


-- ── Preview each table ───────────────────────────────────────
SELECT * FROM transactions  LIMIT 10;
SELECT * FROM customers     LIMIT 10;
SELECT * FROM stations      LIMIT 10;
SELECT * FROM sensor_data   LIMIT 10;


-- ════════════════════════════════════════════════════════════
--  H1 — FRAUD & REVENUE
-- ════════════════════════════════════════════════════════════
 
-- Q1. Overall Fraud Rate
-- "What % of all transactions are fraudulent?"
SELECT 
    ROUND(AVG(fraud_flag::int)::numeric, 3) AS fraud_rate
FROM transactions;
 
 
-- Q2. Revenue Loss Due to Fraud
SELECT 
    ROUND(SUM(GREATEST(fuel_diff, 0))::numeric * 100, 2) AS revenue_lost_rs,
    ROUND(SUM(amount_paid)::numeric, 2)                   AS total_collected_rs
FROM transactions;
 
 
-- Q3. Top 5 Fraud Stations
-- "Which stations are most suspicious + causing most loss?"
SELECT 
    t.station_id,
    s.city,
    COUNT(*)                                                AS total_txns,
    ROUND(AVG(t.fraud_flag::int)::numeric, 3)              AS fraud_rate,
    ROUND(SUM(GREATEST(t.fuel_diff, 0))::numeric * 100, 2) AS revenue_lost_rs
FROM transactions t
JOIN stations s ON t.station_id = s.station_id
GROUP BY t.station_id, s.city
ORDER BY fraud_rate DESC
LIMIT 5;
 
 
-- ════════════════════════════════════════════════════════════
--  H2 — WAIT TIME & RETENTION
-- ════════════════════════════════════════════════════════════
 
-- Q4. Peak Hour Congestion
-- "When is wait time highest and how does it affect retention?"
SELECT 
    hour,
    ROUND(AVG(wait_time_minutes)::numeric, 2)    AS avg_wait_min,
    ROUND(AVG(repeat_customer::int)::numeric, 3) AS repeat_rate
FROM transactions
GROUP BY hour
ORDER BY hour;
 
 
-- Q5. Wait Category vs Retention
-- "Does longer waiting reduce repeat visits?"
SELECT 
    CASE 
        WHEN wait_time_minutes < 5  THEN '1. Low (<5 min)'
        WHEN wait_time_minutes < 10 THEN '2. Medium (5-10 min)'
        ELSE                             '3. High (>10 min)'
    END                                              AS wait_category,
    ROUND(AVG(repeat_customer::int)::numeric, 3)    AS repeat_rate,
    COUNT(*)                                         AS txn_count
FROM transactions
GROUP BY wait_category
ORDER BY wait_category;
 
 
-- ════════════════════════════════════════════════════════════
--  H3 — TRUST & CHURN
-- ════════════════════════════════════════════════════════════
 
-- Q6. Fraud Transaction vs Customer Retention
-- "Do customers who experience fraud come back less?"
SELECT 
    CASE WHEN fraud_flag THEN 'Fraud Txn' 
         ELSE 'Clean Txn' END                        AS txn_type,
    COUNT(*)                                         AS total_txns,
    ROUND(AVG(repeat_customer::int)::numeric, 3)    AS repeat_rate
FROM transactions
GROUP BY fraud_flag;
 
 
-- Q7. Fraud vs Clean Station — Retention
-- "Are customers less loyal to fraud-prone stations?"
SELECT 
    CASE WHEN s.fraud_prone_flag = 1 
         THEN 'Fraud Station' 
         ELSE 'Clean Station' END                    AS station_type,
    ROUND(AVG(t.repeat_customer::int)::numeric, 3)  AS repeat_rate,
    COUNT(*)                                         AS txn_count
FROM transactions t
JOIN stations s ON t.station_id = s.station_id
GROUP BY s.fraud_prone_flag
ORDER BY s.fraud_prone_flag;
 
 
-- ════════════════════════════════════════════════════════════
--  BONUS — ADVANCED SENSOR-BASED FRAUD DETECTION
-- ════════════════════════════════════════════════════════════
 
-- Q8. Sensor-Based Fraud Detection
-- "Which transactions show real physical under-dispensing?"
SELECT 
    sd.transaction_id,
    t.station_id,
    s.city,
    sd.expected_fuel,
    sd.actual_fuel,
    ROUND((sd.expected_fuel - sd.actual_fuel)::numeric, 3) AS gap_liters
FROM sensor_data sd
JOIN transactions t ON sd.transaction_id = t.transaction_id
JOIN stations s     ON t.station_id = s.station_id
WHERE sd.expected_fuel - sd.actual_fuel > 0.5
ORDER BY gap_liters DESC
LIMIT 10;

-- ============================================================
--  FUEL STATION ANALYTICS — FINAL 8 QUERIES
--  Database : fuel_analytics
--  Hypotheses: H1 Fraud | H2 Wait Time | H3 Trust & Churn
-- ============================================================


-- ════════════════════════════════════════════════════════════
--  H1 — FRAUD & REVENUE
-- ════════════════════════════════════════════════════════════

-- Q1. Overall Fraud Rate
-- "What % of all transactions are fraudulent?"
SELECT 
    ROUND(AVG(fraud_flag::int)::numeric, 3) AS fraud_rate
FROM transactions;


-- Q2. Revenue Loss Due to Fraud
-- "How much money is being lost to under-dispensing?"
SELECT 
    ROUND(SUM(GREATEST(fuel_diff, 0))::numeric * 100, 2) AS revenue_lost_rs,
    ROUND(SUM(amount_paid)::numeric, 2)                   AS total_collected_rs
FROM transactions;


-- Q3. Top 5 Fraud Stations
-- "Which stations are most suspicious + causing most loss?"
SELECT 
    t.station_id,
    s.city,
    COUNT(*)                                              AS total_txns,
    ROUND(AVG(t.fraud_flag::int)::numeric, 3)            AS fraud_rate,
    ROUND(SUM(GREATEST(t.fuel_diff, 0))::numeric * 100, 2) AS revenue_lost_rs
FROM transactions t
JOIN stations s ON t.station_id = s.station_id
GROUP BY t.station_id, s.city
ORDER BY fraud_rate DESC
LIMIT 5;


-- ════════════════════════════════════════════════════════════
--  H2 — WAIT TIME & RETENTION
-- ════════════════════════════════════════════════════════════

-- Q4. Peak Hour Congestion
-- "When is wait time highest and how does it affect retention?"
SELECT 
    hour,
    ROUND(AVG(wait_time_minutes)::numeric, 2)    AS avg_wait_min,
    ROUND(AVG(repeat_customer::int)::numeric, 3) AS repeat_rate
FROM transactions
GROUP BY hour
ORDER BY hour;


-- Q5. Wait Category vs Retention
-- "Does longer waiting reduce repeat visits?"
SELECT 
    CASE 
        WHEN wait_time_minutes < 5  THEN '1. Low (<5 min)'
        WHEN wait_time_minutes < 10 THEN '2. Medium (5-10 min)'
        ELSE                             '3. High (>10 min)'
    END                                                  AS wait_category,
    ROUND(AVG(repeat_customer::int)::numeric, 3)        AS repeat_rate,
    COUNT(*)                                             AS txn_count
FROM transactions
GROUP BY wait_category
ORDER BY wait_category;


-- ════════════════════════════════════════════════════════════
--  H3 — TRUST & CHURN
-- ════════════════════════════════════════════════════════════

-- Q6. Fraud Transaction vs Customer Retention
-- "Do customers who experience fraud come back less?"
SELECT 
    CASE WHEN fraud_flag THEN 'Fraud Txn' 
         ELSE 'Clean Txn' END                            AS txn_type,
    COUNT(*)                                             AS total_txns,
    ROUND(AVG(repeat_customer::int)::numeric, 3)        AS repeat_rate
FROM transactions
GROUP BY fraud_flag;


-- Q7. Fraud vs Clean Station — Retention
-- "Are customers less loyal to fraud-prone stations?"
SELECT 
    CASE WHEN s.fraud_prone_flag = 1 
         THEN 'Fraud Station' 
         ELSE 'Clean Station' END                        AS station_type,
    ROUND(AVG(t.repeat_customer::int)::numeric, 3)      AS repeat_rate,
    COUNT(*)                                             AS txn_count
FROM transactions t
JOIN stations s ON t.station_id = s.station_id
GROUP BY s.fraud_prone_flag
ORDER BY s.fraud_prone_flag;


-- ════════════════════════════════════════════════════════════
--  BONUS — ADVANCED SENSOR-BASED FRAUD DETECTION
-- ════════════════════════════════════════════════════════════

-- Q8. Sensor-Based Fraud Detection
-- "Which transactions show real physical under-dispensing?"
SELECT 
    sd.transaction_id,
    t.station_id,
    s.city,
    sd.expected_fuel,
    sd.actual_fuel,
    ROUND((sd.expected_fuel - sd.actual_fuel)::numeric, 3) AS gap_liters
FROM sensor_data sd
JOIN transactions t ON sd.transaction_id = t.transaction_id
JOIN stations s     ON t.station_id = s.station_id
WHERE sd.expected_fuel - sd.actual_fuel > 0.5
ORDER BY gap_liters DESC
LIMIT 10;



-- ════════════════════════════════════════════════════════════
--  BONUS 2 — EXTRA INSIGHTS
-- ════════════════════════════════════════════════════════════

-- Q9. City-wise Fraud Comparison
-- "Which city has highest fraud — Mumbai, Delhi or Bangalore?"
SELECT 
    s.city,
    COUNT(*)                                                AS total_txns,
    ROUND(AVG(t.fraud_flag::int)::numeric, 3)              AS fraud_rate,
    ROUND(AVG(t.repeat_customer::int)::numeric, 3)         AS repeat_rate,
    ROUND(SUM(GREATEST(t.fuel_diff, 0))::numeric * 100, 2) AS revenue_lost_rs
FROM transactions t
JOIN stations s ON t.station_id = s.station_id
GROUP BY s.city
ORDER BY fraud_rate DESC;


-- Q10. Customer Type vs Fraud Exposure
-- "Are frequent customers more affected by fraud than occasional ones?"
SELECT 
    t.customer_type,
    COUNT(*)                                                AS total_txns,
    ROUND(AVG(t.fraud_flag::int)::numeric, 3)              AS fraud_rate,
    ROUND(AVG(t.repeat_customer::int)::numeric, 3)         AS repeat_rate,
    ROUND(AVG(t.wait_time_minutes)::numeric, 2)            AS avg_wait_min
FROM transactions t
GROUP BY t.customer_type
ORDER BY fraud_rate DESC;
