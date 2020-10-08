-- =============== Start of indexes demo

-- sample database: [http://msdn.microsoft.com/en-us/library/dn511655.aspx]

/********************************
 * RESTORE DB BY RUNNING _Setup *
 ********************************/
Use Adventureworks2014
Go

-- observe memory-optimized tables
SELECT name, object_id, is_memory_optimized, durability, durability_desc 
FROM sys.tables 
WHERE type='U' and is_memory_optimized=1
GO
-- query indexes on memory-optimized tables
SELECT 
	t.name as 'table', 
	t.object_id, 
	i.name as 'index', 
	i.index_id,
	i.type, 
	i.type_desc, 
	i.is_unique
FROM sys.indexes i join sys.tables t on i.object_id=t.object_id 
WHERE t.type='U' and t.is_memory_optimized=1 and t.name not like 'Demo%'
ORDER BY t.name, i.index_id
GO

--inspect object explorer, indexes on Production.Product_inmem

-- point lookups using hash
SELECT ProductID, Name, ProductNumber
FROM Production.Product_inmem
WHERE ProductID=2

SELECT sod.SalesOrderID, sod.SalesOrderDetailID, p.ProductID, p.Name, p.ProductNumber
FROM Sales.SalesOrderDetail_inmem sod join Production.Product_inmem p on sod.ProductID=p.ProductID
WHERE sod.SalesOrderID=48374
GO

-- attempt range scan [not supported with a hash index]
SELECT ProductID, Name, ProductNumber
FROM Production.Product_inmem
WHERE ProductID > 2
GO

-- sort [not supported with hash index]
SELECT ProductID, Name, ProductNumber
FROM Production.Product_inmem
ORDER BY ProductID
GO

-- point lookup using nonclustered
SELECT ProductID, Name, ProductNumber
FROM Production.Product_inmem
WHERE Name=N'Bearing Ball'
GO

-- range scan
SELECT ProductID, Name, ProductNumber
FROM Production.Product_inmem
WHERE Name < N'Chain'

SELECT ProductID, Name, ProductNumber
FROM Production.Product_inmem
WHERE Name LIKE N'Chain%'
GO


-- sort 
SELECT ProductID, Name, ProductNumber
FROM Production.Product_inmem
ORDER BY Name
GO
-- ================================ End of indexes demo



