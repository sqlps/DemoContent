/*
USE [master]
GO
RESTORE DATABASE [AdventureWorks2016DW] 
FROM  DISK = N'H:\CCITests\AdvworksDW2014_modified.bak' WITH  FILE = 1,  
MOVE N'AdventureWorks2016DW_Data' TO N'F:\Datactp1\AdventureWorks2016DW_Data.mdf',
MOVE N'AdventureWorks2016DW_Log' TO N'F:\logctp1\AdventureWorks2016DW_Log.ldf',  
NOUNLOAD,  STATS = 5
GO
*/


-- Page Compressed BTree
-- Sure there is a missing index but think of it, you aggregate on a different column,it would require a different index on rowstore.
-- THat in turn can affect loads.
-- Enable Query Plan ( actual ) 
/*
 SQL Server Execution Times:
   CPU time = 26273 ms,  elapsed time = 629 ms.
*/
Use AdventureWorks2016DW
go


alter database AdventureWorks2016DW set compatibility_level = 130
GO
DBCC DROPCLEANBUFFERS
go
set statistics io on
set statistics time on
go
-- CPU time = 22750 ms,  elapsed time = 4031 ms.
select c.CalendarYear,b.SalesTerritoryRegion, FirstName + ' ' + LastName as FullName,
count(SalesOrderNumber) as NumSales,sum(SalesAmount) as TotalSalesAmt , Avg(SalesAmount) as AvgSalesAmt
,count(distinct SalesOrderNumber) as NumOrders, count(distinct ResellerKey) as NumResellers
from FactResellerSalesXL_PageCompressed a
inner join DimSalesTerritory b on b.SalesTerritoryKey = a.SalesTerritoryKey
inner join DimEmployee d on d.Employeekey = a.EmployeeKey
inner join DimDate c on c.DateKey = a.OrderDateKey
where b.SalesTerritoryKey=3
and c.FullDateAlternateKey between '1/1/2006' and '1/1/2010'
Group by b.SalesTerritoryRegion,d.EmployeeKey, d.FirstName,d.LastName,c.CalendarYear
go
set statistics io off
set statistics time off
go



-- CCI Table
-- the numbers are even more dramatic the larger the table is, this is a 11 million row table only.
--CPU time = 531 ms,  elapsed time = 652 ms.
set statistics io on
set statistics time on
go
select b.SalesTerritoryRegion, FirstName + ' ' + LastName as FullName,
count(SalesOrderNumber) as NumSales,sum(SalesAmount) as TotalSalesAmt , Avg(SalesAmount) as AvgSalesAmt
,count(distinct SalesOrderNumber) as NumOrders, count(distinct ResellerKey) as NumResellers
from FactResellerSalesXL_CCI a
inner join DimSalesTerritory b on b.SalesTerritoryKey = a.SalesTerritoryKey
inner join DimEmployee d on d.Employeekey = a.EmployeeKey
inner join DimDate c on c.DateKey = a.OrderDateKey
where b.SalesTerritoryKey=3
and c.FullDateAlternateKey between '1/1/2006' and '1/1/2010'
Group by b.SalesTerritoryRegion,d.EmployeeKey, d.FirstName,d.LastName,c.CalendarYear
go
set statistics io off
set statistics time off
go



-- How about space? Data space is much smaller ( 2X smaller than a Page Compressed Table)
-- The difference is less as we have a Primary Key on the table that creates a Unique Non-clustered index.
sp_spaceused 'FactResellerSalesXL_CCI'
GO
sp_spaceused 'FactResellerSalesXL_PageCompressed'
GO

-- Changes from SQL 2014
-- SQL 2014 did not support foreign Key constraints.. 
-- Validate there are constraints on this table
select * from sys.indexes where object_id = object_id('FactResellerSalesXL_CCI')
select * from sys.foreign_keys where parent_object_id = object_id('FactResellerSalesXL_CCI')


-- Now make change to violate constraint and it should fail.
begin tran
	declare  @SalesOrderNumber nvarchar(25)
	set @SalesOrderNumber = (select top 1 SalesOrderNumber from FactResellerSalesXL_CCI)
	
	update FactResellerSalesXL_CCI set ProductKey = -999
	where SalesOrderNumber = @SalesOrderNumber
rollback




-- How about just a normal where clause on the OrderDateKey
-- Can we see Segments eliminated in the stats IO output
-- Look at the messages Tab and you should get what Segments are being eliminated
/* Table 'FactResellerSales_CCI'. Segment reads 1, segment skipped 11. */
-- Can you get the same from the Plan? You have to look at the XML Plan
/*
 <RunTimeInformation>
     <RunTimeCountersPerThread Thread="0" ActualRows="77313" Batches="158" ActualEndOfScans="0" ActualExecutions="1" ActualExecutionMode="Batch" SegmentReads="1" SegmentSkips="11" />
 </RunTimeInformation> */
set statistics io on
select  OrderDateKey from FactResellerSalesXL_CCI where OrderDateKey > 20141201
go
set statistics io off


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



