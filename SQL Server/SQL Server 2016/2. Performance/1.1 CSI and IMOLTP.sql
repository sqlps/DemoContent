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
-- Step 2) Compare Performance
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

-- ==================================================================
-- Step 3)Add 100K of records... Maybe more
-- ==================================================================

EXEC Insert100K_Rows_in_FactSales_InMem
GO 
--Delete  from salesorder Where Order_id>11669638

-- now run again after the insert
SELECT AVG ( SalesAmount) FROM FactSales_Inmem --average after insertion 
GO
SELECT COUNT(*) FROM FactSales_Inmem 
GO

-- ==================================================================
-- Step 4) Compare Typical Aggregation CSI vs Regular
-- ==================================================================

Select Count (*) AS 'Count FactSales_InMem' From FactSales_Inmem
Select Count (*) AS 'Count FactSales_Regular' From FactSales_Regular
GO

SELECT
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactSales_Inmem f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey in (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO

SELECT
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactSales_Regular f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey in (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO
