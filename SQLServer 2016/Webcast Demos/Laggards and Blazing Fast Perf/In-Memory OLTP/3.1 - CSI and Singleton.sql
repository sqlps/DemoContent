-- ===================================
-- Step 1) Run Reports
-- ===================================
--Run SSRS Reports
--Show sizing differneces in AdventureworksDW_Azure

-- ===================================
-- Step 2) Non-Clustered Indexes ( btree)  on top of Clustered columnstore index 
-- ===================================
Use AdventureworksDW2016CTP3
GO

-- What abount narrow lookups
-- See missing index for this Plan
-- Also notice no segments were eliminated . There is an optimization where you see a PROBE BITMAP filter pushed to the SCAN

--Enable Actual plan

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
DROP INDEX IF EXISTS [FactResellerSalesXL_CCI].IndFactResellerSalesXL_CCI_NCI;

