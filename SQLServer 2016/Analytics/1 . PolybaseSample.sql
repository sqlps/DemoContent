
------------------------------- Polybase Building Blocks --------------------------------------------------------
Use AdventureworksDW2016CTP3
GO
-- ============================================================================================================
-- Step 1) Validate database master key to encrypt database scoped credential secret
-- ============================================================================================================
Select * from sys.symmetric_keys
-- ============================================================================================================
-- Step 2) Validate credential to Azure exists
-- ============================================================================================================
select * from sys.database_credentials;
-- ============================================================================================================
-- Step 3) Validate my external data source
-- ============================================================================================================
select * from sys.external_data_sources;
-- ============================================================================================================
-- Step 4) What file formats have I defined
-- ============================================================================================================
select * from sys.external_file_formats;
-- ============================================================================================================
-- Step 5) What external_tables present
-- ============================================================================================================
select * from sys.external_tables;

-- Try running queries on your external table. 
SELECT * FROM dbo.FactResellerSalesArchiveExternal; -- returns 5000 rows.

SELECT * FROM dbo.FactResellerSalesArchiveExternal -- returns 1959 rows
WHERE SalesAmount > 1000;

------------------------------- Load data into your database --------------------------------------------------------
-- Step 6: Load the data from Azure blob storage into a new table in your database.
SELECT * INTO dbo.FactResellerSalesArchive
FROM dbo.FactResellerSalesArchiveExternal; 


-- Try a select query on this table to confirm the data has been loaded correctly.
SELECT * FROM dbo.FactResellerSalesArchive;

--cleanup
Drop Table FactResellerSalesArchive