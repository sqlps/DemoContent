/* This Sample Code is provided for the purpose of illustration only and is not intended
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys fees, that arise or
result from the use or distribution of the Sample Code.*/

--
-- AdventureWorksDW Setup Script
--

USE master
GO

--
-- Drop all existing databases
--
DROP DATABASE AdventureWorksDW2008Big
DROP DATABASE AdventureWorksDW2008Big_NCCI
DROP DATABASE AdventureWorksDW2008Big_CCI
GO

--
-- Restore all databases (2:30 locally)
--
RESTORE DATABASE AdventureWorksDW2008Big FROM  DISK = N'D:\Demos\SQL 2014\In-Memory CSI\AdventureWorksDW2008Big.bak' WITH  FILE = 1,  
MOVE N'AdventureWorksDW2008_Data' TO N'E:\SQLDATA\AdventureWorksDW2008Big.mdf',  
MOVE N'AdventureWorksDW2008_Log' TO N'E:\SQLDATA\AdventureWorksDW2008Big.ldf',  NOUNLOAD,  STATS = 5
GO

RESTORE DATABASE AdventureWorksDW2008Big_NCCI FROM  DISK = N'D:\Demos\SQL 2014\In-Memory CSI\AdventureWorksDW2008Big.bak' WITH  FILE = 1,  
MOVE N'AdventureWorksDW2008_Data' TO N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2008Big_NCCI.mdf',  
MOVE N'AdventureWorksDW2008_Log' TO N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2008Big_NCCI.ldf',  NOUNLOAD,  STATS = 5
GO

RESTORE DATABASE AdventureWorksDW2008Big_CCI FROM  DISK = N'D:\Demos\SQL 2014\In-Memory CSI\AdventureWorksDW2008Big.bak' WITH  FILE = 1,  
MOVE N'AdventureWorksDW2008_Data' TO N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2008Big_CCI.mdf',
MOVE N'AdventureWorksDW2008_Log' TO N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2008Big_CCI.ldf',  NOUNLOAD,  STATS = 5
GO


--
-- Prepare AdventureWorksDW2008Big
--
USE AdventureWorksDW2008Big
GO

UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'International' WHERE EnglishProductSubcategoryName = 'Mountain Bikes'
UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'US Domestic' WHERE EnglishProductSubcategoryName = 'Road Bikes'
UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'North America' WHERE EnglishProductSubcategoryName = 'Touring Bikes'
GO

SELECT * FROM DimProductSubcategory WHERE ProductSubcategoryKey in (1, 2, 3)
GO

SELECT * INTO FactResellerSalesCache
FROM FactResellerSalesPart
WHERE OrderDateKey = (SELECT MAX(OrderDateKey) FROM FactResellerSalesPart)
GO

DELETE FROM FactResellerSalesPart 
WHERE OrderDateKey = (SELECT MAX(OrderDateKey) FROM FactResellerSalesPart)
GO

SELECT * INTO FactSales
FROM FactResellerSalesPart  --where SalesOrderLineNumber%2 = 1
GO

CREATE CLUSTERED INDEX ci ON FactSales (OrderDateKey)
CREATE INDEX ix1 ON FactSales (ProductKey)
CREATE INDEX ix2 ON FactSales (ShipDateKey)
CREATE INDEX ix7 ON FactSales (ResellerKey)
CREATE INDEX ix3 ON FactSales (EmployeeKey)
CREATE INDEX ix4 ON FactSales (PromotionKey)
CREATE INDEX ix5 ON FactSales (CurrencyKey)
CREATE INDEX ix6 ON FactSales (SalesTerritoryKey)
GO


--
-- Prepare AdventureWorksDW2008Big_NCCI (Non Clustered Columnstore Index)
--
USE AdventureWorksDW2008Big_NCCI
GO

UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'International' WHERE EnglishProductSubcategoryName = 'Mountain Bikes'
UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'US Domestic' WHERE EnglishProductSubcategoryName = 'Road Bikes'
UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'North America' WHERE EnglishProductSubcategoryName = 'Touring Bikes'
GO

SELECT * FROM DimProductSubcategory WHERE ProductSubcategoryKey in (1, 2, 3)
GO

SELECT * INTO FactResellerSalesCache
FROM FactResellerSalesPart
WHERE OrderDateKey = (SELECT MAX(OrderDateKey) FROM FactResellerSalesPart)

DELETE FROM FactResellerSalesPart
WHERE OrderDateKey = (SELECT MAX(OrderDateKey) FROM FactResellerSalesPart)
GO

SELECT * INTO FactSales
FROM FactResellerSalesPart  --where SalesOrderLineNumber%2 = 1
GO

CREATE COLUMNSTORE INDEX ncci ON FactSales (
	ProductKey,
	OrderDateKey,
	DueDateKey,
	ShipDateKey,
	ResellerKey,
	EmployeeKey,
	PromotionKey,
	CurrencyKey,
	SalesTerritoryKey,
	SalesOrderNumber,
	SalesOrderLineNumber,
	RevisionNumber,
	OrderQuantity,
	UnitPrice,
	ExtendedAmount,
	UnitPriceDiscountPct,
	DiscountAmount,
	ProductStandardCost,
	TotalProductCost,
	SalesAmount,
	TaxAmt,
	Freight,
	CarrierTrackingNumber,
	CustomerPONumber
)
GO


--
-- Prepare AdventureWorksDW2008Big_CCI (Clustered Columnstore Index)
--
USE AdventureWorksDW2008Big_CCI
GO

UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'International' WHERE EnglishProductSubcategoryName = 'Mountain Bikes'
UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'US Domestic' WHERE EnglishProductSubcategoryName = 'Road Bikes'
UPDATE DimProductSubcategory SET EnglishProductSubcategoryName = 'North America' WHERE EnglishProductSubcategoryName = 'Touring Bikes'
GO

SELECT * FROM DimProductSubcategory WHERE ProductSubcategoryKey in (1, 2, 3)
GO

SELECT * INTO FactResellerSalesCache
FROM FactResellerSalesPart 
WHERE OrderDateKey = (SELECT MAX(OrderDateKey) FROM FactResellerSalesPart)
GO

DELETE FROM FactResellerSalesPart 
WHERE OrderDateKey = (SELECT MAX(OrderDateKey) FROM FactResellerSalesPart)
GO

SELECT * INTO FactSales 
FROM FactResellerSalesPart  --where SalesOrderLineNumber%2 = 1
GO

CREATE CLUSTERED COLUMNSTORE INDEX cci ON FactSales
GO

DBCC SHRINKDATABASE(N'AdventureWorksDW2008Big_CCI' )
GO


USE master
GO
