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

-- ===================================
-- Step 1) Show CSI report
-- ===================================

-- ===================================
-- Step 2) Main CSI Changes
-- ===================================

Use AdventureworksDW2016CTP3
go

-- You can query the following DMV to show that most data in CCI is compressed
SELECT object_name(object_ID), *
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = object_id('FactResellerSalesXL_CCI')

-- =====================================================================================================
-- Constraints
-- =====================================================================================================
-- SQL 2014 did not support foreign Key constraints.. 
-- Validate there are constraints on this table
SELECT * FROM sys.indexes WHERE object_id = object_id('FactResellerSalesXL_CCI')
SELECT * FROM sys.foreign_keys WHERE parent_object_id = object_id('FactResellerSalesXL_CCI')

-- Now make change to violate constraint and it should fail.
BEGIN TRAN
DECLARE @SalesOrderNumber NVARCHAR(25)

SET @SalesOrderNumber = (
		SELECT TOP 1 SalesOrderNumber
		FROM FactResellerSalesXL_CCI
		)

UPDATE FactResellerSalesXL_CCI
SET ProductKey = - 999
WHERE SalesOrderNumber = @SalesOrderNumber
ROLLBACK

-- =====================================================================================================
--  Batch  Mode improvements under compatibility mode 130
-- =====================================================================================================
-- Enable Actual QUery Plans for this exercise
-- Hover your mouse over the SORT operator, you will see that the SORT is in batch mode.
-- See the "ACTUAL EXECUTION MODE".. A few operators that were in Row mode in SQL 2014 are now in BATCH mode.

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT ProductKey
	,count(ProductKey)
FROM FactResellerSalesXL_CCI
GROUP BY ProductKey
ORDER BY ProductKey

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO


/*****************************************************************************
-- Batch Mode for serial ( Serial plan aka maxdop 1  in 2014 was in row mode)
-- Again hover over the SCAN node in the query plan and you will see that it is
-- in BATCH mode
***************************************************************************/
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT ProductKey,sum(TotalProductCost)
FROM FactResellerSalesXL_CCI
GROUP BY ProductKey
OPTION (MAXDOP 1)
GO


-- set Database in 120 compatibility mode
ALTER DATABASE AdventureworksDW2016CTP3 SET compatibility_level = 120
GO
-- you will see that this query now runs in rowmode (much slower)
SELECT ProductKey,sum(TotalProductCost)
FROM FactResellerSalesXL_CCI
GROUP BY ProductKey
OPTION (MAXDOP 1)
GO

-- Ensure Database is back in 130 compatibility mode
ALTER DATABASE AdventureworksDW2016CTP3 SET compatibility_level = 130
GO
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO


/*****************************************************************************
 Batch mode for Windows aggregates
******************************************************************************/
-- you will see that this query runs with in BATCH mode
SELECT ProductKey,OrderDateKey
	,LEAD(OrderQuantity, 1, 0) OVER (ORDER BY OrderDateKey) AS NextQuota
FROM FactResellerSalesXL_CCI
WHERE orderdatekey IN (	20060301,20060601)

-- set Database in 120 compatibility mode
ALTER DATABASE AdventureworksDW2016CTP3 SET compatibility_level = 120
GO

-- you will see that this query now runs in rowmode (much slower)
SELECT ProductKey	,OrderDateKey
	,LEAD(OrderQuantity, 1, 0) OVER (ORDER BY OrderDateKey) AS NextQuota
FROM FactResellerSalesXL_CCI
WHERE orderdatekey IN (	20060301,20060601)

-- Ensure Database is back in 130 compatibility mode
ALTER DATABASE AdventureworksDW2016CTP3 SET compatibility_level = 130
GO

-- Multiple distinct batch mode ( was row mode in SQL 2014)
-- In SQL 2014 the hash match would be ROW mode, and all upstream operators would be row mode.
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT ProductKey
	,COUNT(DISTINCT rs.EmployeeKey) AS NumEmployees
	,COUNT(DISTINCT rs.ResellerKey) AS NumResellers
FROM dbo.FactResellerSalesXL_CCI AS rs
WHERE rs.SalesTerritoryKey >= 8
GROUP BY ProductKey
ORDER BY ProductKey;
GO

SET STATISTICS IO OFF

SET STATISTICS TIME OFF
GO


/*************************************************************************************
STEP 5 - Aggregate Pushdown
**********************************************************************************/

SET STATISTICS IO ON
SET STATISTICS TIME ON

-- Scalar aggregate pushdown without groupby is implemented.
-- Look at the Rows coming out of the SCAN, invariably in the past, 11 million rows would flow out and be filtered to 1 row
SELECT sum(TotalProductCost)
FROM FactResellerSalesXL_CCI

-- Aggregate Pushdown for a groupby supported as well
SELECT ProductKey
	,count(*)
FROM FactResellerSalesXL_CCI
GROUP BY ProductKey

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

/*************************************************************************************
STEP 7 - String Predicate Pushdown
**********************************************************************************/
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO
DBCC DROPCLEANBUFFERS
GO

-- Look at the Query Plan, you will see the Predicate pushed to the SCAN
-- In SQL 2014, this would be a SCAN followed by a Filter
-- Look at the Properties of the SCAN, you will see a Predicate:  [AdventureworksDW2014].[dbo].[FactResellerSalesXL_CCI].[CustomerPONumber]=[@1]
SELECT CustomerPONumber
FROM FactResellerSalesXL_CCI
WHERE CustomerPONumber = N'PO1022545'

-- set Database in 120 compatibility mode
ALTER DATABASE AdventureworksDW2016CTP3 SET compatibility_level = 120
GO
DBCC DROPCLEANBUFFERS
GO

-- you will see that this query now runs in rowmode (much slower)
SELECT CustomerPONumber
FROM FactResellerSalesXL_CCI
WHERE CustomerPONumber = N'PO1022545'

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

-- Ensure Database is back in 130 compatibility mode
ALTER DATABASE AdventureworksDW2016CTP3 SET compatibility_level = 130
GO


/*************************************************************************************
STEP 8 - Non-Clustered Indexes ( btree)  on top of Clustered columnstore index 
**********************************************************************************/
-- What abount narrow lookups
-- See missing index for this Plan
-- Also notice no segments were eliminated . There is an optimization where you see a PROBE BITMAP filter pushed to the SCAN

DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

SELECT OrderDate
	,SalesAmount
FROM FactResellerSalesXL_CCI a
INNER JOIN DimReseller b ON a.ResellerKey = b.ResellerKey
WHERE b.ResellerName = 'Wheels Inc.'
GO

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
GO


/* Now create the missing index */
CREATE NONCLUSTERED INDEX IndFactResellerSalesXL_CCI_NCI ON [dbo].[FactResellerSalesXL_CCI] ([ResellerKey]) 
INCLUDE ([SalesAmount],[OrderDate])

-- After NCI creation what does the plan look like?
-- Notice the Join has changed from Hash join to a nested loop join
-- Also the inner branch of the nested loop is a seek
-- And IO done is far less and time should be less too in particular CPU time
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

SELECT OrderDate
	,SalesAmount
FROM FactResellerSalesXL_CCI a
INNER JOIN DimReseller b ON a.ResellerKey = b.ResellerKey
WHERE b.ResellerName = 'Wheels Inc.'

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
GO

-- drop the index just created
--Drop index [FactResellerSales_CCI].IndFactResellerSales_CCI_NCI
DROP INDEX IF EXISTS [FactResellerSales_CCI].IndFactResellerSales_CCI_NCI;
