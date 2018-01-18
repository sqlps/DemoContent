
-- Execute a typical query that joins the Fact Table with dimension tables
-- Note this query will run on the Page Compressed table, Note down the time

DECLARE @StartingTime datetime2(7) = SYSDATETIME();
SELECT c.CalendarYear
	,b.SalesTerritoryRegion
	,FirstName + ' ' + LastName AS FullName
	,count(SalesOrderNumber) AS NumSales
	,sum(SalesAmount) AS TotalSalesAmt
	,Avg(SalesAmount) AS AvgSalesAmt
	,count(DISTINCT SalesOrderNumber) AS NumOrders
	,count(DISTINCT ResellerKey) AS NumResellers
FROM FactResellerSales a
INNER JOIN DimSalesTerritory b ON b.SalesTerritoryKey = a.SalesTerritoryKey
INNER JOIN DimEmployee d ON d.Employeekey = a.EmployeeKey
INNER JOIN DimDate c ON c.DateKey = a.OrderDateKey
WHERE b.SalesTerritoryKey = 3
--	AND c.FullDateAlternateKey BETWEEN '1/1/2006' AND '1/1/2010'
GROUP BY b.SalesTerritoryRegion,d.EmployeeKey,d.FirstName,d.LastName,c.CalendarYear
go 15

SELECT ProductKey
	,count(ProductKey)
FROM FactResellerSales_CCI
GROUP BY ProductKey
ORDER BY ProductKey
go 20



SELECT ProductKey,sum(TotalProductCost)
FROM FactResellerSales_CCI
GROUP BY ProductKey
go 20

SELECT ProductKey
	,COUNT(DISTINCT rs.EmployeeKey) AS NumEmployees
	,COUNT(DISTINCT rs.ResellerKey) AS NumResellers
FROM dbo.FactResellerSales_CCI AS rs
WHERE rs.SalesTerritoryKey >= 8
GROUP BY ProductKey
ORDER BY ProductKey
go 20