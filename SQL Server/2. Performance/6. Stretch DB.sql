use master
Go
Select * from sys.certificates
Use adventureworksDW2016CTP3_Local 
GO
-- ===================================
-- Step 1) What's my data distribution
-- ===================================

Select Left(orderdatekey,4) as  'Year', count(*) as '#Records'
From FactResellerSalesXL_PageCompressed
Group by Left(orderdatekey,4)
order by 1 desc
Go

-- ===================================
-- Step 2) Simple aggregation
-- ===================================

-- Enable LQS

SELECT c.CalendarYear
	,b.SalesTerritoryRegion
	,FirstName + ' ' + LastName AS FullName
	,count(SalesOrderNumber) AS NumSales
	,sum(SalesAmount) AS TotalSalesAmt
	,Avg(SalesAmount) AS AvgSalesAmt
	,count(DISTINCT SalesOrderNumber) AS NumOrders
	,count(DISTINCT ResellerKey) AS NumResellers
FROM FactResellerSalesXL_PageCompressed a
INNER JOIN DimSalesTerritory b ON b.SalesTerritoryKey = a.SalesTerritoryKey
INNER JOIN DimEmployee d ON d.Employeekey = a.EmployeeKey
INNER JOIN DimDate c ON c.DateKey = a.OrderDateKey
WHERE b.SalesTerritoryKey = 3
	AND c.FullDateAlternateKey BETWEEN '1/1/2006' AND '1/1/2010'
GROUP BY b.SalesTerritoryRegion,d.EmployeeKey,d.FirstName,d.LastName,c.CalendarYear
GO

-- ===================================================
-- Step 3) Enable Stretch for anything older that 2009
-- ===================================================

-- Walk thru wizard

-- ===================================================
-- Step 4) Re-run query
-- ===================================================
use AdventureworksDW2016CTP3
GO
-- Enable LQS

SELECT c.CalendarYear
	,b.SalesTerritoryRegion
	,FirstName + ' ' + LastName AS FullName
	,count(SalesOrderNumber) AS NumSales
	,sum(SalesAmount) AS TotalSalesAmt
	,Avg(SalesAmount) AS AvgSalesAmt
	,count(DISTINCT SalesOrderNumber) AS NumOrders
	,count(DISTINCT ResellerKey) AS NumResellers
FROM FactResellerSalesXL_PageCompressed a
INNER JOIN DimSalesTerritory b ON b.SalesTerritoryKey = a.SalesTerritoryKey
INNER JOIN DimEmployee d ON d.Employeekey = a.EmployeeKey
INNER JOIN DimDate c ON c.DateKey = a.OrderDateKey
WHERE b.SalesTerritoryKey = 3
	AND c.FullDateAlternateKey BETWEEN '1/1/2006' AND '1/1/2010'
GROUP BY b.SalesTerritoryRegion,d.EmployeeKey,d.FirstName,d.LastName,c.CalendarYear
GO

-- ===================================================
-- Step 5) Show Azure SQLDB
-- ===================================================




Select * from sys.dm_db_rda_migration_status