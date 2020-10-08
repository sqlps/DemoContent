Use AdventureWorks2016DW
GO

-- ==================================================================
-- Step 1) Look at MetaData
-- ==================================================================

-- 1 Shows allocated and used memory of user and system tables.
Select object_name(object_id) as 'Table Name', memory_allocated_for_table_kb, memory_used_by_table_kb
from sys.dm_db_xtp_table_memory_stats 

-- 2 Look at the row groups information
SELECT *
FROM sys.column_store_row_groups
WHERE object_id = OBJECT_ID('FactSales_Inmem')
GO

-- ==================================================================
-- Step 2) Compare Performance. Enable Actual Exec Plan
-- ==================================================================
SET STATISTICS TIME ON
SET STATISTICS IO ON

SELECT COUNT(*) FROM FactSales_Inmem
GO
SELECT COUNT(*) FROM FactSales_InMem
WITH(INDEX = PK__FactSale__61B41DCCC4217218)

SET STATISTICS TIME ON
SET STATISTICS IO ON
GO
SELECT AVG (CONVERT(bigint, SalesAmount)) FROM FactSales_Inmem  
GO
SELECT AVG (CONVERT(bigint, SalesAmount)) FROM FactSales_Inmem  
WITH(INDEX = PK__FactSale__61B41DCCC4217218)
GO

Select * from FactSales_Inmem
Where pk_FactSales = 1000000
GO

Select * from FactSales_Inmem
WITH (INDEX = FactSales_InMem_cci)
Where pk_FactSales = 1000000

GO
SET STATISTICS TIME OFF
SET STATISTICS IO OFF
-- ==================================================================
-- Step 3)Add some records... Maybe more
-- ==================================================================

-- Open Report http://sql2016-sql2/Reports

--EXEC Insert100K_Rows_in_FactSales_InMem
exec usp_Load10KRows
GO 1000
--Delete  from salesorder Where Order_id>11669638

-- 2 Look at the row groups information
SELECT *
FROM sys.column_store_row_groups
WHERE object_id = OBJECT_ID('FactSales_Inmem')
GO
