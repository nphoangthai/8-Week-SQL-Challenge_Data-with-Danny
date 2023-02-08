USE CT8_Fresh_Segments;
GO

-- Questions
-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
EXEC sp_RENAME 'interest_metrics.month_year', 'old_month_year', 'COLUMN';

ALTER TABLE interest_metrics
ADD month_year AS (
	CASE 
		WHEN old_month_year IS NULL THEN NULL
		ELSE CONVERT(VARCHAR, REPLACE(old_month_year, '-', '-01-'), 105)
		END
);

SELECT
	*
FROM
	interest_metrics;

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT
	month_year AS time,
	COUNT(interest_id) AS #records
FROM
	interest_metrics
GROUP BY
	month_year
ORDER BY
	CASE WHEN month_year IS NULL THEN 0 ELSE 1 END,
    month_year DESC;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
DELETE FROM 
	interest_metrics
WHERE
	interest_id IS NULL;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
-- from 'interest_metrics' to 'innterest_map'
SELECT 
	COUNT(DISTINCT map.id) AS map_id_count,
	COUNT(DISTINCT metrics.interest_id) AS metrics_id_count,
	SUM(CASE WHEN map.id is NULL THEN 1 END) AS not_in_metric,
	SUM(CASE WHEN metrics.interest_id is NULL THEN 1 END) AS not_in_map
FROM 
	interest_map AS map
	FULL OUTER JOIN interest_metrics AS metrics ON metrics.interest_id = map.id;

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT
	COUNT(DISTINCT id) AS #unique_ids
FROM
	interest_map;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
SELECT
	*
FROM
	interest_map AS map
	INNER JOIN interest_metrics AS metrics ON map.id = metrics.interest_id
WHERE
	metrics.interest_id = 21246
	AND metrics._month IS NOT NULL;

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT
	COUNT(*)
FROM
	interest_map AS map
	INNER JOIN interest_metrics AS metrics ON map.id = metrics.interest_id
WHERE
	metrics.month_year < map.created_at;

-- These values are still valid because month_year column is set to first day of month in default but they are still in the same month