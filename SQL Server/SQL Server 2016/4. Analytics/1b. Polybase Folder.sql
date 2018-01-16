------------------------------- Polybase Building Blocks --------------------------------------------------------
USE AdventureworksDW2016_HDFS
go
-- ============================================================================================================
-- Step 1) Validate database master key to encrypt database scoped credential secret
-- ============================================================================================================
Select * from sys.symmetric_keys
-- ============================================================================================================
-- Step 2) Validate credential to Azure exists
-- ============================================================================================================
select * from sys.database_credentials;
-- ============================================================================================================
-- Step 3) Validate my external data source
-- ============================================================================================================
select * from sys.external_data_sources;
-- ============================================================================================================
-- Step 4) What file formats have I defined
-- ============================================================================================================
select * from sys.external_file_formats;
-- ============================================================================================================
-- Step 5) What external_tables present
-- ============================================================================================================
select * from sys.external_tables;
Open Master key DeCRYPTION BY PASSWORD = 'P@ssw0rd';
------------------------------- Load data into your database --------------------------------------------------

-- ============================================================================================================
-- Step 6) View Data Before Purged out
-- ============================================================================================================
-- HDFS
SELECT count(*)
From  dbo.[FactResellerSales_XLArchiveExternal]

--In SQL
select count(*) from [dbo].[FactResellerSalesXL_PageCompressed]


select count(*) from [dbo].[FactResellerSalesXL_PageCompressed]
where orderdate < '20050201'

-- ============================================================================================================
-- Step 7) Run Package ArchiveToBlobStorage
-- ============================================================================================================

--Recheck
-- HDFS
SELECT count(*)
From  dbo.[FactResellerSales_XLArchiveExternal]

--In SQL
select count(*) from [dbo].[FactResellerSalesXL_PageCompressed]
where orderdate < '20050201'

-- confirm data purged
select count(*) from [dbo].[FactResellerSalesXL_PageCompressed]


/*
Create View FactResellerSalesXL_PageCompressed_v
 AS
  Select * from  [FactResellerSales_XLArchiveExternal]
  UNION 
  Select * from [dbo].[FactResellerSalesXL_PageCompressed]
 */

 --Joining Both sets together
Select count(*) from FactResellerSalesXL_PageCompressed_v
where orderdate < '20050201'

-- ============================================================================================================
-- Step 7) Recover those deleted rows
-- ============================================================================================================
USE [AdventureworksDW2016_HDFS]
GO
INSERT INTO [dbo].[FactResellerSalesXL_PageCompressed] ([ProductKey], [OrderDateKey], [DueDateKey], [ShipDateKey], [ResellerKey], [EmployeeKey], [PromotionKey], [CurrencyKey], [SalesTerritoryKey], [SalesOrderNumber], [SalesOrderLineNumber], [RevisionNumber], [OrderQuantity], [UnitPrice], [ExtendedAmount], [UnitPriceDiscountPct], [DiscountAmount], [ProductStandardCost], [TotalProductCost], [SalesAmount], [TaxAmt], [Freight], [CarrierTrackingNumber], [CustomerPONumber], [OrderDate], [DueDate], [ShipDate])
SELECT [ProductKey], [OrderDateKey], [DueDateKey], [ShipDateKey], [ResellerKey], [EmployeeKey], [PromotionKey], [CurrencyKey], [SalesTerritoryKey], [SalesOrderNumber], [SalesOrderLineNumber], [RevisionNumber], [OrderQuantity], [UnitPrice], [ExtendedAmount], [UnitPriceDiscountPct], [DiscountAmount], [ProductStandardCost], [TotalProductCost], [SalesAmount], [TaxAmt], [Freight], [CarrierTrackingNumber], [CustomerPONumber], [OrderDate], [DueDate], [ShipDate]
FROM [dbo].[FactResellerSales_XLArchiveExternal]
GO

-- ============================================================================================================
-- Step 8)Check local table agian
-- ============================================================================================================
select count(*) from [dbo].[FactResellerSalesXL_PageCompressed]