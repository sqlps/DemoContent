-- If you haven't already set your current database, run these 2 lines
USE AdventureWorks2016DW
GO

-- Verify the size of the table
SELECT COUNT(*) FROM FactResellerSalesXL_CCI
GO

-- Create a foreign key
-- 1.
ALTER TABLE [dbo].[FactResellerSalesXL_CCI]  WITH CHECK 
ADD CONSTRAINT [FK_FactResellerSalesXLCCI_DimEmployee] FOREIGN KEY([EmployeeKey])
REFERENCES [dbo].[DimEmployee] ([EmployeeKey])
GO
ALTER TABLE [dbo].[FactResellerSalesXL_CCI] 
CHECK CONSTRAINT [FK_FactResellerSalesXLCCI_DimEmployee]
GO

-- 2. verify that foreign key enforces ref. integrity: This will produce an error
DECLARE @nonexistentEmployeeKey int
SELECT @nonexistentEmployeeKey = MAX(EmployeeKey)+1 FROM [DimEmployee]
INSERT INTO FactResellerSalesXL_CCI
([ProductKey],[OrderDateKey],[DueDateKey],[ShipDateKey],
 [ResellerKey],[EmployeeKey],[PromotionKey],[CurrencyKey],
 [SalesTerritoryKey],[SalesOrderNumber],[SalesOrderLineNumber])
VALUES(310,20140101,20140104,20140102,150,@nonexistentEmployeeKey,
1,100,10,'S0101',1)
GO

-- Create an additional non-clustered index on the table
--1 Run a simple query without the additional index
SET STATISTICS XML ON
SET STATISTICS IO ON
GO
SELECT b.ProductKey, OrderDateKey, SalesTerritoryKey, EmployeeKey
FROM FactResellerSalesXL_CCI a 
INNER JOIN DimProduct b ON a.ProductKey = b.ProductKey
WHERE OrderDateKey BETWEEN 20080201 AND 20090801
AND b.ProductKey = 310
GO

-- 3 Create a non-clustered index. 
CREATE NONCLUSTERED INDEX idxProductOrderDate
ON dbo.FactResellerSalesXL_CCI (ProductKey, OrderDateKey)
INCLUDE (EmployeeKey, SalesTerritoryKey)
GO

-- 4 re-run the query now that there is an index
SET STATISTICS XML ON
SET STATISTICS IO ON
GO
SELECT b.ProductKey, OrderDateKey, SalesTerritoryKey, EmployeeKey
FROM FactResellerSalesXL_CCI a 
INNER JOIN DimProduct b ON a.ProductKey = b.ProductKey
WHERE OrderDateKey BETWEEN 20080201 AND 20090801
AND b.ProductKey = 310
GO
SET STATISTICS XML OFF
SET STATISTICS IO OFF

-- 5 Run a simple query with a predicate
SET STATISTICS XML ON
SET STATISTICS IO ON
GO
SELECT COUNT(*)
FROM FactResellerSalesXL_CCI 
WHERE OrderDateKey BETWEEN 20060101 AND 20070101
GO
SET STATISTICS XML OFF
SET STATISTICS IO OFF

--Comparing performance with a nonclustered Columnstore index

-- 1 Create a non-clustered columnstore index on a table that already has a clustered index on it. 
CREATE NONCLUSTERED COLUMNSTORE INDEX [Idx_Columnstore] 
ON [dbo].[FactResellerSalesXL_PageCompressed]
(
	[ShipDateKey],
	[SalesTerritoryKey],
	[ProductKey],
	[SalesAmount]
)WITH (DROP_EXISTING = OFF) ON [PRIMARY]
GO

-- 2 Run a query, but ignore the index
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
SELECT AVG(SalesAmount) AS AvgSales, SUM(SalesAmount) AS TotalSales
FROM FactResellerSalesXL_PageCompressed
WHERE ShipDateKey BETWEEN 20080101 AND 20100101
GROUP BY SalesTerritoryKey, ProductKey
OPTION (IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX) --this ignores the index
GO

