/* This Sample Code is provided for the purpose of illustration only and is not intended 
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE 
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR 
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You 
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or 
result from the use or distribution of the Sample Code.
*/


------------------------------- Polybase Building Blocks --------------------------------------------------------
USE AdventureWorksDW2016CTP3
go
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
select Sum(salesamount) 'Total Sales', SalesTerritoryRegion, SalesTerritoryCountry, SalesTerritoryGroup
from FactResellerSalesArchiveExternal FR
inner join DimSalesTerritory ST
on ST.SalesTerritoryKey = FR.SalesTerritoryKey
Group by SalesTerritoryRegion, SalesTerritoryCountry, SalesTerritoryGroup


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