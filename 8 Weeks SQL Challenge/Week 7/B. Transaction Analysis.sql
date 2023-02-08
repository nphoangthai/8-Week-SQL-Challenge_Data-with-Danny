USE CT7_Balanced_Tree_Clothing_Co;
GO

-- 1. How many unique transactions were there?
SELECT
	COUNT(DISTINCT txn_id) AS #unique_transactions
FROM
	sales;

-- 2. What is the average unique products purchased in each transaction?
SELECT
	AVG(a.#unique_products) AS avg_unique_products_per_transaction
FROM (
	SELECT
		txn_id,
		COUNT(DISTINCT prod_id) AS #unique_products
	FROM
		sales
	GROUP BY
		txn_id
) AS a;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

-- 4. What is the average discount value per transaction?
SELECT
	AVG(a.overall_discounts) AS avg_discounts_per_transaction
FROM (
	SELECT
		txn_id,
		SUM(qty*price*discount/100) AS overall_discounts
	FROM
		sales
	GROUP BY
		txn_id
) AS a;

-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT
	member,
	100*CAST(COUNT(DISTINCT txn_id) AS FLOAT)/(SELECT COUNT(DISTINCT txn_id) FROM sales) AS #transactions
FROM
	sales
GROUP BY
	member;

-- 6. What is the average revenue for member transactions and non-member transactions?
SELECT
	member,
	AVG(a.price_per_transaction) AS avg_price_per_transaction
FROM (
	SELECT	
		txn_id, member,
		SUM(qty*price) AS price_per_transaction
	FROM
		sales
	GROUP BY
		txn_id, member
) AS a
GROUP BY
	member;