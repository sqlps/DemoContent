--
-- RUN Script
--
SET STATISTICS TIME ON
GO

--
-- 1. Try to run for traditional index database and table. Cancel the query because it is too long
--
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

--
-- 2. Try to run for Non-Clustered Columnstore index database and table. This should be significantly faster especially if you pre-run this to populate the buffer cache.
--
USE AdventureWorksDW2008Big_NCCI
GO
SELECT
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactSales f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey in (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO

--
-- 3. Try again for Clustered Columnstore index database and table. This should be similar speed with Non-Clustered Columnstore Index
--
USE AdventureWorksDW2008Big_CCI
GO
SELECT
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactSales f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey in (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO

-- 4. Non-Clustered Columnstore Index is not updateable. The query below should generate error.
USE AdventureWorksDW2008Big_NCCI
GO
INSERT FactSales
	SELECT * FROM FactResellerSalesCache
GO

-- 5. However, Clustered Columnstore Index is updateable
USE AdventureWorksDW2008Big_CCI
GO
INSERT FactSales
	SELECT * FROM FactResellerSalesCache
GO

-- 6. Plus, Clustered Columnstore Index uses less space because of compression. Run 6a and 6b together to see the comparison.

-- 6a. Check disk space used by Non Clustered Columnstore Index
USE AdventureWorksDW2008Big_NCCI
GO

SELECT SUM(on_disk_size_MB) AS NonClusteredTotalSizeInMB
FROM
(
   (SELECT SUM(css.on_disk_size)/(1024.0*1024.0) on_disk_size_MB
    FROM sys.indexes AS i
    JOIN sys.partitions AS p
        ON i.object_id = p.object_id 
    JOIN sys.column_store_segments AS css
        ON css.hobt_id = p.hobt_id
    WHERE i.object_id = object_id('FactSales') 
    AND i.type_desc = 'NONCLUSTERED COLUMNSTORE') 
  UNION ALL
   (SELECT SUM(csd.on_disk_size)/(1024.0*1024.0) on_disk_size_MB
    FROM sys.indexes AS i
    JOIN sys.partitions AS p
        ON i.object_id = p.object_id 
    JOIN sys.column_store_dictionaries AS csd
        ON csd.hobt_id = p.hobt_id
    WHERE i.object_id = object_id('FactSales') 
    AND i.type_desc = 'NONCLUSTERED COLUMNSTORE') 
) AS SegmentsPlusDictionary

-- 6b. Check disk space used by Clustered Columnstore Index
USE AdventureWorksDW2008Big_CCI
GO

SELECT SUM(on_disk_size_MB) AS ClusteredTotalSizeInMB
FROM
(
   (SELECT SUM(css.on_disk_size)/(1024.0*1024.0) on_disk_size_MB
    FROM sys.indexes AS i
    JOIN sys.partitions AS p
        ON i.object_id = p.object_id 
    JOIN sys.column_store_segments AS css
        ON css.hobt_id = p.hobt_id
    WHERE i.object_id = object_id('FactSales') 
    AND i.type_desc = 'CLUSTERED COLUMNSTORE') 
  UNION ALL
   (SELECT SUM(csd.on_disk_size)/(1024.0*1024.0) on_disk_size_MB
    FROM sys.indexes AS i
    JOIN sys.partitions AS p
        ON i.object_id = p.object_id 
    JOIN sys.column_store_dictionaries AS csd
        ON csd.hobt_id = p.hobt_id
    WHERE i.object_id = object_id('FactSales') 
    AND i.type_desc = 'CLUSTERED COLUMNSTORE') 
) AS SegmentsPlusDictionary