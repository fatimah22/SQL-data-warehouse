--=======================================================
-- Advanced Analytics project
--=======================================================
-- go through these analysis types based on requirements 
-- 1) Change over time - trend analsyis
-- 2) Comulative Analysis
-- 3) Performance Analysis
-- 4) Part to Whole Analysis
-- 5) Data Segmentation
-->> Change over time <<--

--Analyze sales performance over time (YEAR)
SELECT 
YEAR(order_date) AS Year,
SUM (sales_amount) AS Total_Sales,
COUNT (DISTINCT customer_key) AS Total_customers,
SUM (quantity) AS Total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

--Analyze sales performance over time (MONTH) to discover seasonality 
SELECT 
DATETRUNC (Month,order_date) AS order_date, -- output is date
YEAR(order_date) AS 'Year', -- output is integer
MONTH (order_date) AS 'Month',-- output is integer
SUM (sales_amount) AS Total_Sales,
COUNT (DISTINCT customer_key) AS Total_customers,
SUM (quantity) AS Total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC (Month,order_date), YEAR(order_date),MONTH(order_date)
ORDER BY DATETRUNC (Month,order_date), YEAR(order_date),MONTH(order_date)

--=======================================================
-->> Comulative Analysis <<--

-- Calculate the total sales per month 
-- and the runing total of sales over time
SELECT
order_date,
total_sales,
Avg_price,
SUM (total_sales) OVER (PARTITION BY DATETRUNC(YEAR, order_date) ORDER BY order_date ROWS BETWEEN 
UNBOUNDED PRECEDING AND CURRENT ROW) AS Runing_total_sales,
AVG (Avg_price) OVER (PARTITION BY DATETRUNC(YEAR, order_date) ORDER BY order_date ROWS BETWEEN 
UNBOUNDED PRECEDING AND CURRENT ROW) AS Moving_average_price
FROM (
	SELECT 
	DATETRUNC(Month, order_date) AS order_date,
	SUM(sales_amount)  AS total_sales,
	AVG(price) AS Avg_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(Month, order_date)
	) t

--=======================================================
-->> Performance Analysis <<--
-- Analyze the yearly performance of products by comparing each product's sales 
-- to both its average sales performance and the previous year's sales

WITH Yearly_Product_Sales AS (
	SELECT 
	YEAR(s.order_date) Order_Year,
	p.product_name AS Product_Name,
	SUM (s.sales_amount) Current_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key 
	WHERE order_date IS NOT NULL
	GROUP BY p.product_name , YEAR(s.order_date)
	)

SELECT 
Order_Year,
Product_Name,
Current_sales,
AVG (Current_sales) OVER (PARTITION BY Product_Name ) AS Average_sales,
Current_sales - AVG (Current_sales) OVER (PARTITION BY Product_Name) AS Avg_diff,
CASE WHEN Current_sales - AVG (Current_sales) OVER (PARTITION BY Product_Name) >0 THEN 'Above Avg'
	 WHEN Current_sales - AVG (Current_sales) OVER (PARTITION BY Product_Name) <0 THEN 'Below Avg'
	 ELSE 'Avg'
	 END AS Avg_Change,
-- Year - over - year Analysis	 
LAG (Current_sales) OVER (PARTITION BY Product_Name ORDER BY Order_Year) AS Py_Sales,
Current_sales - LAG (Current_sales) OVER (PARTITION BY Product_Name ORDER BY Order_Year) AS Diff_Py,
CASE WHEN LAG (Current_sales) OVER (PARTITION BY Product_Name ORDER BY Order_Year) >0 THEN 'Increase'
	 WHEN LAG (Current_sales) OVER (PARTITION BY Product_Name ORDER BY Order_Year) <0 THEN 'Decrease'
	 ELSE 'No change'
	 END AS Py_Change
FROM Yearly_Product_Sales

--=======================================================
-->> Part to Whole Analysis <<--
-- which categories contributes the most to overall sales 
-- Try it with total orders or quantity ... 
WITH Category_Sales AS (
SELECT 
p.category,
SUM (s.sales_amount) AS Total_Sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p 
ON s.product_key = p.product_key 
GROUP BY p.category
)
SELECT 
category,
Total_Sales,
SUM (Total_Sales) OVER () AS Overall_Sales,
CONCAT (ROUND((CAST(Total_Sales AS Float) / SUM (Total_Sales) OVER () ) * 100,2), '%') AS Percentage_of_total
FROM Category_Sales
ORDER BY Total_Sales DESC


--=======================================================
-->> Data Segmentation <<--
/*Segment products into cost ranges and count how 
many products full into each segment*/

-- convert the cost measure to dimention 
WITH Product_Segment AS (
	SELECT 
	product_key,
	product_name,
	cost,
	CASE WHEN COST< 100 THEN 'Below 100'
		WHEN COST BETWEEN 100 AND 500 THEN '100 - 500'
		WHEN COST BETWEEN 500 AND 1000 THEN '500 - 1000'
		ELSE 'Above 1000'
		END AS Cost_Range 
	FROM gold.dim_products
) 
SELECT 
Cost_Range,
COUNT (product_key) AS Total_Products
FROM Product_Segment
GROUP BY Cost_Range

/* Group customers into three segments based on their spending behavior
  - VIP: Customers with at least 12 months of history and spending more than 5000 $
  - Regular: Customers with at least 12 months of history but spending 5000 $ or less
  - New: Customers with a lifespan less than 12 months
and find the total number of customers by each froup */
WITH Customer_Segmentation AS (
SELECT 
c.customer_key,
SUM(s.sales_amount) AS Total_spending,
MIN (s.order_date) AS First_order_date,
MAX (s.order_date) AS Last_order_date,
DATEDIFF( Month,MIN (s.order_date),MAX (s.order_date)) AS Lifespan
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON s.customer_key = c.customer_key
GROUP BY c.customer_key
)
SELECT 
Customer_segment,
COUNT(customer_key) AS Total_customers
FROM (
	SELECT 
	customer_key,
	Total_spending,
	Lifespan,
	CASE WHEN Lifespan > 12 AND Total_spending > 5000 THEN 'VIP'
		 WHEN Lifespan > 12 AND Total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
		 END AS Customer_segment
	FROM Customer_Segmentation
)t
GROUP BY Customer_segment
ORDER BY Total_customers DESC
