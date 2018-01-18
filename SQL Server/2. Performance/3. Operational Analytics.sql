-- =====================================================================================================
-- Documentation: https://msdn.microsoft.com/en-us/library/bb510411.aspx#columnstore
-- =====================================================================================================
/*
Key Points:
-- TIP: Run Ostress first then explain
-- 

1) Updateable NCCI after upgrade for operational analytics
2) CCI can have secondary B-Tree Indexes
3) String(Filter on string) and aggregate (ex count(*) group by) predicate pushdown
4) Reorg eliminates fragmentation caused by deletes
5) Batch mode supported with non-parallel plan
6) Support for constraints
*/
Use Adventureworks2016CTP3
GO
-- =====================================================================================================
-- Step 1) What are the current counts
-- =====================================================================================================
select count(*) from sales.[SalesOrderDetail_inmem2]
GO
select count(*) from sales.[SalesOrderDetail_ondisk]
GO 

-- =====================================================================================================
-- Step 2) Run the Ostress and open Perfmon. Takes about 2 mins to run
-- =====================================================================================================
-- C:\Demos\SQLServer 2016\2. Performance\Operational Analytics\Load 1M DiskBased.bat

-- =====================================================================================================
-- Step 3) Explain Operational Analytics
-- =====================================================================================================
-- What does Operational Analytics solve for?
-- Launch http://sql2016c3-sql1/Reports/Pages/Report.aspx?ItemPath=%2fOperational+Analytics%2fOperational+Analytics+(Disk+Based)

-- =====================================================================================================
-- Step 4) View the NCCI Metadata
-- =====================================================================================================

-- Script out NCCI on [SalesOrderDetail_ondisk].
-- Look at _Setup - Operation Analytics. Explain In-mem config

-- Check counts 
select count(*) from sales.[SalesOrderDetail_ondisk]
GO 

--Check Column Store Metadata
SELECT i.object_id, 
    object_name(i.object_id) AS TableName, 
    i.name AS IndexName, 
	total_rows,
    i.index_id, 
	    i.type_desc, 
    CSRowGroups.*,
    100*(ISNULL(deleted_rows,0))/total_rows AS 'Fragmentation'
FROM sys.indexes AS i
JOIN sys.dm_db_column_store_row_group_physical_stats AS CSRowGroups
    ON i.object_id = CSRowGroups.object_id AND i.index_id = CSRowGroups.index_id 
-- WHERE object_name(i.object_id) = 'table_name' 
ORDER BY object_name(i.object_id), i.name, row_group_id;


-- =====================================================================================================
-- Step 5) Run the Ostress and open Perfmon for inmem
-- =====================================================================================================
-- C:\Demos\SQLServer 2016\2. Performance\Operational Analytics\Load 1M In_mem.bat

-- =====================================================================================================
-- Step 6) Review the DDL for In-Mem under _Setup - Operational Analytics
-- =====================================================================================================
-- Check counts 
select count(*) from sales.[SalesOrderDetail_inmem2]
GO 

select object_name(object_id), * from sys.dm_db_column_store_row_group_physical_stats
where object_name(object_id) = 'SalesOrderDetail_inmem2'

