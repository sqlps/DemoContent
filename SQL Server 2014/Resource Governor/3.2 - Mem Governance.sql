--------------------------------------------------
-- 1 - Enable graphical Execution Plan
--------------------------------------------------

--------------------------------------------------
-- 2 - Clear the buffer pool cache
--------------------------------------------------
DBCC DROPCLEANBUFFERS

-------------------------------------------------------
-- 3 - How much memory is being used by the buffer pool
-------------------------------------------------------
 SELECT count(*)*8  AS size_kb
    ,CASE database_id 
        WHEN 32767 THEN 'ResourceDb' 
        ELSE db_name(database_id) 
        END AS Database_name
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY 1 DESC;

-------------------------------------------------------------------------------
-- 3 - Run a simple query that needs 0 memory grant but large buffer pool alloc
-------------------------------------------------------------------------------
Use AdventureWorksDW2008
Go
Select top 1000000 * from FactResellerSales
go

----------------------------------------------------------------------
-- 4 - Look at the Excution Plan XML and confirm the memory grant is 0
----------------------------------------------------------------------

----------------------------------------------------------------------
-- 5 - How much memory is being used by the buffer pool now?
----------------------------------------------------------------------
-- How much space in the buffer cache is each database taking?
 SELECT count(*)*8  AS size_kb
    ,CASE database_id 
        WHEN 32767 THEN 'ResourceDb' 
        ELSE db_name(database_id) 
        END AS Database_name
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY 1 DESC;

--271344KB
---------------------------------------------------------------------------------------------------------------
-- 6 - Now run a query that needs > 15MB memory grant. RG should be configured with a 1% of 1500MB for max mem
---------------------------------------------------------------------------------------------------------------
DBCC DROPCLEANBUFFERS
GO
-- How much space in the buffer cache is each database taking?
 SELECT count(*)*8  AS size_kb
    ,CASE database_id 
        WHEN 32767 THEN 'ResourceDb' 
        ELSE db_name(database_id) 
        END AS Database_name
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY 1 DESC;
--Run the query
SELECT
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactResellerSales_CCI f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey in (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO
--OH NO!!!

---------------------------------------------------------------------------------------------------------------
-- 7 - Reconfigure RG to allow for 150MB memory grant and re-run a query that needs > 15MB memory grant. 
---------------------------------------------------------------------------------------------------------------
ALTER RESOURCE POOL [Customer1] WITH(max_memory_percent=10)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

DBCC DROPCLEANBUFFERS
GO

-- How much space in the buffer cache is each database taking?
 SELECT count(*)*8  AS size_kb
    ,CASE database_id 
        WHEN 32767 THEN 'ResourceDb' 
        ELSE db_name(database_id) 
        END AS Database_name
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY 1 DESC;

--Run the query
SELECT
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactResellerSales_CCI f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey in (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO

-- How much space in the buffer cache is each database taking?
 SELECT count(*)*8  AS size_kb
    ,CASE database_id 
        WHEN 32767 THEN 'ResourceDb' 
        ELSE db_name(database_id) 
        END AS Database_name
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY 1 DESC;


