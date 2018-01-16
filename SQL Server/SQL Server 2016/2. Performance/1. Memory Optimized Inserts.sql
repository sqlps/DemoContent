-- =====================================================================================================
-- Step 1) What are the memory optimized Tables?
-- =====================================================================================================
Use AdventureWorks2016CTP3
GO
SELECT name, object_id, type, type_desc, is_memory_optimized, durability, durability_desc
FROM sys.tables
WHERE is_memory_optimized=1

-- =====================================================================================================
-- Step 2) What are the current counts
-- =====================================================================================================
--Delete from sales.[SalesOrderDetail_ondisk]
--where modifieddate > '2016-01-01'

select count(*) from sales.[SalesOrderDetail_inmem2]
GO
select count(*) from sales.[SalesOrderDetail_ondisk]
GO 

--select * from db.sys.dm_db_xtp_checkpoint_stats 
-- =====================================================================================================
-- Step 3) Run the Ostress and open Perfmon. Takes about 2 mins to run
-- =====================================================================================================

-- C:\Demos\SQLServer 2016\2. Performance\In-Memory OLTP

-- =====================================================================================================
-- Step 4) Explain enhancements in In-Memory OLTP
-- =====================================================================================================
/*
Key Points:
-- Documentation: https://msdn.microsoft.com/en-us/library/bb510411.aspx#InMemory

1) ALTER Table and Proc
2) Up to 2 TB
3) Parallel PLan support
4) LOB Support
5) No longer need data collectors to eval candidates
6) FK, Check and Unique constraints
7) Triggers
8) Native procs now support OR, NOT, UNION and UNION ALL, SELECT DISTINCT, OUTER JOIN, subqueries in SELECT
9) Stats Auto Update
*/

-- =====================================================================================================
-- Step 5) Re-Run the Ostress with In-mem option and open Perfmon. Takes about 2 mins to run
-- =====================================================================================================

-- C:\Demos\SQLServer 2016\2. Performance\In-Memory OLTP
--Re Run validation
select count(*) from sales.[SalesOrderDetail_inmem2]
GO
select count(*) from sales.[SalesOrderDetail_ondisk]
GO 




