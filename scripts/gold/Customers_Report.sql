/*
===============================================================================

Customer Report
===============================================================================

Purpose:
   - This report consolidates key customer metrics and behaviors

Highlights:
   1. Gathers essential fields such as names, ages, and transaction details.
   2. Segments customers into categories (VIP, Regular, New) and age groups.
   3. Aggregates customer-level metrics:
      - total orders
      - total sales
      - total quantity purchased
      - total products
      - lifespan (in months)
   4. Calculates valuable KPIs:
      - recency (months since last order)
      - average order value
      - average monthly spend

===============================================================================
*/

/*-------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
-------------------------------------------------------------*/
CREATE VIEW gold.report_customers AS 

WITH base_query AS (
SELECT
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
	CONCAT ( c.first_name, ' ' ,c.last_name ) Customer_Name,
	DATEDIFF (Year, c.birthdate, GETDATE()) Age 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
WHERE f.order_date IS NOT NULL )

, Customer_Aggregations AS (
/*-------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
-------------------------------------------------------------*/
SELECT 
customer_key,
customer_number,
customer_name,
Age,
COUNT (DISTINCT order_number) AS Total_order,
SUM (Sales_amount) AS Total_sales,
SUM(quantity) AS Total_Quantity,
COUNT(DISTINCT product_key) AS total_product,
MAX (order_date) AS last_order_date,
DATEDIFF(Month, MIN(order_date), MAX(order_date)) AS Lifespan
FROM base_query 
GROUP BY customer_key,
		 customer_number,
		 customer_name,
		 Age
)

SELECT 
customer_key,
customer_number,
customer_name,
Age,
CASE WHEN Age < 20 THEN 'Under 20'
	 WHEN Age BETWEEN 20 AND 29 THEN '20 -29'
	 WHEN Age BETWEEN 30 AND 39 THEN '30 -39'
	 WHEN Age BETWEEN 40 AND 49 THEN '40 -49'
	 ELSE 'Above 50'
	 END AS Age_Group,
Total_order,
Total_sales,
Total_Quantity,
total_product,
last_order_date,
DATEDIFF(month, last_order_date,GETDATE()) AS recency,
Lifespan,
CASE WHEN Lifespan > 12 AND Total_sales > 5000 THEN 'VIP'
	 WHEN Lifespan > 12 AND Total_sales <= 5000 THEN 'Regular'
	 ELSE 'New'
	 END AS Customer_segment,
--compute average order value (AVO)
--Average order value = total sales / total number of orders 
CASE WHEN Total_order = 0 THEN 0
	 ELSE Total_sales / Total_order
	 END AS AVO,
-- Compute average monthly spend = total sales / number of months 
CASE WHEN Lifespan = 0 THEN Total_sales
	 ELSE Total_sales / Lifespan
	 END AS average_monthly_spend
FROM Customer_Aggregations
