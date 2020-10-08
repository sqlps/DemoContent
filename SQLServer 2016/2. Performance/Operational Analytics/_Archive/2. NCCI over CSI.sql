-- 1 Create a non-clustered columnstore index on a table that already has a clustered index on it. 
Use AdventureWorks2016DW
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX [Idx_Columnstore] 
ON [dbo].[FactSalesXL]
(
	[ShipDateKey],
	[SalesTerritoryKey],
	[ProductKey],
	[SalesAmount]
)WITH (DROP_EXISTING = OFF) ON [PRIMARY]
GO

-- 2 Run a query, but ignore the index
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
SELECT AVG(SalesAmount) AS AvgSales, SUM(SalesAmount) AS TotalSales
FROM FactSalesXL
WHERE ShipDateKey BETWEEN 20020715  AND 20040715
GROUP BY SalesTerritoryKey, ProductKey
OPTION (IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX) --this ignores the index
GO

-- 4 Run the query again, this time with the index
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
SELECT AVG(SalesAmount) AS AvgSales, SUM(SalesAmount) AS TotalSales
FROM FactSalesXL
WHERE ShipDateKey BETWEEN 20020715  AND 20040715
GROUP BY SalesTerritoryKey, ProductKey
GO

-- Inserting data to a table with a non-clustered Columnstore index
SET STATISTICS TIME OFF
SET STATISTICS IO OFF
INSERT  
	INTO FactSalesXL
		(ProductKey, OrderDateKey, DueDateKey,
		ShipDateKey, ResellerKey, EmployeeKey, PromotionKey, CurrencyKey, SalesTerritoryKey,
		SalesOrderNumber, SalesOrderLineNumber, OrderQuantity, UnitPrice, SalesAmount, TaxAmt)
	SELECT TOP 2000 ProductKey, OrderDateKey, DueDateKey, 20150601, ResellerKey,
		EmployeeKey, PromotionKey, CurrencyKey, SalesTerritoryKey, LEFT(SalesOrderNumber+'T',20), 
		SalesOrderLineNumber, OrderQuantity, UnitPrice, SalesAmount, TaxAmt
	FROM FactSales_staging_10K

Set Statistics IO ON
Set Statistics Time on
-- Display the newly inserted rows
SELECT pk_factsales, shipdatekey 
FROM FactSalesXL WITH(INDEX = CI_FactSalesXL)
WHERE ShipDateKey = 20150601;
GO

SELECT pk_factsales, shipdatekey 
FROM FactSalesXL 
WHERE ShipDateKey = 20150601;

SET Statistics IO OFF
Set Statistics Time oFF
--  Verify new rows are not in compressed rowgroups

SELECT *
FROM sys.column_store_row_groups
WHERE object_id = OBJECT_ID('FactSalesXL')
GO


DELETE From FactSalesXL
WHERE ShipDateKey = 20150601;