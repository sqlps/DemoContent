-- Hands on Lab: JSON
USE AdventureWorks2014
GO

-- Lab 1. Query data into JSON output
-- 1.1 Query the data in its relational format
SELECT TOP 10 H.SalesOrderNumber, H.OrderDate,
D.UnitPrice,D.OrderQty
FROM Sales.SalesOrderHeader H  
INNER JOIN Sales.SalesOrderDetail DON H.SalesOrderID = D.SalesOrderID
GO

-- 1.2 Now return the output as JSON
SELECT TOP 10 H.SalesOrderNumber, H.OrderDate,
D.UnitPrice,D.OrderQty
FROM Sales.SalesOrderHeader H  
INNER JOIN Sales.SalesOrderDetail DON H.SalesOrderID = D.SalesOrderID
FOR JSON AUTO
GO

-- 1.3 Get familiar with JSON data structure by looking at only a couple of records
SELECT H.SalesOrderNumber, H.OrderDate,
D.UnitPrice,D.OrderQty
FROM Sales.SalesOrderHeader H  
INNER JOIN Sales.SalesOrderDetail DON H.SalesOrderID = D.SalesOrderID
WHERE H.SalesOrderID IN (43660, 43669)
FOR JSON AUTO
GO

-- 1.4 Add a root key
SELECT H.SalesOrderNumber, H.OrderDate,
D.UnitPrice,D.OrderQty
FROM Sales.SalesOrderHeader H  
INNER JOIN Sales.SalesOrderDetail DON H.SalesOrderID = D.SalesOrderID
WHERE H.SalesOrderID IN (43660, 43669)
FOR JSON AUTO, ROOT ('SalesOrder')
GO


-- Lab 2. Using FOR JSON PATH and other control structures
-- 2.1 Start with a regular query for product information
SELECT TOP 7 M.ProductModelID, M.Name, 
ProductID, P.Name, ProductNumber, MakeFlag,
FinishedGoodsFlag, Color, Size, SafetyStockLevel, ReorderPoint, SellStartDate
FROM Production.Product P
INNER JOIN Production.ProductModel M ON P.ProductModelID = M.ProductModelID
GO

-- 2.2 Modify JSON structure with FOR JSON PATH
SELECT TOP 7 M.ProductModelID, M.Name AS [ProductModel.Name], 
ProductID, P.Name AS [Product.Name], ProductNumber, MakeFlag,
FinishedGoodsFlag, Color, Size, SafetyStockLevel, ReorderPoint, SellStartDate
FROM Production.Product P
INNER JOIN Production.ProductModel M ON P.ProductModelID = M.ProductModelID
FOR JSON PATH
GO

-- 2.3 Handle NULL values --Notice the Size attribute is not in result set
SELECT M.ProductModelID, M.Name AS [ProductModel.Name], 
ProductID, P.Name AS [Product.Name], Size
FROM Production.Product P
INNER JOIN Production.ProductModel M ON P.ProductModelID = M.ProductModelID
WHERE M.ProductModelID = 33
FOR JSON PATH
GO

--Size is displayed here because of the INCLUDE_NULL_VALUES
SELECT M.ProductModelID, M.Name AS [ProductModel.Name], 
ProductID, P.Name AS [Product.Name], Size
FROM Production.Product P
INNER JOIN Production.ProductModel M ON P.ProductModelID = M.ProductModelID
WHERE M.ProductModelID = 33
FOR JSON PATH, INCLUDE_NULL_VALUES 
GO

-- 2.4 Alternate method with nested queries
SELECT M.ProductModelID, M.Name AS [ProductModel.Name], 
	(SELECT ProductID, P.Name AS [Product.Name], Size
	 FROM Production.Product P
	 WHERE P.ProductModelID = M.ProductModelID
	 FOR JSON PATH) AS P 
FROM Production.ProductModel M 
WHERE M.ProductModelID = 33
FOR JSON PATH
GO


-- Lab 3. Import JSON document to Azure DocumentDB
-- 3.1 Retrieve product records as JSON
SELECT TOP 7 M.ProductModelID, M.Name AS [ProductModel.Name], 
ProductID, P.Name AS [Product.Name], ProductNumber, MakeFlag,
FinishedGoodsFlag, Color, Size, SafetyStockLevel, ReorderPoint, SellStartDate
FROM Production.Product P
INNER JOIN Production.ProductModel M ON P.ProductModelID = M.ProductModelID
FOR JSON PATH, ROOT('ProductModel')
GO



