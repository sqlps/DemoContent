/* This Sample Code is provided for the purpose of illustration only and is not intended 
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE 
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR 
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You 
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or 
result from the use or distribution of the Sample Code.
*/

Use adventureworksDW2016CTP3_Local 
GO
-- ===================================
-- Step 1) What's my data distribution
-- ===================================

Select DatePart(YYYY, orderDate) as  'Year', count(*) as '#Records'
From FactResellerSalesXL_PageCompressed
Group by DatePart(YYYY, orderDate)
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