-- 4 Run the query again, this time with the index
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
SELECT AVG(SalesAmount) AS AvgSales, SUM(SalesAmount) AS TotalSales
FROM FactResellerSalesXL_PageCompressed
WHERE ShipDateKey BETWEEN 20080101 AND 20100101
GROUP BY SalesTerritoryKey, ProductKey
GO

-- Inserting data to a table with a non-clustered Columnstore index
SET STATISTICS TIME OFF
SET STATISTICS IO OFF
INSERT  
	INTO FactResellerSalesXL_PageCompressed
		(ProductKey, OrderDateKey, DueDateKey,
		ShipDateKey, ResellerKey, EmployeeKey, PromotionKey, CurrencyKey, SalesTerritoryKey,
		SalesOrderNumber, SalesOrderLineNumber, OrderQuantity, UnitPrice, SalesAmount, TaxAmt)
	SELECT TOP 2000 ProductKey, OrderDateKey, DueDateKey, 20150601, ResellerKey,
		EmployeeKey, PromotionKey, CurrencyKey, SalesTerritoryKey, SalesOrderNumber+'T', 
		SalesOrderLineNumber, OrderQuantity, UnitPrice, SalesAmount, TaxAmt
	FROM FactResellerSalesXL_CCI
	WHERE ShipDateKey BETWEEN 20121205 AND 20140101;

-- Display the newly inserted rows
SELECT * 
FROM FactResellerSalesXL_PageCompressed 
WHERE ShipDateKey = 20150601;




--LAB 3

-- 3.1 Examine the table. [Note: This table has already been created and populated with data.]

/*
CREATE TABLE dbo.SalesOrder
(
 order_id int  identity not null,
 order_date datetime not null INDEX BW_t_hkcci NONCLUSTERED,
 order_status tinyint not null,
 OrderQty int,
 Salesamount float not null,
 INDEX SalesOrder_cci CLUSTERED COLUMNSTORE,
 CONSTRAINT PK_SalesOrderID PRIMARY KEY NONCLUSTERED HASH (order_id) WITH (BUCKET_COUNT = 3000000)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
GO
*/

-- 4 Look at the row groups information
SELECT *
FROM sys.column_store_row_groups
WHERE object_id = OBJECT_ID('SalesOrder')
GO

-- 5 Compare performance on a simple select with columnstore index (here) to the hash index (next statement)
SET STATISTICS TIME ON
SET STATISTICS IO ON

SELECT COUNT(*) FROM SalesOrder
GO

-- 7 using the hash index
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO
SELECT COUNT(*) FROM SalesOrder WITH(INDEX = PK_SalesOrderId)
GO

-- 9. Compare performance on an aggregate select with columnstore index (here) to the hash index (next statement)
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO
SELECT AVG (CONVERT(bigint, SalesAmount)) FROM SalesOrder  
GO

-- 10. using the hash index
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO
SELECT AVG (CONVERT(bigint, SalesAmount)) FROM SalesOrder  WITH(INDEX = PK_SalesOrderID)
GO

-- 11 Compare performance with a natively compiled stored proc (here) to the hash index (next statement)
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO
IF OBJECT_ID('Hk_GetAvgSalesAmt') IS NOT NULL
DROP PROCEDURE Hk_GetAvgSalesAmt
GO
CREATE PROCEDURE Hk_GetAvgSalesAmt WITH SCHEMABINDING, NATIVE_COMPILATION, EXECUTE AS OWNER 
AS
BEGIN ATOMIC WITH(TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'ENGLISH')
	SELECT AVG (CONVERT(bigint, SalesAmount)) FROM dbo.SalesOrder  
END
GO
-- Execute
EXEC Hk_GetAvgSalesAmt
GO

-- 12. using the hash index
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO
SELECT AVG (CONVERT(bigint, SalesAmount)) FROM SalesOrder  WITH(INDEX = PK_SalesOrderID)
GO

-- 13 Insert performance for adding new data
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO
SELECT AVG ( SalesAmount) FROM SalesOrder --average before insertion
GO
SELECT COUNT(*) FROM SalesOrder WITH (INDEX=SalesOrder_cci)
GO
EXEC Insert10K_Rows_in_SalesOrder
GO
--Delete  from salesorder Where Order_id>11669638

