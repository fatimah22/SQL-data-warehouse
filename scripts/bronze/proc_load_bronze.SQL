/*
============================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
============================================================

Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from CSV files to bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
============================================================
*/


-- ======================================================================
-- Insert bulk the data from the data source CSV files 
-- truncate first ( to make the table empty and avoid duplication )
-- ======================================================================
-- Include all the tables insertion in a stored procedure to make it easy to update the tables in the data base 

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN

	DECLARE @start_time DATETIME , @end_time DATETIME ,@batch_start_time DATETIME , @batch_end_time DATETIME;
	BEGIN TRY 	
	SET @batch_start_time = GETDATE();
		PRINT '=====================================================';
		PRINT ' LOADING BRONZE LAYER';
		PRINT '=====================================================';

		PRINT '-----------------------------------------------------';
		PRINT 'LOADING CRM TABLES';
		PRINT '-----------------------------------------------------';

		SET @start_time = GETDATE ();
		PRINT '>> Truncate tabel: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '>> Inserting data into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\fatima abdullah\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW =2,             -- start from row two because we have the header already
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE ();
		PRINT '>> Load Duration '+ CAST(DATEDIFF (SECOND,@start_time , @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> -------------------'
	
		SET @start_time = GETDATE ();
		PRINT '>> Truncate tabel:bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT '>> Inserting data into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\fatima abdullah\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE ();
		PRINT '>> Load Duration '+ CAST(DATEDIFF (SECOND,@start_time , @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> -------------------'

		SET @start_time = GETDATE ();
		PRINT '>> Truncate tabel:bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '>> Inserting data into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\fatima abdullah\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE ();
		PRINT '>> Load Duration '+ CAST(DATEDIFF (SECOND,@start_time , @end_time) AS VARCHAR) + ' seconds';
		
		
		PRINT '-----------------------------------------------------';
		PRINT 'LOADING ERP TABLES';
		PRINT '-----------------------------------------------------';

		SET @start_time = GETDATE ();
		PRINT '>> Truncate tabel:bronze.erp_CUST_AZ12';
		TRUNCATE TABLE bronze.erp_CUST_AZ12;
		PRINT '>> Inserting data into: bronze.erp_CUST_AZ12';
		BULK INSERT bronze.erp_CUST_AZ12
		FROM 'C:\Users\fatima abdullah\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.CSV'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE ();
		PRINT '>> Load Duration '+ CAST(DATEDIFF (SECOND,@start_time , @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> -------------------'
	
		SET @start_time = GETDATE ();
		PRINT '>> Truncate tabel:bronze.erp_LOC_A101';
		TRUNCATE TABLE bronze.erp_LOC_A101;
		PRINT '>> Inserting data into: bronze.erp_LOC_A101';
		BULK INSERT bronze.erp_LOC_A101
		FROM 'C:\Users\fatima abdullah\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\LOC_A101.CSV'
		WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE ();
		PRINT '>> Load Duration '+ CAST(DATEDIFF (SECOND,@start_time , @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> -------------------'

		SET @start_time = GETDATE ();
		PRINT '>> Truncate tabel:bronze.erp_PX_CAT_G1V2';
		TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;
		PRINT '>> Inserting data into: bronze.erp_PX_CAT_G1V2';
		BULK INSERT bronze.erp_PX_CAT_G1V2
		FROM 'C:\Users\fatima abdullah\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.CSV'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
		SET @end_time = GETDATE ();
		PRINT '>> Load Duration '+ CAST(DATEDIFF (SECOND,@start_time , @end_time) AS VARCHAR) + ' seconds';
		
	SET @batch_end_time = GETDATE();
	PRINT '====================================================';
	PRINT 'Loading bronze layer is completed';
	PRINT '	Total load duration ' + CAST( DATEDIFF (SECOND, @batch_start_time , @batch_end_time) AS VARCHAR) + ' seconds';
	PRINT '====================================================';
	END TRY
	BEGIN CATCH
	PRINT '===================================================='
	PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
	PRINT 'Error Message' + error_message ();
	PRINT 'Error Number' + CAST (error_number() AS NVARCHAR);
	PRINT ' Error State' + CAST (error_state () AS NVARCHAR);
	PRINT '===================================================='
	END CATCH
END

EXEC bronze.load_bronze

-- =========================================================================

/* Validate the table: Check if the data inserted in the correct column
   Validate the table: check that all rows are imported completely */

-- SELECT * FROM bronze.crm_cust_info
-- SELECT COUNT (*) FROM bronze.crm_cust_info

-- SELECT * FROM bronze.crm_prd_info
-- SELECT COUNT(*) FROM bronze.crm_prd_info

-- SELECT * FROM bronze.crm_sales_details
-- SELECT COUNT(*) FROM bronze.crm_sales_details

-- SELECT * FROM bronze.erp_CUST_AZ12
-- SELECT COUNT(*) FROM bronze.erp_CUST_AZ12

-- SELECT * FROM bronze.erp_LOC_A101
-- SELECT COUNT(*) FROM bronze.erp_LOC_A101

-- SELECT * FROM bronze.erp_PX_CAT_G1V2
-- SELECT COUNT(*) FROM bronze.erp_PX_CAT_G1V2
