-- ============================================================
--  FUELGUARD - DATA QUALITY & RECONCILIATION CHECKS
--  Database : fuel_analytics (PostgreSQL)
--  Tables   : transactions, customers, stations, sensor_data
--  Run AFTER loading the 4 CSVs. Every check returns an
--  issue_count; 0 = PASS. Section 8 gives one summary table.
-- ============================================================


-- ── 1. ROW-COUNT RECONCILIATION ─────────────────────────────
-- Expected: transactions = sensor_data (one sensor reading per txn)
SELECT 'transactions' AS tbl, COUNT(*) AS row_count FROM transactions
UNION ALL SELECT 'sensor_data', COUNT(*) FROM sensor_data
UNION ALL SELECT 'customers',   COUNT(*) FROM customers
UNION ALL SELECT 'stations',    COUNT(*) FROM stations;


-- ── 2. NULL CHECKS (key and measure columns) ────────────────
SELECT
    COUNT(*) FILTER (WHERE transaction_id        IS NULL) AS null_txn_id,
    COUNT(*) FILTER (WHERE customer_id           IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE station_id            IS NULL) AS null_station_id,
    COUNT(*) FILTER (WHERE txn_timestamp         IS NULL) AS null_timestamp,
    COUNT(*) FILTER (WHERE fuel_requested_liters IS NULL) AS null_requested,
    COUNT(*) FILTER (WHERE fuel_dispensed_liters IS NULL) AS null_dispensed,
    COUNT(*) FILTER (WHERE amount_paid           IS NULL) AS null_amount,
    COUNT(*) FILTER (WHERE fraud_flag            IS NULL) AS null_fraud_flag
FROM transactions;


-- ── 3. DUPLICATE KEY CHECKS ─────────────────────────────────
-- Any rows returned = duplicate keys (empty result = PASS)
SELECT 'transactions' AS tbl, transaction_id AS key_value, COUNT(*) AS n
FROM transactions GROUP BY transaction_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'customers', customer_id, COUNT(*)
FROM customers GROUP BY customer_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'stations', station_id, COUNT(*)
FROM stations GROUP BY station_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'sensor_data', transaction_id, COUNT(*)
FROM sensor_data GROUP BY transaction_id HAVING COUNT(*) > 1;


-- ── 4. ORPHAN KEY CHECKS (referential integrity) ────────────
-- 4a. Transactions pointing to a missing customer
SELECT t.transaction_id, t.customer_id
FROM transactions t
LEFT JOIN customers c ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 4b. Transactions pointing to a missing station
SELECT t.transaction_id, t.station_id
FROM transactions t
LEFT JOIN stations s ON t.station_id = s.station_id
WHERE s.station_id IS NULL;

-- 4c. Sensor readings with no matching transaction
SELECT sd.transaction_id
FROM sensor_data sd
LEFT JOIN transactions t ON sd.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL;

-- 4d. Transactions with no sensor reading
SELECT t.transaction_id
FROM transactions t
LEFT JOIN sensor_data sd ON t.transaction_id = sd.transaction_id
WHERE sd.transaction_id IS NULL;


-- ── 5. RANGE / VALIDITY CHECKS ──────────────────────────────
SELECT
    COUNT(*) FILTER (WHERE fuel_requested_liters <= 0) AS bad_requested,
    COUNT(*) FILTER (WHERE fuel_dispensed_liters <= 0) AS bad_dispensed,
    COUNT(*) FILTER (WHERE wait_time_minutes < 0)      AS negative_wait,
    COUNT(*) FILTER (WHERE amount_paid <= 0)           AS bad_amount,
    COUNT(*) FILTER (WHERE hour NOT BETWEEN 0 AND 23)  AS bad_hour,
    COUNT(*) FILTER (WHERE customer_type NOT IN ('frequent', 'occasional')) AS bad_customer_type
FROM transactions;

SELECT
    COUNT(*) FILTER (WHERE num_pumps <= 0)                    AS bad_pumps,
    COUNT(*) FILTER (WHERE staff_count <= 0)                  AS bad_staff,
    COUNT(*) FILTER (WHERE quality_score NOT BETWEEN 0 AND 5) AS bad_quality_score,
    COUNT(*) FILTER (WHERE fraud_prone_flag NOT IN (0, 1))    AS bad_fraud_prone_flag
FROM stations;


-- ── 6. CROSS-TABLE & INTERNAL CONSISTENCY ───────────────────
-- 6a. fuel_diff must equal requested - dispensed (rounding tolerance 0.011)
SELECT COUNT(*) AS fuel_diff_mismatch
FROM transactions
WHERE ABS(fuel_diff - (fuel_requested_liters - fuel_dispensed_liters)) > 0.011;

-- 6b. sensor expected_fuel must equal the fuel requested in transactions
SELECT COUNT(*) AS expected_vs_requested_mismatch
FROM transactions t
JOIN sensor_data sd ON t.transaction_id = sd.transaction_id
WHERE ABS(sd.expected_fuel - t.fuel_requested_liters) > 0.011;

-- 6c. customer_type in transactions must match the customers table
SELECT COUNT(*) AS customer_type_mismatch
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
WHERE t.customer_type <> c.customer_type;