-- now run again after the insert
SELECT AVG ( SalesAmount) FROM SalesOrder --average after insertion 
GO
SELECT COUNT(*) FROM SalesOrder WITH (INDEX=SalesOrder_cci)
GO

-- 16 Verify new rows are not in compressed rowgroups
SELECT *
FROM sys.column_store_row_groups
WHERE object_id = OBJECT_ID('SalesOrder')
GO

 
ALTER DATABASE AdventureWorks2016DW SET COMPATIBILITY_LEVEL=130
GO
DBCC DROPCLEANBUFFERS
GO
--17. Page Compressed main table
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO
SELECT D.CalendarYear,
		T.SalesTerritoryRegion, 
		E.FirstName + ' ' + E.LastName AS FullName,
		COUNT(*) AS NumSales,
		SUM(S.SalesAmount) AS TotalSalesAmt, 
		AVG(S.SalesAmount) AS AvgSalesAmt,
		COUNT(DISTINCT S.SalesOrderNumber) AS NumOrders, 
		COUNT(DISTINCT S.ResellerKey) AS NumResellers
	FROM FactResellerSalesXL_PageCompressed S
			INNER JOIN 
		DimSalesTerritory T 
				ON T.SalesTerritoryKey = S.SalesTerritoryKey
			INNER JOIN 
		DimEmployee E 
				ON E.Employeekey = S.EmployeeKey
			INNER JOIN 
		DimDate D 
				ON D.DateKey = S.OrderDateKey
	WHERE T.SalesTerritoryKey=3
		AND D.FullDateAlternateKey BETWEEN '1/1/2006' AND '1/1/2010'
	GROUP BY T.SalesTerritoryRegion,E.EmployeeKey, E.FirstName,E.LastName,D.CalendarYear
GO
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO


-- 18 Clustered Columnstore Index Table
-- the numbers are even more dramatic the larger the table is, this is a 11 million row table only.

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT D.CalendarYear,
		T.SalesTerritoryRegion, 
		E.FirstName + ' ' + E.LastName AS FullName,
		COUNT(*) AS NumSales,
		SUM(S.SalesAmount) AS TotalSalesAmt, 
		AVG(S.SalesAmount) AS AvgSalesAmt,
		COUNT(DISTINCT S.SalesOrderNumber) AS NumOrders, 
		COUNT(DISTINCT S.ResellerKey) AS NumResellers
	FROM FactResellerSalesXL_CCI S
			INNER JOIN 
		DimSalesTerritory T 
				ON T.SalesTerritoryKey = S.SalesTerritoryKey
			INNER JOIN 
		DimEmployee E 
				ON E.Employeekey = S.EmployeeKey
			INNER JOIN 
		DimDate D 
				ON D.DateKey = S.OrderDateKey
	WHERE T.SalesTerritoryKey=3
		AND D.FullDateAlternateKey BETWEEN '1/1/2006' AND '1/1/2010'
	GROUP BY T.SalesTerritoryRegion,E.EmployeeKey, E.FirstName,E.LastName,D.CalendarYear
GO
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO



-- 19 Space differences
sp_spaceused 'FactResellerSalesXL_CCI'
GO
sp_spaceused 'FactResellerSalesXL_PageCompressed'
GO

-- Changes from SQL 2014
-- 20. SQL 2014 did not support foreign Key constraints.. 
-- Validate there are constraints on this table
SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('FactResellerSalesXL_CCI')
SELECT * FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('FactResellerSalesXL_CCI')


-- 21 Now make change to violate constraint and it should fail.
BEGIN TRAN
	DECLARE  @SalesOrderNumber NVARCHAR(25)
	SET @SalesOrderNumber = (SELECT TOP 1 SalesOrderNumber FROM FactResellerSalesXL_CCI)
	
	UPDATE FactResellerSalesXL_CCI SET EmployeeKey = -999
		WHERE SalesOrderNumber = @SalesOrderNumber
ROLLBACK

