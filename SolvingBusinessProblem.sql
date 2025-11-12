

SELECT *
FROM walmart;

-- Business Problems

-- 1. Analyze payment method and sales

SELECT payment_method,
		COUNT(invoice_id) AS no_transactions
FROM walmart
GROUP BY 1;


-- 2. Identify the highest rated category in each branch

WITH highest_ratings
AS
(
SELECT branch,
		category,
		MAX(rating) AS ratings,
		RANK() OVER(PARTITION BY branch ORDER BY MAX(rating) DESC) AS rank
FROM walmart
GROUP BY 1, 2
)
SELECT branch,
		category,
		ratings
FROM highest_ratings
WHERE rank = 1;


-- 3. Determine the busiest day of each branch

WITH busiest_day
AS
(
SELECT branch,
		TO_CHAR(date, 'Day') AS day_name,
		COUNT(invoice_id) no_of_transactions,
		RANK() OVER(PARTITION BY branch ORDER BY COUNT(invoice_id) DESC) AS rank
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 3 DESC
)
SELECT branch,
		day_name,
		no_of_transactions
FROM busiest_day
WHERE rank = 1;


-- 4. Calculate the total quantity sold by payment method. 

SELECT payment_method,
		SUM(quantity) AS qnty_sold
FROM walmart
GROUP BY 1;


-- 5. What are the average, minimum and maximum ration for each category in each city.

SELECT city,
		category,
		AVG(rating) AS avg_ratings,
		MAX(rating) AS max_ratings,
		MIN(rating) AS min_ratings
FROM walmart
GROUP BY 1, 2
ORDER BY 1;


-- 6. What is the total profit for each category ranked from highest to lowest in each city.

SELECT city,
		category,
		ROUND(SUM(unit_price * quantity * profit_margin)::numeric, 3) AS total_profit
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


-- 7. Determine the most common payment method per branch.

SELECT payment_method,
		COUNT(branch) AS no_of_branches
FROM walmart
GROUP BY 1;


-- 8. How many transactions occurs each shifts(Morning, Afternoon, Evening) across branches?

SELECT branch,
		CASE WHEN EXTRACT(HOUR FROM time::time) < 12 THEN 'Morning'
			WHEN EXTRACT(HOUR FROM time::time) BETWEEN 12 AND 17 THEN 'Afternoon'
			ELSE 'Evening'
		END AS shifts,
		COUNT(invoice_id) AS no_of_transactions
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


-- 9. Identify the highest revenue decline ratio year over year(2020 - 2021) for each category in each city.

WITH total_sale2020
AS
(
	SELECT city,
			category,
			SUM(unit_price * quantity) AS total_revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM date) = 2020
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC
),
sale2021
AS
(
	SELECT city,
			category,
			SUM(unit_price * quantity) AS total_revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM date) = 2021
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC
),
year_over_year_rev
AS
(	SELECT s.city,
			ts.category,
			ts.total_revenue AS revenue_sale2020,
			s.total_revenue AS revenue_sale2021,
			ROUND((ts.total_revenue - s.total_revenue)::numeric/ts.total_revenue::numeric * 100, 3) AS revenue_decline_ratio
	FROM total_sale2020 ts
	JOIN sale2021 s
	ON s.city = ts.city
	WHERE ts.total_revenue > s.total_revenue
	ORDER BY 1, 5 DESC
),
ranking_year
AS
(
	SELECT *,
			RANK() OVER(PARTITION BY city ORDER BY revenue_decline_ratio DESC) AS rank
	FROM year_over_year_rev
)
	SELECT city,
			category,
			revenue_sale2020,
			revenue_sale2021,
			revenue_decline_ratio
	FROM ranking_year
	WHERE rank = 1
	ORDER BY 5 DESC;


-- 10. Identify the highest revenue decline ratio year over year(2024 - 2025) in each branch.

WITH revenue_2024
AS
(
	SELECT branch,
			SUM(unit_price * quantity) AS total_revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM date) = 2024
	GROUP BY 1
),
revenue_2025
AS
(
	SELECT branch,
			SUM(unit_price * quantity) AS total_revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM date) = 2025
	GROUP BY 1
)
	SELECT ls.branch,
			ls.total_revenue AS last_year_revenue,
			cs.total_revenue AS current_year_revenue,
			ROUND((ls.total_revenue - cs.total_revenue)::numeric/ls.total_revenue::numeric * 100, 3) AS decline_ratio
	FROM revenue_2024 ls
	JOIN revenue_2025 cs
	ON ls.branch = cs.branch
	WHERE ls.total_revenue > cs.total_revenue
	ORDER BY 1, 4 DESC;







