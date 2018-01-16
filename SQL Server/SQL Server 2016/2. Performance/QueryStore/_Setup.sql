-- ============================================================================================================================================
-- This script leverage Adventureworks to create a XL SalesOrderHeader table that we can create a parameter sniffing issue
-- ============================================================================================================================================
USE [Adventureworks2016]
GO

-- ==========================================
-- Step 1) Add TT to the SalesTerritory table
-- ==========================================
INSERT INTO [Sales].[SalesTerritory]
           ([Name]
           ,[CountryRegionCode]
           ,[Group]
           ,[SalesYTD]
           ,[SalesLastYear]
           ,[CostYTD]
           ,[CostLastYear])
     VALUES
           ('Trinidad and Tobago'
           ,'TT'
           ,'LATAM'
           ,1000000.00
           ,100000.00
           ,0.00
           ,0.00)
GO

--Get the TerritoryID to be used later on when you insert rows into the XL Table
Select * from sales.SalesTerritory
where CountryRegionCode = 'TT'
GO

-- ==========================================
-- Step 2) Set a customer to be in TT
-- ==========================================
Update Sales.Customer
--STOP!!! Change TerritoryID
Set TerritoryID = 11
where CustomerID = 1

-- ==========================================
-- Step 3) Create large SalesOrderHeaderTable
-- ==========================================

--Create initial Table
Select * into Sales.SalesOrderHeader_XL from Sales.SalesOrderHeader
GO

-- Make it big
SET IDENTITY_INSERT Sales.SalesOrderHeader_XL ON
GO
Insert Into Sales.SalesOrderHeader_XL ([SalesOrderID]
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
go 50

-- ================================================================
-- Step 4) Insert a couple TT Rows
-- STOP!!!! MAKE SURE YOU UPDATE THE TERRITORYID AND CUSTOMERNUMBER
-- ================================================================

Insert Into Sales.SalesOrderHeader_XL ([SalesOrderID]
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
Select top 10 [SalesOrderID]
      ,[RevisionNumber]
      ,[OrderDate]
      ,[DueDate]
      ,[ShipDate]
      ,[Status]
      ,[OnlineOrderFlag]
      ,[SalesOrderNumber]
      ,[PurchaseOrderNumber]
      ,[AccountNumber]
      ,1
      ,[SalesPersonID]
      ,11
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
go 

-- ===================================
-- Step 5) Create indexes
-- ===================================

CREATE CLUSTERED INDEX [SalesOrderHeader_XL_SalesOrderID] ON [Sales].[SalesOrderHeader_XL]
(
	[SalesOrderID] ASC
)

GO

CREATE NONCLUSTERED INDEX [IX_SalesOrderHeader_XL_SalesPersonID] ON [Sales].[SalesOrderHeader_XL]
(
	[SalesPersonID] ASC
)
GO

CREATE NONCLUSTERED INDEX [IX_SalesOrderHeade_XL_CustomerID] ON [Sales].[SalesOrderHeader_XL]
(
	[CustomerID] ASC
)
GO
CREATE  NONCLUSTERED INDEX [AK_SalesOrderHeader_XL_SalesOrderNumber] ON [Sales].[SalesOrderHeader_XL]
(
	[SalesOrderNumber] ASC
)
GO

CREATE  NONCLUSTERED INDEX [AK_SalesOrderHeader_XL_rowguid] ON [Sales].[SalesOrderHeader_XL]
(
	[rowguid] ASC
)
GO

-- ===================================
-- Step 6) Create the Proc
-- ===================================
If Exists (Select name from sys.procedures where name = 'GetSalesOrderByCountry')
	Drop Procedure Sales.GetSalesOrderByCountry
GO

CREATE PROCEDURE Sales.GetSalesOrderByCountry
@Country NVARCHAR (60)
--with recompile
As
BEGIN
          SELECT B.Name, Sum(SubTotal) As Sales --TerritoryID, salespersonid
          FROM   Sales.SalesOrderHeader_XL A
		  Inner Join Sales.SalesTerritory B
		  On A.TerritoryID = B.TerritoryID
		  where B.CountryRegionCode = @Country
		  group by B.Name
END
GO

-- ===================================
-- Step 6) Testing
-- ===================================
Set Statistics time ON

-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'TT' with recompile

-- Run the stored proc and examine the query plan

EXECUTE Sales.GetSalesOrderByCountry 'US'

EXECUTE Sales.GetSalesOrderByCountry 'US' with recompile;

-- ===================================
-- Step 6) Why is TT an issue?
-- ===================================

SELECT B.CountryRegionCode, Count(*) 'Number of orders' --TerritoryID, salespersonid
FROM   Sales.SalesOrderHeader_XL A
Inner Join Sales.SalesTerritory B
On A.TerritoryID = B.TerritoryID
group by B.CountryRegionCode
Order by 2 