-- Use Database
USE CT4_Data_Bank;
GO

-- Questions
-- 1. What is the unique count and total amount for each transaction type?
SELECT
	COUNT(DISTINCT txn_type) AS #transaction_types
FROM
	customer_transactions;

SELECT
	txn_type,
	COUNT(*) AS total_count
FROM
	customer_transactions
GROUP BY
	txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH cte AS (
	SELECT
		customer_id,
		COUNT(*) AS #deposits,
		AVG(txn_amount) AS avg_amounts
	FROM
		customer_transactions
	WHERE
		txn_type = 'deposit'
	GROUP BY
		customer_id
)

SELECT
	AVG(#deposits) AS avg_deposits,
	AVG(avg_amounts) AS avg__amounts
FROM
	cte;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_transactions AS (
  SELECT 
    customer_id, 
    DATEPART(MONTH, txn_date) AS month_,
    SUM(CASE WHEN txn_type = 'deposit' THEN 0 ELSE 1 END) AS deposit_count,
    SUM(CASE WHEN txn_type = 'purchase' THEN 0 ELSE 1 END) AS purchase_count,
    SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
  FROM customer_transactions
  GROUP BY customer_id, DATEPART(MONTH, txn_date)
 )

SELECT
  month_,
  COUNT(DISTINCT customer_id) AS customer_count
FROM monthly_transactions
WHERE deposit_count >= 2 
  AND (purchase_count > 1 OR withdrawal_count > 1)
GROUP BY month_
ORDER BY month_;

-- 4. What is the closing balance for each customer at the end of the month?


-- 5. What is the percentage of customers who increase their closing balance by more than 5%?