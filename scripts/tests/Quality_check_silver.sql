-- ========================================
-- Quality Check for bronze tables:
-- ========================================

-- Check for nulls or duplicate in primary key 
-- expectation: no result 

SELECT cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR cst_id IS NULL 

-- Check for unwanted spaces 
-- expectation: no result 
-- check for all text columns

SELECT 
cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM (cst_firstname)

-- Data standardization & consistency 
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info

-- ========================================
-- Quality Check for silver tables (after cleaning):
-- ========================================

-- Check for nulls or duplicate in primary key 
-- expectation: no result 

SELECT cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR cst_id IS NULL 

-- Check for unwanted spaces 
-- expectation: no result 
-- check for all text columns

SELECT 
cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM (cst_firstname)

-- Data standardization & consistency 
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info

-- ================================================================
-- Check for nulls or duplicate in primary key 
-- expectation: no result 
SELECT 
prd_id,
COUNT (*) 
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL 

-- Check for unwanted spaces 
-- expectation: no result 
-- check for all text columns

SELECT 
prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM (prd_nm)

-- check for Nulls or negative numbers
-- expectation: no result 

SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost <0

-- Data standardization & consistency 
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check if the end date is < the start date
-- expectation: no result 
SELECT 
prd_id,
prd_start_dt,
prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt 
-- Solution: End date = start date of next record -1


-- ================================================================
-- Check if the keys are applicable to use in customer and product table
-- expectation: no result 

SELECT 
 sls_prd_key,
 sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id  NOT IN (SELECT cst_id FROM silver.crm_cust_info )
OR 	  sls_prd_key  NOT IN (SELECT prd_key FROM silver.crm_prd_info )						

-- Check for unwanted spaces 
-- expectation: no result 
-- check for all text columns

SELECT 
sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num!= TRIM (sls_ord_num)

-- to convert order_dt INT to date ,check : 

SELECT 
sls_order_dt,
sls_ship_dt,
sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt =0      -- check if the date is 0 
OR sls_due_dt <0         -- or negative values
OR LEN(sls_due_dt) != 8  -- check if all the numbers have 8 charachter yyyymmdd
OR sls_due_dt > 20500101 -- check for outliers 
OR sls_due_dt < 19000101 -- check for outliers 
OR sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt -- check for invalid date order 

-- check data consistency between sales , quantity and price 
-- >> Sales = Quantity * Price 
-- >> values must not be zero or nulls or negative 

SELECT DISTINCT
sls_sales AS old_sales,
CASE WHEN sls_sales IS NULL OR sls_quantity <=0 OR sls_sales != sls_quantity * ABS(sls_price)
	 THEN  sls_quantity * ABS(sls_price)
	 ELSE sls_sales
	 END AS sls_sales,
 sls_quantity,
 sls_price AS old_price,
CASE WHEN sls_price IS NULL OR sls_price <=0
	 THEN sls_sales / NULLIF (sls_quantity , 0)
	 ELSE sls_price 
	 END AS sls_price 
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR	  sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR	  sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0

-- Transformation Rules:
-- if sales is negative , zero, or null , derive it using quantity and price
-- if price is zer or null calculate it using sales and quantity 
-- if price is negative convert it to positive value

-- =======================================================================

-- check if the CID is consistence with the cst_key from crm_cust Table
SELECT
	CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING (CID,4,LEN(CID))
		 ELSE CID
		 END AS CID ,
    BDATE,
    GEN
FROM bronze.erp_CUST_AZ12
WHERE CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING (CID,4,LEN(CID))
		 ELSE CID
		 END NOT IN (SELECT DISTINCT cst_key FROM Silver.crm_cust_info )

-- identify the out of range birthday date 
SELECT
	CID,
    BDATE,
    GEN
FROM bronze.erp_CUST_AZ12
WHERE BDATE < '1924-01-01' OR BDATE > GETDATE()

-- Data standardization & consistency 
SELECT DISTINCT GEN
FROM bronze.erp_CUST_AZ12

-- ====================================================
-- Data standardization & consistency 
SELECT DISTINCT 
CASE WHEN TRIM(CNTRY) IN ( 'DE', 'Germany') THEN 'Germany'
	 WHEN TRIM(CNTRY) IN ( 'US', 'USA', 'United States') THEN 'United States'
	 WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
  	 ELSE TRIM(CNTRY)
	 END AS CNTRY
FROM bronze.erp_LOC_A101
ORDER BY CNTRY 

-- ==================================================

-- Check for unwanted spaces 
SELECT
	ID,
    CAT,
    SUBCAT,
    MAINTENANCE
FROM bronze.erp_PX_CAT_G1V2
WHERE CAT != TRIM (CAT) OR SUBCAT != TRIM (SUBCAT) OR MAINTENANCE != TRIM (MAINTENANCE)

-- Data standardization & consistency 
SELECT DISTINCT MAINTENANCE
FROM bronze.erp_PX_CAT_G1V2