-- 6d. hour and day columns must match txn_timestamp
SELECT COUNT(*) AS hour_day_mismatch
FROM transactions
WHERE hour <> EXTRACT(HOUR FROM txn_timestamp)
   OR day  <> txn_timestamp::date;

-- 6e. Transactions dated BEFORE the customer signed up
SELECT COUNT(*) AS txn_before_signup
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
WHERE t.txn_timestamp::date < c.signup_date;


-- ── 7. FRAUD-FLAG vs SENSOR RECONCILIATION (informational) ──
-- Shows how much of the fraud flag is backed by a physical sensor gap
SELECT
    COUNT(*) FILTER (WHERE t.fraud_flag)                                   AS flagged_txns,
    COUNT(*) FILTER (WHERE t.fraud_flag
                       AND sd.expected_fuel - sd.actual_fuel > 0.5)        AS flagged_with_sensor_gap,
    COUNT(*) FILTER (WHERE NOT t.fraud_flag
                       AND sd.expected_fuel - sd.actual_fuel > 0.5)        AS unflagged_with_sensor_gap
FROM transactions t
JOIN sensor_data sd ON t.transaction_id = sd.transaction_id;


-- ── 8. SUMMARY: ALL CHECKS IN ONE TABLE ─────────────────────
SELECT check_name, issue_count,
       CASE WHEN issue_count = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (
    SELECT 'Row count: transactions vs sensor_data' AS check_name,
           ABS((SELECT COUNT(*) FROM transactions) - (SELECT COUNT(*) FROM sensor_data)) AS issue_count
    UNION ALL SELECT 'Nulls in transactions (key/measure columns)',
           COUNT(*) FROM transactions
           WHERE transaction_id IS NULL OR customer_id IS NULL OR station_id IS NULL
              OR txn_timestamp IS NULL OR fuel_requested_liters IS NULL
              OR fuel_dispensed_liters IS NULL OR amount_paid IS NULL OR fraud_flag IS NULL
    UNION ALL SELECT 'Duplicate transaction_id',
           (SELECT COUNT(*) FROM transactions) - (SELECT COUNT(DISTINCT transaction_id) FROM transactions)
    UNION ALL SELECT 'Duplicate customer_id',
           (SELECT COUNT(*) FROM customers) - (SELECT COUNT(DISTINCT customer_id) FROM customers)
    UNION ALL SELECT 'Duplicate station_id',
           (SELECT COUNT(*) FROM stations) - (SELECT COUNT(DISTINCT station_id) FROM stations)
    UNION ALL SELECT 'Duplicate sensor_data transaction_id',
           (SELECT COUNT(*) FROM sensor_data) - (SELECT COUNT(DISTINCT transaction_id) FROM sensor_data)
    UNION ALL SELECT 'Orphan: transactions -> customers',
           COUNT(*) FROM transactions t LEFT JOIN customers c ON t.customer_id = c.customer_id
           WHERE c.customer_id IS NULL
    UNION ALL SELECT 'Orphan: transactions -> stations',
           COUNT(*) FROM transactions t LEFT JOIN stations s ON t.station_id = s.station_id
           WHERE s.station_id IS NULL
    UNION ALL SELECT 'Orphan: sensor_data -> transactions',
           COUNT(*) FROM sensor_data sd LEFT JOIN transactions t ON sd.transaction_id = t.transaction_id
           WHERE t.transaction_id IS NULL
    UNION ALL SELECT 'Orphan: transactions without sensor reading',
           COUNT(*) FROM transactions t LEFT JOIN sensor_data sd ON t.transaction_id = sd.transaction_id
           WHERE sd.transaction_id IS NULL
    UNION ALL SELECT 'Invalid values (negative / zero / out of range)',
           COUNT(*) FROM transactions
           WHERE fuel_requested_liters <= 0 OR fuel_dispensed_liters <= 0
              OR wait_time_minutes < 0 OR amount_paid <= 0 OR hour NOT BETWEEN 0 AND 23
    UNION ALL SELECT 'fuel_diff <> requested - dispensed',
           COUNT(*) FROM transactions
           WHERE ABS(fuel_diff - (fuel_requested_liters - fuel_dispensed_liters)) > 0.011
    UNION ALL SELECT 'Sensor expected_fuel <> fuel_requested',
           COUNT(*) FROM transactions t JOIN sensor_data sd ON t.transaction_id = sd.transaction_id
           WHERE ABS(sd.expected_fuel - t.fuel_requested_liters) > 0.011
    UNION ALL SELECT 'customer_type mismatch (transactions vs customers)',
           COUNT(*) FROM transactions t JOIN customers c ON t.customer_id = c.customer_id
           WHERE t.customer_type <> c.customer_type
    UNION ALL SELECT 'hour/day <> txn_timestamp',
           COUNT(*) FROM transactions
           WHERE hour <> EXTRACT(HOUR FROM txn_timestamp) OR day <> txn_timestamp::date
    UNION ALL SELECT 'Transaction dated before customer signup_date',
           COUNT(*) FROM transactions t JOIN customers c ON t.customer_id = c.customer_id
           WHERE t.txn_timestamp::date < c.signup_date
) checks
ORDER BY status ASC, check_name;