-- How about just a normal where clause on the OrderDateKey
-- Can we see Segments eliminated in the stats IO output
-- Look at the messages Tab and you should get what Segments are being eliminated
/* Table 'FactResellerSales_CCI'. Segment reads 8, segment skipped 6. */
-- Can you get the same from the Plan? You have to look at the XML Plan
/*
 <RunTimeInformation>
     <RunTimeCountersPerThread Thread="0" ActualRows="77313" Batches="158" ActualEndOfScans="0" ActualExecutions="1" ActualExecutionMode="Batch" SegmentReads="1" SegmentSkips="11" />
 </RunTimeInformation> */
SET SHOWPLAN_XML ON
SET STATISTICS IO ON
SELECT OrderDateKey FROM FactResellerSalesXL_CCI WHERE OrderDateKey > 20141201
GO
SET STATISTICS IO OFF


-- Sort is in batch mode. Hover your mouse over the SORT operator
-- See the "ACTUAL EXECUTION MODE".. A few operators that were in Row mode now in BATCH mode.
-- SQL 14 had Row mode
set statistics io on
set statistics time on
go
select ProductKey, count(ProductKey)
from FactResellerSalesXL_CCI
Group by ProductKey
order by ProductKey
set statistics io off
set statistics time off
go

-- Batch Mode for serial ( Serial in 2014 was row mode)
-- Again hover over the SCAN, in 2014 this would be ROW mode.
set statistics io on
set statistics time on
go
select ProductKey, sum(TotalProductCost)
from FactResellerSalesXL_CCI
Group by ProductKey
option(maxdop 1)
go
set statistics io off
set statistics time off
go


-- Multiple distinct batch mode ( was row mode in SQL 2014)
-- In SQL 2014 the hash match would be ROW mode, and all upstream operators would be row mode.
set statistics io on
set statistics time on
go
SELECT     ProductKey
		 , COUNT(DISTINCT rs.EmployeeKey) AS  NumEmployees
		 , COUNT(DISTINCT rs.ResellerKey) AS  NumResellers
FROM       dbo.FactResellerSalesXL_CCI    AS  rs
   WHERE      rs.SalesTerritoryKey    >=  8
GROUP BY   ProductKey
ORDER BY   ProductKey;
go
set statistics io off
set statistics time off
go

set statistics io on
set statistics time on
go
SELECT     ProductKey
		 , COUNT(DISTINCT rs.EmployeeKey) AS  NumEmployees
		 , COUNT(DISTINCT rs.ResellerKey) AS  NumResellers
FROM       dbo.[FactResellerSalesXL_PageCompressed]    AS  rs
   WHERE      rs.SalesTerritoryKey    >=  8
GROUP BY   ProductKey
ORDER BY   ProductKey;
go
set statistics io off
set statistics time off
go


-- Aggregate Pushdown 
-- Scalar aggregate pushdown without groupby is implemented.
select  max(TotalProductCost)
from FactResellerSalesXL_CCI



-- Look at the Query Plan, you will see the Predicate pushed to the SCAN
select CustomerPONumber from FactResellerSalesXL_CCI where CustomerPONumber = N'PO1022545'



-- What abount Narrow lookups
-- See Missing index for this Plan
-- Also notice NO segments were eliminated . There is an optimization where you see a PROBE BITMAP filter pushed to the SCAN
/* Table 'FactResellerSales_CCI'. Segment reads 13, segment skipped 0. */
/*
 SQL Server Execution Times:
   CPU time = 63 ms,  elapsed time = 468 ms.
*/
DBCC DROPCLEANBUFFERS
go
set statistics time on
set statistics io on
go
select OrderDate,SalesAmount
from FactResellerSalesXL_CCI a
inner join DimReseller b on a.ResellerKey = b.ResellerKey
where b.ResellerName = 'Wheels Inc.'
go
set statistics time off
set statistics io off
go


-- What if we create the missing index? Missing index
/*
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 378 ms.
*/
-- Drop index [FactResellerSales_CCI].IndFactResellerSales_CCI_NCI
CREATE NONCLUSTERED INDEX IndFactResellerSalesXL_CCI_NCI
ON [dbo].[FactResellerSalesXL_CCI] ([ResellerKey])
INCLUDE ([SalesAmount],[OrderDate])

