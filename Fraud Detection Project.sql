-- 1. Database select karna
USE bank;

-- 2. Basic check (Optional)
SELECT * FROM transactions;

-- 3. Detecting Recursive Fraudulent Transactions
WITH RECURSIVE fraud_chain AS (
    -- Anchor Member: Shuruat un transactions se jo fraud hain
    SELECT 
        nameOrig AS initial_account,
        nameDest AS next_account,
        step,
        amount
    FROM 
        transactions
    WHERE 
        isFraud = 1 
        AND type = 'TRANSFER'

    UNION ALL

    -- Recursive Member: Agle accounts ko link karna jo fraud chain ka hissa hain
    SELECT fc.initial_account, t.nameDest AS next_account, t.step,t.amount
    FROM fraud_chain fc
    JOIN transactions t ON fc.next_account = t.nameOrig 
        AND fc.step < t.step
    WHERE t.isFraud = 1 
        AND t.type = 'TRANSFER'
)
-- 4. Final Result dekhna
SELECT * FROM fraud_chain;
-- Q2- Uses a cte to calculate the rolling sum of 
-- fraudlent Transactions for each account  over the last  5 steps
SELECT 
    nameOrig,
    step,
    isFraud,
    SUM(isFraud) OVER (
        PARTITION BY nameOrig
        ORDER BY step
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS fraud_rolling_sum
FROM transactions
LIMIT 1000;


-- 3. Complex Fraud Detection Using Multiple CTEs
-- Question: Use multiple CTEs to identify accounts with suspicious activity, 
-- including large transfers, consecutive transactions without balance change, and flagged transactions.

WITH large_transfer AS (
    SELECT nameOrig, step, amount 
    FROM transactions 
    WHERE type = 'TRANSFER' AND amount > 500000
),
no_balance_change AS (
    SELECT nameOrig, step, oldbalanceOrg, newbalanceOrig 
    FROM transactions 
    WHERE oldbalanceOrg = newbalanceOrig
),
flagged_transactions AS (
    SELECT nameOrig, step, isFlaggedFraud
    FROM transactions 
    WHERE isFlaggedFraud = 1
)

SELECT DISTINCT lt.nameOrig
FROM large_transfer AS lt
JOIN no_balance_change nbc 
    ON lt.nameOrig = nbc.nameOrig 
    AND lt.step = nbc.step
JOIN flagged_transactions ft 
    ON lt.nameOrig = ft.nameOrig 
    AND lt.step = ft.step;

-- 4. Query to check if the computed new_updated_Balance matches newbalanceDest

WITH CTE AS (
    SELECT 
        nameOrig, 
        nameDest,
        amount, 
        oldbalanceDest, 
        newbalanceDest, 
        (amount + oldbalanceDest) AS new_updated_Balance
    FROM transactions
)
SELECT * FROM CTE 
WHERE new_updated_Balance = newbalanceDest;
