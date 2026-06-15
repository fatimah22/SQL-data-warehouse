/*
===============================================================================

Product Report
===============================================================================

Purpose:
   - This report consolidates key product metrics and behaviors.

Highlights:
   1. Gathers essential fields such as product name, category, subcategory, and cost.
   2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
   3. Aggregates product-level metrics:
      - total orders
      - total sales
      - total quantity sold
      - total customers (unique)
      - lifespan (in months)
   4. Calculates valuable KPIs:
      - recency (months since last sale)
      - average order revenue (AOR)
      - average monthly revenue

===============================================================================
*/

/*-------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
-------------------------------------------------------------*/
CREATE VIEW Gold.report_products AS 

WITH Base_query AS (
    SELECT
    s.order_number,
    s.order_date,
    s.customer_key,
    s.sales_amount,
    s.quantity,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p 
    ON s.product_key = p.product_key 
    WHERE order_date IS NOT NULL 
)
/*-------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
-------------------------------------------------------------*/
, Product_Aggregation AS (
    SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(Month, MIN(order_date), MAX(order_date)) AS Lifespan,
    MAX (order_date) AS last_sales_date,
    COUNT(DISTINCT order_number) AS Total_Orders,
    COUNT(DISTINCT customer_key) AS Total_customers,
    SUM (sales_amount) AS Total_sales,
    SUM (Quantity) AS Total_quantity,
    ROUND (AVG (CAST (sales_amount AS FLOAT) / NULLIF (quantity,0)),1) AS Avg_selling_price
    FROM Base_query
    GROUP BY 
    product_key,
    product_name,
    category,
    subcategory,
    cost
    )
/*-------------------------------------------------------------
3) Final Query: combine all product results into one output
-------------------------------------------------------------*/
SELECT 
product_key,
product_name,
category,
subcategory,
cost,
last_sales_date,
DATEDIFF(Month, last_sales_date,GETDATE()) AS Recency_in_months ,
CASE WHEN Total_sales > 50000 THEN 'High Performer'
    WHEN Total_sales >= 10000 THEN 'Mid Performer'
    ELSE 'Low Performer'
    END AS products_Segment,
Lifespan,
Total_Orders,
Total_customers,
Total_sales,
Total_quantity,
Avg_selling_price,
--Average order value (AVO)
--Average order value = total sales / total number of orders 
CASE WHEN Total_Orders = 0 THEN 0
	 ELSE Total_sales / Total_Orders
	 END AS AVO,
--Average monthly revenue
CASE WHEN Lifespan = 0 THEN Total_sales
	 ELSE Total_sales / Lifespan
	 END AS average_monthly_revenue
FROM Product_Aggregation
