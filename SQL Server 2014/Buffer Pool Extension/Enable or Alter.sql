-- ===================================
-- Step 1) Set limits on SQL Server
-- ===================================
sp_configure 'show advanced options', 1
Reconfigure

EXEC sp_configure 'min server memory (MB)', 1000;
GO
EXEC sp_configure 'max server memory (MB)', 2000;
GO
RECONFIGURE;
GO

-- ===================================
-- Step 2) Enable BPE
-- ===================================

ALTER SERVER CONFIGURATION 
SET BUFFER POOL EXTENSION ON
    (FILENAME = 'D:\Data\Example.BPE', SIZE = 16 GB); --1:4 nor more than 1:8
Go

-- ===================================
-- Step 3) Wreak Havoc
-- ===================================
Set Statistics IO On
go

--Load Some Data
select f.SalesTerritoryKey, t.SalesTerritoryCountry, d.CalendarQuarter, COUNT(*) SalesCount, SUM(f.SalesAmount) SalesAmount
from AdventureWorksDW2008..FactResellerSales f, AdventureWorksDW2008..DimSalesTerritory t, AdventureWorksDW2008..DimDate d
where f.SalesTerritoryKey = t.SalesTerritoryKey
and f.OrderDateKey = d.DateKey
and d.CalendarYear <> 2005
and t.SalesTerritoryCountry <> 'United States'
group by f.SalesTerritoryKey, t.SalesTerritoryCountry, d.CalendarQuarter
order by d.CalendarQuarter asc, SUM(f.SalesAmount) desc, t.SalesTerritoryCountry asc;

--Run big query to cause memory pressure but stop after some time
USE AdventureWorksDW2008Big
GO
SELECT 
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactSales f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey IN (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO

-- ===================================
-- Step 3) What's in the BPE
-- ===================================

-- Check the buffer descriptors
Select * from sys.dm_os_buffer_descriptors
where is_in_bpool_extension = 1

-- What DB?
Select db_name(10)

Use AdventureWorksDW2008Big
go

--Check the details of a page
DBCC TRACEON (3604);
GO

DBCC PAGE(10,1,4012228,3)

-- What Table?
Select OBJECT_NAME(1214627370)

-- ===================================
-- Step 4) Factory Reset
-- ===================================
EXEC sp_configure 'max server memory (MB)', 12000;
GO
RECONFIGURE;
GO

--Diable BPE
ALTER SERVER CONFIGURATION SET BUFFER POOL EXTENSION OFF
GO 