USE CT5_Data_Mart;
GO

-- Data Cleansing Steps
SELECT
	CONVERT(date, week_date, 3) AS week_date,	-- Convert the week_date to a DATE format
	DATEPART(ISO_WEEK, CONVERT(date, week_date, 3)) AS week_number,
	DATEPART(MONTH, CONVERT(date, week_date, 3)) AS month_number,
	DATEPART(YEAR, CONVERT(date, week_date, 3)) AS calendar_year,
	region,
	platform,
	segment,
	CASE 
		WHEN segment = 'null' THEN 'unknown'
		WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
		WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
		WHEN RIGHT(segment, 1) = '3' OR RIGHT(segment, 1) = '4' THEN 'Retirees'
		END AS age_band,
	CASE
		WHEN segment = 'null' THEN 'unknown'
		WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
		WHEN LEFT(segment, 1) = 'F' THEN 'Families'
		END AS demographic,
	transactions,
	ROUND(CAST(sales AS FLOAT)/transactions, 2) AS avg_transaction,
	sales
INTO 
	dbo.clean_weekly_sales
FROM
	weekly_sales;
