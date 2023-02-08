USE CT5_Data_Mart;
GO

-- Questions
-- 1. What day of the week is used for each week_date value?
SELECT
	DISTINCT DATENAME(WEEKDAY, week_date) AS week_day
FROM
	clean_weekly_sales;

-- 2. What range of week numbers are missing from the dataset?
DROP TABLE IF EXISTS week_number;
CREATE TABLE week_number (
	"number" INTEGER
);

DECLARE @i INTEGER = 1;
WHILE @i <= 52
	BEGIN
		INSERT INTO week_number ("number") VALUES (@i);
		SET @i = @i + 1;
	END;

SELECT
	DISTINCT a.number
FROM
	week_number AS a
	LEFT OUTER JOIN clean_weekly_sales AS b ON a.number = b.week_number
WHERE
	b.week_number IS NULL;

-- 3. How many total transactions were there for each year in the dataset?
SELECT
	calendar_year,
	SUM(transactions) AS total_transactions
FROM
	clean_weekly_sales
GROUP BY
	calendar_year
ORDER BY
	calendar_year;

-- 4. What is the total sales for each region for each month?
SELECT
	region, month_number,
	SUM(CAST(sales AS BIGINT)) AS total_sales
FROM
	clean_weekly_sales
GROUP BY
	region, month_number
ORDER BY
	region, month_number;

-- 5. What is the total count of transactions for each platform
SELECT
	platform,
	SUM(transactions) AS total_transactions
FROM
	clean_weekly_sales
GROUP BY
	platform
ORDER BY
	platform;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
WITH cte AS (
	SELECT
		calendar_year, month_number, platform,
		SUM(CAST(sales AS BIGINT)) AS sales
	FROM
		clean_weekly_sales
	GROUP BY
		calendar_year, month_number, platform
)

SELECT
	calendar_year, month_number,
	ROUND(100 * CAST(MAX(CASE WHEN platform = 'Retail' THEN sales ELSE NULL END) AS FLOAT) /
			SUM(sales), 2) AS retail_percentage,
	ROUND(100 * CAST(MAX(CASE WHEN platform = 'Shopify' THEN sales ELSE NULL END) AS FLOAT) /
			SUM(sales), 2) AS shopify_percentage
FROM
	cte
GROUP BY
	calendar_year, month_number;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH cte AS (
	SELECT
		calendar_year, demographic,
		SUM(CAST(sales AS BIGINT)) AS sales
	FROM
		clean_weekly_sales
	GROUP BY
		calendar_year, demographic
)

SELECT
	calendar_year,
	ROUND(100 * CAST(MAX(CASE WHEN demographic = 'unknown' THEN sales ELSE NULL END) AS FLOAT) /
			SUM(sales), 2) AS unknown_percentage,
	ROUND(100 * CAST(MAX(CASE WHEN demographic = 'Families' THEN sales ELSE NULL END) AS FLOAT) /
			SUM(sales), 2) AS families_percentage,
	ROUND(100 * CAST(MAX(CASE WHEN demographic = 'Couples' THEN sales ELSE NULL END) AS FLOAT) /
			SUM(sales), 2) AS couples_percentage
FROM
	cte
GROUP BY
	calendar_year;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
WITH cte AS (
	SELECT
		age_band, demographic,
		SUM(CAST(sales AS BIGINT)) AS sales
	FROM
		clean_weekly_sales
	WHERE
		platform = 'Retail'
	GROUP BY
		age_band, demographic
		
)

SELECT
	*,
	100 * CAST(sales AS FLOAT) / 
		(SELECT SUM(CAST(sales AS BIGINT)) FROM clean_weekly_sales WHERE platform = 'Retail') AS percentage
FROM
	cte
ORDER BY
	percentage DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
