USE CT5_Data_Mart;
GO

-- Setup
-- Before changes table
DROP TABLE IF EXISTS before_changes;
SELECT
	*
INTO 
	before_changes
FROM
	clean_weekly_sales
WHERE
	week_date < '2020-06-15';

-- After changes table
DROP TABLE IF EXISTS after_changes;
SELECT
	*
INTO
	after_changes
FROM
	clean_weekly_sales
WHERE 
	week_date >= '2020-06-15';

-- Questions
-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
-- Before change
WITH changes_1 AS (
	SELECT
		SUM(CAST(CASE WHEN week_date < '2020-06-15' THEN sales END AS BIGINT)) AS before_changes_sales,
		SUM(CAST(CASE WHEN week_date >= '2020-06-15' THEN sales END AS BIGINT)) AS after_changes_sales	
	FROM
		clean_weekly_sales
	WHERE
		week_date BETWEEN DATEADD(WEEK, -4, '2020-06-15') AND DATEADD(WEEK, 4, '2020-06-15')
)

SELECT 
  before_changes_sales, 
  after_changes_sales, 
  after_changes_sales - before_changes_sales AS variance, 
  ROUND(100 * CAST((after_changes_sales - before_changes_sales) AS FLOAT) / before_changes_sales,2) AS percentage
FROM 
	changes_1;

-- 2. What about the entire 12 weeks before and after?
WITH changes_1 AS (
	SELECT
		SUM(CAST(CASE WHEN week_date < '2020-06-15' THEN sales END AS BIGINT)) AS before_changes_sales,
		SUM(CAST(CASE WHEN week_date >= '2020-06-15' THEN sales END AS BIGINT)) AS after_changes_sales	
	FROM
		clean_weekly_sales
	WHERE
		week_date BETWEEN DATEADD(WEEK, -12, '2020-06-15') AND DATEADD(WEEK, 12, '2020-06-15')
)

SELECT 
  before_changes_sales, 
  after_changes_sales, 
  after_changes_sales - before_changes_sales AS variance, 
  ROUND(100 * CAST((after_changes_sales - before_changes_sales) AS FLOAT) / before_changes_sales,2) AS percentage
FROM 
	changes_1;

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
-- 4 weeks period
WITH changes_1 AS (
	SELECT
		calendar_year,
		SUM(CAST(CASE WHEN week_date < CONCAT(CAST(calendar_year AS VARCHAR), '-06-15') THEN sales END AS BIGINT)) AS before_changes_sales,
		SUM(CAST(CASE WHEN week_date >= CONCAT(CAST(calendar_year AS VARCHAR), '-06-15') THEN sales END AS BIGINT)) AS after_changes_sales	
	FROM
		clean_weekly_sales
	WHERE
		week_date BETWEEN DATEADD(WEEK, -4, CONCAT(CAST(calendar_year AS VARCHAR), '-06-15')) AND DATEADD(WEEK, 4, CONCAT(CAST(calendar_year AS VARCHAR), '-06-15'))
	GROUP BY
		calendar_year
)

SELECT
	calendar_year,
	before_changes_sales, 
	after_changes_sales, 
	after_changes_sales - before_changes_sales AS variance, 
	ROUND(100 * CAST((after_changes_sales - before_changes_sales) AS FLOAT) / before_changes_sales,2) AS percentage
FROM 
	changes_1;

-- 12 weeks period
WITH changes_1 AS (
	SELECT
		calendar_year,
		SUM(CAST(CASE WHEN week_date < CONCAT(CAST(calendar_year AS VARCHAR), '-06-15') THEN sales END AS BIGINT)) AS before_changes_sales,
		SUM(CAST(CASE WHEN week_date >= CONCAT(CAST(calendar_year AS VARCHAR), '-06-15') THEN sales END AS BIGINT)) AS after_changes_sales	
	FROM
		clean_weekly_sales
	WHERE
		week_date BETWEEN DATEADD(WEEK, -12, CONCAT(CAST(calendar_year AS VARCHAR), '-06-15')) AND DATEADD(WEEK, 12, CONCAT(CAST(calendar_year AS VARCHAR), '-06-15'))
	GROUP BY
		calendar_year
)

SELECT
	calendar_year,
	before_changes_sales, 
	after_changes_sales, 
	after_changes_sales - before_changes_sales AS variance, 
	ROUND(100 * CAST((after_changes_sales - before_changes_sales) AS FLOAT) / before_changes_sales,2) AS percentage
FROM 
	changes_1;