-- After NCI creation what does the plan look like?
-- Notice the Join has changed from Hash join to a nested loop join
-- Also the inner branch of the nested loop is a seek
-- And IO done is far less and time should be less too in particular CPU time
DBCC DROPCLEANBUFFERS
go
select OrderDate,SalesAmount
from FactResellerSalesXL_CCI a
inner join DimReseller b on a.ResellerKey = b.ResellerKey
where b.ResellerName = 'Wheels Inc.'


-- RCSI now supported now, which means you can have CCI on AlwaysOn secondaries
Alter database AdventureWorks2016DW SET READ_COMMITTED_SNAPSHOT ON
GO
Alter database AdventureWorks2016DW SET ALLOW_SNAPSHOT_ISOLATION ON
GO

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRAN
select top 100 * from FactResellerSales_CCI
COMMIT
GO



-- Metadata for CCI
-- This is a new DMV that gives you Usage data like index operational stats for columnstores
-- You can see which rowgroups are scanned how often, locking on rowgroups, latching on row groups
-- Also io_latch waits on rowgroups that indicate Io bottleneck
select * from sys.dm_db_column_store_row_group_operational_stats


-- New DMV
-- See in particular the trim_reason_description which will give you why the rowgroup was closed ( if at all ) before the 1 million mark
-- In this case all of them have 1 million except one, which has the trim_reason_description as REORG
select * from sys.dm_db_column_store_row_group_physical_stats


-- Do we see NCI metadata?
-- Should appear like any Non clustered index.
select * from sys.dm_db_index_operational_stats(NULL,NULL,NULL,NULL)
where database_id = db_id()
and object_id=object_id('FactResellerSalesXL_CCI')



/*
-- Batch mode for Windows aggregates
SELECT ProductKey , OrderDateKey
, LEAD(OrderQuantity, 1,0) OVER (ORDER BY OrderDateKey) AS NextQuota
FROM FactResellerSalesXL_CCI
WHERE  orderdatekey in ( 20060301,20060401)*/


-- new additions --
-- Demo parallel Insert from staging table

drop table FactResellerSalesXL_CCI_temp
go

-- create ccitest_temp and enable columncompression
select * into  FactResellerSalesXL_CCI_temp from FactResellerSalesXL_CCI where 1=2
create clustered columnstore index cci_temp on  FactResellerSalesXL_CCI_temp

-- Note this inserts rows in parallel
insert into FactResellerSalesXL_CCI_temp with (TABLOCK) select top 100000 * from FactResellerSalesXL_CCI

-- check the rowgroups created.
-- you will notice each DOP thread creates its own delta rowgroup. The compressed rowgproup will only be created 
-- if number of rows inserted by a thread is > 100k
select * from sys.dm_db_column_store_row_group_physical_stats 
where object_id = object_id('FactResellerSalesXL_CCI_temp')

-- let us now force the compression of all rowgroups
alter index cci_temp on FactResellerSalesXL_CCI_temp reorganize WITH (COMPRESS_ALL_ROW_GROUPS = ON)

-- run the following DMV to note that all delta RGs were compressed
-- Also note, that this DMV provides much richer set of information such as why a rowgroup was compressed
select * from sys.dm_db_column_store_row_group_physical_stats where object_id = object_id('FactResellerSalesXL_CCI_temp')

-- now we will delete a subset of rows 
delete FactResellerSalesXL_CCI_temp where productkey%2 = 0
-- run the following DMV to note the deleted rows
select * from sys.dm_db_column_store_row_group_physical_stats where object_id = object_id('FactResellerSalesXL_CCI_temp')


-- we will now run REORG command to defragement the columnstore index by removing deleted rows
alter index cci_temp on FactResellerSalesXL_CCI_temp reorganize

-- run the following DMV to note that deleted rows were removed
select * from sys.dm_db_column_store_row_group_physical_stats where object_id = object_id('FactResellerSalesXL_CCI_temp')


select top 1 productkey from FactResellerSalesXL_CCI
