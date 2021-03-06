-- ===================================================================================================================================================
-- This script leverage Adventureworks to create a  SalesOrderHeader table to showcase operational analytics.
-- ===================================================================================================================================================
USE [Adventureworks2016CTP3]
GO

-- ======================================================
-- Step 1) Create staging table to add sales records
-- ======================================================

--Create Staging Table
Select * into Sales.SalesOrderHeader_staging from Sales.SalesOrderHeader
GO

--Modify sales date
Update Sales.SalesOrderHeader_staging
Set OrderDate = GetDate()

-- ======================================================
-- Step 2 Create Large SalesOrderHeader table > 3M rows
-- ======================================================

--Create initial Table
Select * into Sales.SalesOrderHeader_OpAnalytics from Sales.SalesOrderHeader
GO

-- Make it big
SET IDENTITY_INSERT Sales.SalesOrderHeader_OpAnalytics ON
GO
Insert Into Sales.SalesOrderHeader_OpAnalytics ([SalesOrderID]
      ,[RevisionNumber]
      ,[OrderDate]
      ,[DueDate]
      ,[ShipDate]
      ,[Status]
      ,[OnlineOrderFlag]
      ,[SalesOrderNumber]
      ,[PurchaseOrderNumber]
      ,[AccountNumber]
      ,[CustomerID]
      ,[SalesPersonID]
      ,[TerritoryID]
      ,[BillToAddressID]
      ,[ShipToAddressID]
      ,[ShipMethodID]
      ,[CreditCardID]
      ,[CreditCardApprovalCode]
      ,[CurrencyRateID]
      ,[SubTotal]
      ,[TaxAmt]
      ,[Freight]
      ,[TotalDue]
      ,[Comment]
      ,[rowguid]
      ,[ModifiedDate])
Select [SalesOrderID]
      ,[RevisionNumber]
      ,[OrderDate]
      ,[DueDate]
      ,[ShipDate]
      ,[Status]
      ,[OnlineOrderFlag]
      ,[SalesOrderNumber]
      ,[PurchaseOrderNumber]
      ,[AccountNumber]
      ,[CustomerID]
      ,[SalesPersonID]
      ,[TerritoryID]
      ,[BillToAddressID]
      ,[ShipToAddressID]
      ,[ShipMethodID]
      ,[CreditCardID]
      ,[CreditCardApprovalCode]
      ,[CurrencyRateID]
      ,[SubTotal]
      ,[TaxAmt]
      ,[Freight]
      ,[TotalDue]
      ,[Comment]
      ,[rowguid]
      ,[ModifiedDate]
From Sales.SalesOrderHeader
go 100

-- ======================================================
-- Step 3) Create indexes operational analytics
-- ======================================================
--Regular Clustered index
CREATE CLUSTERED INDEX [CI_SalesOrderHeader_OpAnalytics] ON [Sales].[SalesOrderHeader_OpAnalytics]
(
	[OrderDate] ASC,
	[SalesOrderID] ASC
)ON [PRIMARY]
GO

--NCCI for Op Analytics
CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCI_SalesOrderHeader_OpAnalytics] ON [Sales].[SalesOrderHeader_OpAnalytics]
(
	[OrderDate],
	[SalesOrderID],
	[RevisionNumber],
	[DueDate],
	[ShipDate],
	[Status],
	[SalesOrderNumber],
	[CustomerID],
	[SalesPersonID],
	[TerritoryID],
	[BillToAddressID],
	[ShipToAddressID],
	[ShipMethodID],
	[CreditCardID],
	[CreditCardApprovalCode],
	[CurrencyRateID],
	[SubTotal],
	[TaxAmt],
	[Freight],
	[TotalDue],
	[Comment],
	[ModifiedDate]
)
Where OrderDate < '2016-01-01'
WITH (DROP_EXISTING = OFF)

GO


-- ======================================================
-- Step 4) Simple Reporting queries
-- ======================================================
Select STH.Name, STH.CountryRegionCode, STH.[Group], STH.SalesLastYear, Sum(TotalDue) SalesYTD
from Sales.SalesOrderHeader_OpAnalytics SOH 
Inner Join sales.SalesTerritory STH
on STH.TerritoryID = SOH.TerritoryID
where  OrderDate < '2016-01-01'
Group by Name, CountryRegionCode, [Group], SalesLastYear


Select FirstName, LastName, Sum(TotalDue)
From Sales.SalesOrderHeader_OpAnalytics SOH
Inner Join Sales.CustomerPII C
On C.CustomerID = SOH.CustomerID
Where SOH.CustomerID = 29672
Group by FirstName, LastName


Select * from Sales.CustomerPII
where CustomerID = 29672
