USE CT8_Fresh_Segments;
GO

-- Questions
-- 1. Which interests have been present in all month_year dates in our dataset?
WITH
cte0 AS (
	SELECT
		interest_id
	FROM
		interest_metrics
	GROUP BY
		interest_id
	HAVING	
		COUNT(DISTINCT month_year) = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics)
)

SELECT
	DISTINCT map.interest_name
FROM
	cte0
	INNER JOIN interest_map AS map ON cte0.interest_id = map.id
ORDER BY
	map.interest_name;

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?


-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
-- 5. After removing these interests - how many unique interests are there for each month?