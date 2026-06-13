/*
============================================================
DDL Script: Create Gold Views
============================================================

Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema).

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
============================================================
*/

--=========================================================
--CREATE DIMENTION: gold.dim_Customers
--=========================================================
CREATE VIEW gold.dim_Customers AS
SELECT
-- Generate a primary key
	ROW_NUMBER() OVER (ORDER BY cst_id) AS Customer_Key,
	ci.cst_id AS Customer_Id,
	ci.cst_key AS Customer_Number,
	ci.cst_firstname AS First_Name,
	ci.cst_lastname AS Last_Name,
	lo.CNTRY AS Country,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master fro gender info
	ELSE COALESCE( ca.GEN , 'n/a')
	END AS Gender,
	ci.cst_marital_status AS Marital_Status ,
	ca.BDATE AS BirthDate,
	ci.cst_create_date AS Create_Date	
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.CID
LEFT JOIN silver.erp_LOC_A101 lo
ON ci.cst_key = lo.CID

--=========================================================
--CREATE DIMENTION: gold.dim_Products
--=========================================================
CREATE VIEW gold.dim_Products AS 
SELECT 
ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key ) AS Product_Key ,
	pn.prd_id AS Product_ID,
	pn.prd_key AS Product_Number,
	pn.prd_nm AS Product_Name,
	pn.cat_id AS Categoy_ID,
	pc.cat AS Category,
	pc.subcat AS Subcategory,
	pc.maintenance,
	pn.prd_cost AS Cost,
	pn.prd_line AS Product_Line,
	pn.prd_start_dt AS Start_Date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL -- Filter out all historical data 

--=========================================================
--CREATE FACT: gold.fact_Sales
--=========================================================
CREATE VIEW gold.fact_Sales AS 
SELECT 
sa.sls_ord_num AS Order_Number,
--sa.sls_prd_key, --remove it 
--pr.Product_Number, --remove it 
pr.Product_Key,
--sa.sls_cust_id, --remove it 
--cu.Customer_Id, --remove it 
cu.Customer_Key,
sa.sls_order_dt AS Order_Date,
sa.sls_ship_dt AS Shipping_Date,
sa.sls_due_dt AS Due_Date,
sa.sls_sales AS Sales_Amount,
sa.sls_quantity AS Quantity,
sa.sls_price AS Price
FROM silver.crm_sales_details sa
LEFT JOIN gold.dim_Products pr
ON sa.sls_prd_key = pr.Product_Number
LEFT JOIN gold.dim_Customers cu
ON sa.sls_cust_id = cu.Customer_Id



