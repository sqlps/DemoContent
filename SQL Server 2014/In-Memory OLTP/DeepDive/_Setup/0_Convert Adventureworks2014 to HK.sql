Use Master
GO
Restore Database AdventureWorks2014 From Disk ='G:\Backup\Adventureworks2014.bak'
GO
USE [Adventureworks2014]
GO
EXEC dbo.sp_changedbowner @loginame = N'sa', @map = false
GO
-- when running the script in SSMS, be sure to enable "Query -> SQLCMD Mode"


:setvar checkpoint_files_location "d:\Data\"

:setvar max_memory_percent "80"
:setvar database_name "AdventureWorks2014"

-- The below script is used to install the sample for In-Memory OLTP in SQL Server 2014, based on AdventureWorks.
-- The sample requires the base AdventureWorks2014 database, available from: http://msftdbprodsamples.codeplex.com/downloads/get/880661
--
-- For details about the sample, as well as installation instructions, see Books Online
-- 
-- Last updated: 2014-08-22
--
--  change note (2014-08-22): updated to use AdventureWorks2014
--  change note (2014-04-28): fixed isolation level for sample stored procedures demonstrating integrity checks:
--				Sales.usp_InsertSpecialOfferProduct_inmem, Sales.usp_DeleteSpecialOffer_inmem,
--				Production.usp_InsertProduct_inmem, Production.usp_DeleteProduct_inmem
-- 
--  Copyright (C) Microsoft Corporation.  All rights reserved.
-- 
-- This source code is intended only as a supplement to Microsoft
-- Development Tools and/or on-line documentation.  
-- 
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
-- ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO 
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.


USE master
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
SET NOCOUNT ON
GO

/*************************** Add MEMORY_OPTIMIZED_DATA filegroup and container to enable in-memory OLTP in the database **********************************/

IF NOT EXISTS (SELECT * FROM $(database_name).sys.data_spaces WHERE type='FX')
	ALTER DATABASE $(database_name) 
	  ADD FILEGROUP [$(database_name)_mod] CONTAINS MEMORY_OPTIMIZED_DATA
GO
IF NOT EXISTS (SELECT * FROM $(database_name).sys.data_spaces ds JOIN $(database_name).sys.database_files df ON ds.data_space_id=df.data_space_id WHERE ds.type='FX')
	ALTER DATABASE $(database_name)
	  ADD FILE (name='$(database_name)_mod', filename='$(checkpoint_files_location)$(database_name)_mod') 
	  TO FILEGROUP [$(database_name)_mod]
GO

/*************************** Create resource pool and bind the database to it **********************************/

IF EXISTS (SELECT * FROM sys.resource_governor_resource_pools rp join sys.databases d on rp.pool_id=d.resource_pool_id WHERE d.name=N'$(database_name)')
BEGIN
	EXEC sp_xtp_unbind_db_resource_pool '$(database_name)'
END
GO

IF NOT EXISTS (SELECT * FROM sys.resource_governor_resource_pools WHERE name=N'Pool_$(database_name)')
BEGIN		
	CREATE RESOURCE POOL Pool_$(database_name) 
		WITH ( MAX_MEMORY_PERCENT = $(max_memory_percent) );
	ALTER RESOURCE GOVERNOR RECONFIGURE;
END
GO

EXEC sp_xtp_bind_db_resource_pool '$(database_name)', 'Pool_$(database_name)'
GO

ALTER DATABASE $(database_name) SET OFFLINE WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE $(database_name) SET ONLINE
GO


USE $(database_name)
GO

/*************************** For memory-optimized tables, automatically map all lower isolation levels (including READ COMMITTED) to SNAPSHOT **********************************/

ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON
GO



/*************************** Create Tables **********************************/

-- first drop all objects that have a schema-bound dependency on the table
IF object_id('[Sales].[vSalesOrderHeader_extended_inmem]') IS NOT NULL
	DROP VIEW [Sales].[vSalesOrderHeader_extended_inmem] 
GO
IF object_id('[Sales].[vSalesOrderDetail_extended_inmem]') IS NOT NULL
	DROP VIEW [Sales].[vSalesOrderDetail_extended_inmem] 
GO
IF object_id('[Sales].[usp_UpdateSalesOrderShipInfo_native]') IS NOT NULL
	DROP PROCEDURE [Sales].usp_UpdateSalesOrderShipInfo_native 
GO
IF object_id('[Sales].[usp_InsertSalesOrder_inmem]') IS NOT NULL
	DROP PROCEDURE [Sales].usp_InsertSalesOrder_inmem 
GO
IF object_id('[Sales].[SalesOrderHeader_inmem]') IS NOT NULL
	DROP TABLE [Sales].[SalesOrderHeader_inmem] 
GO
CREATE TABLE [Sales].[SalesOrderHeader_inmem](
	[SalesOrderID] int IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT=10000000),
	[RevisionNumber] [tinyint] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_RevisionNumber]  DEFAULT ((0)),
	[OrderDate] [datetime2] NOT NULL ,
	[DueDate] [datetime2] NOT NULL,
	[ShipDate] [datetime2] NULL,
	[Status] [tinyint] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_Status]  DEFAULT ((1)),
	[OnlineOrderFlag] bit NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_OnlineOrderFlag]  DEFAULT ((1)), 
	[PurchaseOrderNumber] nvarchar(25) NULL,
	[AccountNumber] nvarchar(15) NULL,
	[CustomerID] [int] NOT NULL ,
	[SalesPersonID] [int] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_SalesPersonID]  DEFAULT ((-1)), 
	[TerritoryID] [int] NULL,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[ShipMethodID] [int] NOT NULL,
	[CreditCardID] [int] NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[CurrencyRateID] [int] NULL,
	[SubTotal] [money] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_SubTotal]  DEFAULT ((0.00)),
	[TaxAmt] [money] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_TaxAmt]  DEFAULT ((0.00)),
	[Freight] [money] NOT NULL CONSTRAINT [IMDF_SalesOrderHeader_Freight]  DEFAULT ((0.00)),
	[Comment] [nvarchar](128) NULL,
	[ModifiedDate] [datetime2] NOT NULL ,

	INDEX IX_SalesPersonID HASH (SalesPersonID) WITH (BUCKET_COUNT=1000000),
	INDEX IX_CustomerID HASH (CustomerID) WITH (BUCKET_COUNT=1000000)
) WITH (MEMORY_OPTIMIZED=ON)
GO

-- computed values for TotalDue and SalesOrderNumber are included in this view
IF object_id('[Sales].[vSalesOrderHeader_extended_inmem]') IS NOT NULL
	DROP VIEW [Sales].[vSalesOrderHeader_extended_inmem] 
GO
CREATE VIEW Sales.[vSalesOrderHeader_extended_inmem]
WITH SCHEMABINDING
AS
SELECT SalesOrderID, 
	RevisionNumber, 
	OrderDate, 
	DueDate, 
	ShipDate, 
	Status, 
	OnlineOrderFlag, 
	PurchaseOrderNumber, 
	AccountNumber, 
	CustomerID, 
	SalesPersonID, 
	TerritoryID, 
	BillToAddressID, 
	ShipToAddressID,                          
	ShipMethodID, 
	CreditCardID, 
	CreditCardApprovalCode, 
	CurrencyRateID, 
	SubTotal, 
	Freight, 
	TaxAmt, 
	Comment, 
	ModifiedDate, 
	ISNULL(N'SO' + CONVERT([nvarchar](23), SalesOrderID), N'*** ERROR ***') AS SalesOrderNumber, 
	ISNULL(SubTotal + TaxAmt + Freight, 0) AS TotalDue
FROM Sales.SalesOrderHeader_inmem
GO


IF object_id('[Sales].[vSalesOrderDetail_extended_inmem]') IS NOT NULL
	DROP VIEW [Sales].[vSalesOrderDetail_extended_inmem] 
GO
IF object_id('[Sales].[SalesOrderDetail_inmem]') IS NOT NULL
	DROP TABLE [Sales].[SalesOrderDetail_inmem] 
GO
CREATE TABLE [Sales].[SalesOrderDetail_inmem](
	[SalesOrderID] int NOT NULL INDEX IX_SalesOrderID HASH WITH (BUCKET_COUNT=10000000),
	[SalesOrderDetailID] bigint IDENTITY NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL INDEX IX_ProductID HASH WITH (BUCKET_COUNT=1000000),
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL CONSTRAINT [IMDF_SalesOrderDetail_UnitPriceDiscount]  DEFAULT ((0.0)),
	[ModifiedDate] [datetime2] NOT NULL ,

	CONSTRAINT [imPK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY NONCLUSTERED HASH 
	(	[SalesOrderID],
		[SalesOrderDetailID]
	)WITH (BUCKET_COUNT=50000000)
) WITH (MEMORY_OPTIMIZED=ON)
GO

-- computed value for LineTotal is included in this view
IF object_id('[Sales].[vSalesOrderDetail_extended_inmem]') IS NOT NULL
	DROP VIEW [Sales].[vSalesOrderDetail_extended_inmem] 
GO
CREATE VIEW Sales.[vSalesOrderDetail_extended_inmem]
WITH SCHEMABINDING
AS
SELECT SalesOrderID, 
	SalesOrderDetailID, 
	CarrierTrackingNumber, 
	OrderQty, 
	ProductID, 
	SpecialOfferID, 
	UnitPrice, 
	UnitPriceDiscount, 
	ModifiedDate, 
	ISNULL(UnitPrice * (1.0 - UnitPriceDiscount) * OrderQty, 0.0) AS LineTotal
FROM Sales.SalesOrderDetail_inmem
GO

-- type used for TVPs when creating new sales orders
IF type_id('[Sales].[SalesOrderDetailType_inmem]') IS NOT NULL
	DROP TYPE [Sales].[SalesOrderDetailType_inmem] 
GO
CREATE TYPE [Sales].[SalesOrderDetailType_inmem] AS TABLE(
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL INDEX IX_ProductID NONCLUSTERED HASH WITH (BUCKET_COUNT=8),
	[SpecialOfferID] [int] NOT NULL INDEX IX_SpecialOfferID NONCLUSTERED HASH WITH (BUCKET_COUNT=8)
) WITH (MEMORY_OPTIMIZED=ON)
GO


IF object_id('Sales.usp_DeleteSpecialOffer_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_DeleteSpecialOffer_inmem
go
IF object_id('Sales.usp_InsertSpecialOfferProduct_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSpecialOfferProduct_inmem
GO
IF object_id('Sales.usp_InsertSpecialOffer_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSpecialOffer_inmem
go
IF object_id('[Sales].[SpecialOffer_inmem]') IS NOT NULL
	DROP TABLE [Sales].[SpecialOffer_inmem] 
GO
CREATE TABLE [Sales].[SpecialOffer_inmem](
	[SpecialOfferID] [int] IDENTITY NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[DiscountPct] [smallmoney] NOT NULL CONSTRAINT [IMDF_SpecialOffer_DiscountPct]  DEFAULT ((0.00)),
	[Type] [nvarchar](50) NOT NULL,
	[Category] [nvarchar](50) NOT NULL,
	[StartDate] [datetime2] NOT NULL,
	[EndDate] [datetime2] NOT NULL,
	[MinQty] [int] NOT NULL CONSTRAINT [IMDF_SpecialOffer_MinQty]  DEFAULT ((0)),
	[MaxQty] [int] NULL,
	[ModifiedDate] [datetime2] NOT NULL CONSTRAINT [IMDF_SpecialOffer_ModifiedDate]  DEFAULT (SYSDATETIME()),

	CONSTRAINT [IMPK_SpecialOffer_SpecialOfferID] PRIMARY KEY NONCLUSTERED HASH
	([SpecialOfferID]) WITH (BUCKET_COUNT=1000000)
) WITH (MEMORY_OPTIMIZED=ON)
GO

IF object_id('Production.usp_DeleteProduct_inmem') IS NOT NULL
	DROP PROCEDURE Production.usp_DeleteProduct_inmem
GO
IF object_id('Sales.usp_DeleteSpecialOffer_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_DeleteSpecialOffer_inmem
GO
IF object_id('Sales.usp_InsertSpecialOfferProduct_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSpecialOfferProduct_inmem
GO
IF object_id('[Sales].[SpecialOfferProduct_inmem]') IS NOT NULL
	DROP TABLE [Sales].[SpecialOfferProduct_inmem] 
GO
CREATE TABLE [Sales].[SpecialOfferProduct_inmem](
	[SpecialOfferID] [int] NOT NULL,
	[ProductID] [int] NOT NULL INDEX ix_ProductID,
	[ModifiedDate] [datetime2] NOT NULL CONSTRAINT [IMDF_SpecialOfferProduct_ModifiedDate]  DEFAULT (SYSDATETIME()),
	CONSTRAINT [IMPK_SpecialOfferProduct_SpecialOfferID_ProductID] PRIMARY KEY NONCLUSTERED 
	(	[SpecialOfferID], [ProductID])
) WITH (MEMORY_OPTIMIZED=ON)
GO

IF object_id('Production.usp_InsertProduct_inmem') IS NOT NULL
	DROP PROCEDURE Production.usp_InsertProduct_inmem
GO
IF object_id('Production.usp_DeleteProduct_inmem') IS NOT NULL
	DROP PROCEDURE Production.usp_DeleteProduct_inmem
GO
IF object_id('[Production].[Product_inmem]') IS NOT NULL
	DROP TABLE [Production].[Product_inmem] 
GO
CREATE TABLE [Production].[Product_inmem](
	[ProductID] [int] IDENTITY NOT NULL,
	[Name] nvarchar(50) COLLATE Latin1_General_100_BIN2 NOT NULL INDEX IX_Name,
	[ProductNumber] [nvarchar](25) COLLATE Latin1_General_100_BIN2 NOT NULL INDEX IX_ProductNumber,
	[MakeFlag] bit NOT NULL CONSTRAINT [IMDF_Product_MakeFlag]  DEFAULT ((1)),
	[FinishedGoodsFlag] bit NOT NULL CONSTRAINT [IMDF_Product_FinishedGoodsFlag]  DEFAULT ((1)),
	[Color] [nvarchar](15) NULL,
	[SafetyStockLevel] [smallint] NOT NULL,
	[ReorderPoint] [smallint] NOT NULL,
	[StandardCost] [money] NOT NULL,
	[ListPrice] [money] NOT NULL,
	[Size] [nvarchar](5) NULL,
	[SizeUnitMeasureCode] [nchar](3) NULL,
	[WeightUnitMeasureCode] [nchar](3) NULL,
	[Weight] [decimal](8, 2) NULL,
	[DaysToManufacture] [int] NOT NULL,
	[ProductLine] [nchar](2) NULL,
	[Class] [nchar](2) NULL,
	[Style] [nchar](2) NULL,
	[ProductSubcategoryID] [int] NULL,
	[ProductModelID] [int] NULL,
	[SellStartDate] [datetime2] NOT NULL,
	[SellEndDate] [datetime2] NULL,
	[DiscontinuedDate] [datetime2] NULL,
	[ModifiedDate] [datetime2] NOT NULL CONSTRAINT [IMDF_Product_ModifiedDate]  DEFAULT (SYSDATETIME()),

	CONSTRAINT [IMPK_Product_ProductID] PRIMARY KEY NONCLUSTERED HASH
	( [ProductID] ) WITH (BUCKET_COUNT=1000000)
)	WITH (MEMORY_OPTIMIZED=ON)
GO

IF object_id('[Sales].[SalesOrderHeader_ondisk]') IS NOT NULL
	DROP TABLE [Sales].[SalesOrderHeader_ondisk] 
GO
CREATE TABLE [Sales].[SalesOrderHeader_ondisk](
	[SalesOrderID] int IDENTITY NOT NULL PRIMARY KEY,
	[RevisionNumber] [tinyint] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_RevisionNumber]  DEFAULT ((0)),
	[OrderDate] [datetime2] NOT NULL ,
	[DueDate] [datetime2] NOT NULL,
	[ShipDate] [datetime2] NULL,
	[Status] [tinyint] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_Status]  DEFAULT ((1)),
	[OnlineOrderFlag] bit NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_OnlineOrderFlag]  DEFAULT ((1)),  
	[PurchaseOrderNumber] nvarchar(25) NULL, 
	[AccountNumber] nvarchar(15) NULL, 
	[CustomerID] [int] NOT NULL ,
	[SalesPersonID] [int] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_SalesPersonID]  DEFAULT ((-1)), 
	[TerritoryID] [int] NULL,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[ShipMethodID] [int] NOT NULL,
	[CreditCardID] [int] NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[CurrencyRateID] [int] NULL,
	[SubTotal] [money] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_SubTotal]  DEFAULT ((0.00)),
	[TaxAmt] [money] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_TaxAmt]  DEFAULT ((0.00)),
	[Freight] [money] NOT NULL CONSTRAINT [ODDF_SalesOrderHeader_Freight]  DEFAULT ((0.00)),
	[Comment] [nvarchar](128) NULL,
	[ModifiedDate] [datetime2] NOT NULL ,

	INDEX IX_SalesPersonID (SalesPersonID) ,
	INDEX IX_CustomerID (CustomerID) ,
	INDEX IX_OrderDate (OrderDate ASC)
) 
GO


IF object_id('[Sales].[SalesOrderDetail_ondisk]') IS NOT NULL
	DROP TABLE [Sales].[SalesOrderDetail_ondisk] 
GO
CREATE TABLE [Sales].[SalesOrderDetail_ondisk](
	[SalesOrderID] int NOT NULL,
	[SalesOrderDetailID] bigint IDENTITY NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL INDEX IX_ProductID NONCLUSTERED,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL CONSTRAINT [ODDF_SalesOrderDetail_UnitPriceDiscount]  DEFAULT ((0.0)),
	[ModifiedDate] [datetime2] NOT NULL ,

	CONSTRAINT [ODPK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY  
	(	[SalesOrderID],	[SalesOrderDetailID])
) 
GO



IF object_id('Sales.usp_InsertSalesOrder_ondisk') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSalesOrder_ondisk 
GO
IF type_id('Sales.SalesOrderDetailType_ondisk') IS NOT NULL
	DROP TYPE [Sales].[SalesOrderDetailType_ondisk] 
GO
CREATE TYPE [Sales].[SalesOrderDetailType_ondisk] AS TABLE(
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL INDEX IX_ProductID CLUSTERED,
	[SpecialOfferID] [int] NOT NULL INDEX IX_SpecialOfferID NONCLUSTERED
)
GO



IF object_id('[Sales].[SpecialOffer_ondisk]') IS NOT NULL
	DROP TABLE [Sales].[SpecialOffer_ondisk] 
GO
CREATE TABLE [Sales].[SpecialOffer_ondisk](
	[SpecialOfferID] [int] IDENTITY NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[DiscountPct] [smallmoney] NOT NULL CONSTRAINT [ODDF_SpecialOffer_DiscountPct]  DEFAULT ((0.00)),
	[Type] [nvarchar](50) NOT NULL,
	[Category] [nvarchar](50) NOT NULL,
	[StartDate] [datetime2] NOT NULL,
	[EndDate] [datetime2] NOT NULL,
	[MinQty] [int] NOT NULL CONSTRAINT [ODDF_SpecialOffer_MinQty]  DEFAULT ((0)),
	[MaxQty] [int] NULL,
	[ModifiedDate] [datetime2] NOT NULL CONSTRAINT [ODDF_SpecialOffer_ModifiedDate]  DEFAULT (SYSDATETIME()),
	CONSTRAINT [ODPK_SpecialOffer_SpecialOfferID] PRIMARY KEY CLUSTERED ([SpecialOfferID] ASC)
)
GO


IF object_id('[Production].[Product_ondisk]') IS NOT NULL
	DROP TABLE Production.[Product_ondisk] 
GO
CREATE TABLE [Production].[Product_ondisk](
	[ProductID] [int] IDENTITY NOT NULL,
	[Name] nvarchar(50) COLLATE Latin1_General_100_BIN2 NOT NULL INDEX IX_Name,
	[ProductNumber] [nvarchar](25) COLLATE Latin1_General_100_BIN2 NOT NULL INDEX IX_ProductNumber,
	[MakeFlag] bit NOT NULL CONSTRAINT [ODDF_Product_MakeFlag]  DEFAULT ((1)),
	[FinishedGoodsFlag] bit NOT NULL CONSTRAINT [ODDF_Product_FinishedGoodsFlag]  DEFAULT ((1)),
	[Color] [nvarchar](15) NULL,
	[SafetyStockLevel] [smallint] NOT NULL,
	[ReorderPoint] [smallint] NOT NULL,
	[StandardCost] [money] NOT NULL,
	[ListPrice] [money] NOT NULL,
	[Size] [nvarchar](5) NULL,
	[SizeUnitMeasureCode] [nchar](3) NULL,
	[WeightUnitMeasureCode] [nchar](3) NULL,
	[Weight] [decimal](8, 2) NULL,
	[DaysToManufacture] [int] NOT NULL,
	[ProductLine] [nchar](2) NULL,
	[Class] [nchar](2) NULL,
	[Style] [nchar](2) NULL,
	[ProductSubcategoryID] [int] NULL,
	[ProductModelID] [int] NULL,
	[SellStartDate] [datetime2] NOT NULL,
	[SellEndDate] [datetime2] NULL,
	[DiscontinuedDate] [datetime2] NULL,
	[ModifiedDate] [datetime2] NOT NULL CONSTRAINT [ODDF_Product_ModifiedDate]  DEFAULT (SYSDATETIME()),
	CONSTRAINT [ODPK_Product_ProductID] PRIMARY KEY CLUSTERED ([ProductID]) 
)
GO

/*************************** Load data into migrated tables, as well as comparison tables **********************************/

SET IDENTITY_INSERT Sales.SalesOrderHeader_inmem ON
INSERT INTO Sales.SalesOrderHeader_inmem
	([SalesOrderID],
	[RevisionNumber],
	[OrderDate],
	[DueDate],
	[ShipDate],
	[Status],
	[OnlineOrderFlag],
	[PurchaseOrderNumber],
	[AccountNumber],
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
	[Comment],
	[ModifiedDate])
SELECT
	[SalesOrderID],
	[RevisionNumber],
	[OrderDate],
	[DueDate],
	[ShipDate],
	[Status],
	[OnlineOrderFlag],
	[PurchaseOrderNumber],
	[AccountNumber],
	[CustomerID],
	ISNULL([SalesPersonID],-1),
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
	[Comment],
	[ModifiedDate]
FROM Sales.SalesOrderHeader
SET IDENTITY_INSERT Sales.SalesOrderHeader_inmem OFF
GO

SET IDENTITY_INSERT Sales.SalesOrderHeader_ondisk ON
INSERT INTO Sales.SalesOrderHeader_ondisk
	([SalesOrderID],
	[RevisionNumber],
	[OrderDate],
	[DueDate],
	[ShipDate],
	[Status],
	[OnlineOrderFlag],
	[PurchaseOrderNumber],
	[AccountNumber],
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
	[Comment],
	[ModifiedDate])
SELECT *
FROM Sales.SalesOrderHeader_inmem
SET IDENTITY_INSERT Sales.SalesOrderHeader_ondisk OFF
GO

SET IDENTITY_INSERT Sales.SalesOrderDetail_inmem ON
INSERT INTO Sales.SalesOrderDetail_inmem
	([SalesOrderID],
	[SalesOrderDetailID],
	[CarrierTrackingNumber],
	[OrderQty],
	[ProductID],
	[SpecialOfferID],
	[UnitPrice],
	[UnitPriceDiscount],
	[ModifiedDate])
SELECT
	[SalesOrderID],
	[SalesOrderDetailID],
	[CarrierTrackingNumber],
	[OrderQty],
	[ProductID],
	[SpecialOfferID],
	[UnitPrice],
	[UnitPriceDiscount],
	[ModifiedDate]
FROM Sales.SalesOrderDetail
SET IDENTITY_INSERT Sales.SalesOrderDetail_inmem OFF
GO

SET IDENTITY_INSERT Sales.SalesOrderDetail_ondisk ON
INSERT INTO Sales.SalesOrderDetail_ondisk
	([SalesOrderID],
	[SalesOrderDetailID],
	[CarrierTrackingNumber],
	[OrderQty],
	[ProductID],
	[SpecialOfferID],
	[UnitPrice],
	[UnitPriceDiscount],
	[ModifiedDate])
SELECT *
FROM Sales.SalesOrderDetail_inmem
SET IDENTITY_INSERT Sales.SalesOrderDetail_ondisk OFF
GO




SET IDENTITY_INSERT Sales.SpecialOffer_inmem ON
INSERT INTO Sales.SpecialOffer_inmem
	([SpecialOfferID],
	[Description],
	[DiscountPct],
	[Type],
	[Category],
	[StartDate],
	[EndDate],
	[MinQty],
	[MaxQty],
	[ModifiedDate])
SELECT
	[SpecialOfferID],
	[Description],
	[DiscountPct],
	[Type],
	[Category],
	[StartDate],
	[EndDate],
	[MinQty],
	[MaxQty],
	[ModifiedDate]
FROM Sales.SpecialOffer
SET IDENTITY_INSERT Sales.SpecialOffer_inmem OFF
GO

SET IDENTITY_INSERT Sales.SpecialOffer_ondisk ON
INSERT INTO [Sales].[SpecialOffer_ondisk] 
	([SpecialOfferID],
	[Description],
	[DiscountPct],
	[Type],
	[Category],
	[StartDate],
	[EndDate],
	[MinQty],
	[MaxQty],
	[ModifiedDate])
SELECT * FROM Sales.SpecialOffer_inmem
SET IDENTITY_INSERT Sales.SpecialOffer_ondisk OFF
GO



INSERT INTO Sales.[SpecialOfferProduct_inmem]
SELECT
	[SpecialOfferID],
	ProductID,
	[ModifiedDate]
FROM Sales.[SpecialOfferProduct]
GO





SET IDENTITY_INSERT [Production].[Product_inmem] ON
INSERT INTO [Production].[Product_inmem]
	([ProductID],
	[Name],
	[ProductNumber],
	[MakeFlag],
	[FinishedGoodsFlag],
	[Color],
	[SafetyStockLevel],
	[ReorderPoint],
	[StandardCost],
	[ListPrice],
	[Size],
	[SizeUnitMeasureCode],
	[WeightUnitMeasureCode],
	[Weight],
	[DaysToManufacture],
	[ProductLine],
	[Class],
	[Style],
	[ProductSubcategoryID],
	[ProductModelID],
	[SellStartDate],
	[SellEndDate],
	[DiscontinuedDate],
	[ModifiedDate])
SELECT
	[ProductID],
	[Name],
	[ProductNumber],
	[MakeFlag],
	[FinishedGoodsFlag],
	[Color],
	[SafetyStockLevel],
	[ReorderPoint],
	[StandardCost],
	[ListPrice],
	[Size],
	[SizeUnitMeasureCode],
	[WeightUnitMeasureCode],
	[Weight],
	[DaysToManufacture],
	[ProductLine],
	[Class],
	[Style],
	[ProductSubcategoryID],
	[ProductModelID],
	[SellStartDate],
	[SellEndDate],
	[DiscontinuedDate],
	[ModifiedDate]
FROM [Production].[Product]
SET IDENTITY_INSERT [Production].[Product_inmem] OFF
GO

SET IDENTITY_INSERT [Production].[Product_ondisk] ON
INSERT INTO [Production].[Product_ondisk]
	([ProductID],
	[Name],
	[ProductNumber],
	[MakeFlag],
	[FinishedGoodsFlag],
	[Color],
	[SafetyStockLevel],
	[ReorderPoint],
	[StandardCost],
	[ListPrice],
	[Size],
	[SizeUnitMeasureCode],
	[WeightUnitMeasureCode],
	[Weight],
	[DaysToManufacture],
	[ProductLine],
	[Class],
	[Style],
	[ProductSubcategoryID],
	[ProductModelID],
	[SellStartDate],
	[SellEndDate],
	[DiscontinuedDate],
	[ModifiedDate])
SELECT * FROM [Production].[Product_inmem]
SET IDENTITY_INSERT [Production].[Product_ondisk] OFF
GO



/*************************** Update statistics for memory-optimized tables **********************************/

UPDATE STATISTICS Sales.[SalesOrderHeader_inmem]
WITH FULLSCAN, NORECOMPUTE
GO
UPDATE STATISTICS Sales.[SalesOrderDetail_inmem]
WITH FULLSCAN, NORECOMPUTE
GO

UPDATE STATISTICS Sales.SpecialOfferProduct_inmem
WITH FULLSCAN, NORECOMPUTE
GO
UPDATE STATISTICS Sales.SpecialOffer_inmem
WITH FULLSCAN, NORECOMPUTE
GO

UPDATE STATISTICS Production.Product_inmem
WITH FULLSCAN, NORECOMPUTE
GO

/*************************** Create stored procedures **********************************/

IF object_id('Sales.usp_InsertSalesOrder_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSalesOrder_inmem 
GO
CREATE PROCEDURE Sales.usp_InsertSalesOrder_inmem
	@SalesOrderID int OUTPUT,
	@DueDate [datetime2](7) NOT NULL,
	@CustomerID [int] NOT NULL,
	@BillToAddressID [int] NOT NULL,
	@ShipToAddressID [int] NOT NULL,
	@ShipMethodID [int] NOT NULL,
	@SalesOrderDetails Sales.SalesOrderDetailType_inmem READONLY,
	@Status [tinyint] NOT NULL = 1,
	@OnlineOrderFlag [bit] NOT NULL = 1,
	@PurchaseOrderNumber [nvarchar](25) = NULL,
	@AccountNumber [nvarchar](15) = NULL,
	@SalesPersonID [int] NOT NULL = -1,
	@TerritoryID [int] = NULL,
	@CreditCardID [int] = NULL,
	@CreditCardApprovalCode [varchar](15) = NULL,
	@CurrencyRateID [int] = NULL,
	@Comment nvarchar(128) = NULL
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
  (TRANSACTION ISOLATION LEVEL = SNAPSHOT,
   LANGUAGE = N'us_english')

	DECLARE @OrderDate datetime2 NOT NULL = sysdatetime()

	DECLARE @SubTotal money NOT NULL = 0

	SELECT @SubTotal = ISNULL(SUM(p.ListPrice * (1 - so.DiscountPct)),0)
	FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_inmem so on od.SpecialOfferID=so.SpecialOfferID
		JOIN Production.Product_inmem p on od.ProductID=p.ProductID

	INSERT INTO Sales.SalesOrderHeader_inmem
	(	DueDate,
		Status,
		OnlineOrderFlag,
		PurchaseOrderNumber,
		AccountNumber,
		CustomerID,
		SalesPersonID,
		TerritoryID,
		BillToAddressID,
		ShipToAddressID,
		ShipMethodID,
		CreditCardID,
		CreditCardApprovalCode,
		CurrencyRateID,
		Comment,
		OrderDate,
		SubTotal,
		ModifiedDate)
	VALUES
	(	
		@DueDate,
		@Status,
		@OnlineOrderFlag,
		@PurchaseOrderNumber,
		@AccountNumber,
		@CustomerID,
		@SalesPersonID,
		@TerritoryID,
		@BillToAddressID,
		@ShipToAddressID,
		@ShipMethodID,
		@CreditCardID,
		@CreditCardApprovalCode,
		@CurrencyRateID,
		@Comment,
		@OrderDate,
		@SubTotal,
		@OrderDate
	)

    SET @SalesOrderID = SCOPE_IDENTITY()

	INSERT INTO Sales.SalesOrderDetail_inmem
	(
		SalesOrderID,
		OrderQty,
		ProductID,
		SpecialOfferID,
		UnitPrice,
		UnitPriceDiscount,
		ModifiedDate
	)
    SELECT 
		@SalesOrderID,
		od.OrderQty,
		od.ProductID,
		od.SpecialOfferID,
		p.ListPrice,
		p.ListPrice * so.DiscountPct,
		@OrderDate
	FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_inmem so on od.SpecialOfferID=so.SpecialOfferID
		JOIN Production.Product_inmem p on od.ProductID=p.ProductID

END
GO



IF object_id('Sales.usp_InsertSalesOrder_ondisk') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSalesOrder_ondisk 
GO
CREATE PROCEDURE Sales.usp_InsertSalesOrder_ondisk
	@SalesOrderID int OUTPUT,
	@DueDate [datetime2](7) ,
	@CustomerID [int] ,
	@BillToAddressID [int] ,
	@ShipToAddressID [int] ,
	@ShipMethodID [int] ,
	@SalesOrderDetails Sales.SalesOrderDetailType_ondisk READONLY,
	@Status [tinyint]  = 1,
	@OnlineOrderFlag [bit] = 1,
	@PurchaseOrderNumber [nvarchar](25) = NULL,
	@AccountNumber [nvarchar](15) = NULL,
	@SalesPersonID [int] = -1,
	@TerritoryID [int] = NULL,
	@CreditCardID [int] = NULL,
	@CreditCardApprovalCode [varchar](15) = NULL,
	@CurrencyRateID [int] = NULL,
	@Comment nvarchar(128) = NULL
AS
BEGIN 
	BEGIN TRAN
	
		DECLARE @OrderDate datetime2 = sysdatetime()

		DECLARE @SubTotal money = 0

		SELECT @SubTotal = ISNULL(SUM(p.ListPrice * (1 - so.DiscountPct)),0)
		FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_ondisk so on od.SpecialOfferID=so.SpecialOfferID
			JOIN Production.Product_ondisk p on od.ProductID=p.ProductID

		INSERT INTO Sales.SalesOrderHeader_ondisk
		(	DueDate,
			Status,
			OnlineOrderFlag,
			PurchaseOrderNumber,
			AccountNumber,
			CustomerID,
			SalesPersonID,
			TerritoryID,
			BillToAddressID,
			ShipToAddressID,
			ShipMethodID,
			CreditCardID,
			CreditCardApprovalCode,
			CurrencyRateID,
			Comment,
			OrderDate,
			SubTotal,
			ModifiedDate)
		VALUES
		(	
			@DueDate,
			@Status,
			@OnlineOrderFlag,
			@PurchaseOrderNumber,
			@AccountNumber,
			@CustomerID,
			@SalesPersonID,
			@TerritoryID,
			@BillToAddressID,
			@ShipToAddressID,
			@ShipMethodID,
			@CreditCardID,
			@CreditCardApprovalCode,
			@CurrencyRateID,
			@Comment,
			@OrderDate,
			@SubTotal,
			@OrderDate
		)

		SET @SalesOrderID = SCOPE_IDENTITY()

		INSERT INTO Sales.SalesOrderDetail_ondisk
		(
			SalesOrderID,
			OrderQty,
			ProductID,
			SpecialOfferID,
			UnitPrice,
			UnitPriceDiscount,
			ModifiedDate
		)
		SELECT 
			@SalesOrderID,
			od.OrderQty,
			od.ProductID,
			od.SpecialOfferID,
			p.ListPrice,
			p.ListPrice * so.DiscountPct,
			@OrderDate
		FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_ondisk so on od.SpecialOfferID=so.SpecialOfferID
			JOIN Production.Product_ondisk p on od.ProductID=p.ProductID


	COMMIT
END
GO



IF object_id('Sales.usp_UpdateSalesOrderShipInfo_native') IS NOT NULL
	DROP PROCEDURE Sales.usp_UpdateSalesOrderShipInfo_native 
GO
CREATE PROCEDURE Sales.usp_UpdateSalesOrderShipInfo_native
	@SalesOrderID int , 
	@ShipDate datetime2,
	@Comment nvarchar(128),
	@Status tinyint,
	@TaxRate smallmoney,
	@Freight money,
	@CarrierTrackingNumber nvarchar(25)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
  (TRANSACTION ISOLATION LEVEL = SNAPSHOT,
   LANGUAGE = N'us_english')

	DECLARE @now datetime2 = SYSDATETIME()

	UPDATE Sales.SalesOrderDetail_inmem 
	SET CarrierTrackingNumber = @CarrierTrackingNumber, ModifiedDate = @now
	WHERE SalesOrderID = @SalesOrderID

	UPDATE Sales.SalesOrderHeader_inmem
	SET RevisionNumber = RevisionNumber + 1,
		ShipDate = @ShipDate,
		Status = @Status,
		TaxAmt = SubTotal * @TaxRate,
		Freight = @Freight,
		ModifiedDate = @now
	WHERE SalesOrderID = @SalesOrderID

END
GO


IF object_id('Sales.usp_UpdateSalesOrderShipInfo_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_UpdateSalesOrderShipInfo_inmem 
GO
-- for simplicity, we assume all items in the order are shipped in the same package, and thus have the same carrier tracking number
CREATE PROCEDURE Sales.usp_UpdateSalesOrderShipInfo_inmem
	@SalesOrderID int , 
	@ShipDate datetime2 = NULL,
	@Comment nvarchar(128) = NULL,
	@Status tinyint,
	@TaxRate smallmoney = 0,
	@Freight money,
	@CarrierTrackingNumber nvarchar(25)
AS
BEGIN

  DECLARE @retry INT = 10
  SET @ShipDate = ISNULL(@ShipDate, SYSDATETIME())

  WHILE (@retry > 0)
  BEGIN
    BEGIN TRY

      EXEC Sales.usp_UpdateSalesOrderShipInfo_native
		@SalesOrderID = @SalesOrderID, 
		@ShipDate = @ShipDate,
		@Comment = @Comment,
		@Status = @Status,
		@TaxRate = @TaxRate,
		@Freight = @Freight,
		@CarrierTrackingNumber = @CarrierTrackingNumber


      SET @retry = 0
    END TRY
    BEGIN CATCH
      SET @retry -= 1
  
      IF (@retry > 0 AND error_number() in (41302, 41305, 41325, 41301))
      BEGIN

        IF XACT_STATE() <> 0 
          ROLLBACK TRANSACTION

      END
      ELSE
      BEGIN
        ;THROW
      END
    END CATCH
  END
END
GO

IF object_id('Sales.usp_UpdateSalesOrderShipInfo_ondisk') IS NOT NULL
	DROP PROCEDURE Sales.usp_UpdateSalesOrderShipInfo_ondisk 
GO
-- for simplicity, we assume all items in the order are shipped in the same package, and thus have the same carrier tracking number
CREATE PROCEDURE Sales.usp_UpdateSalesOrderShipInfo_ondisk
	@SalesOrderID int , 
	@ShipDate datetime2 = NULL,
	@Comment nvarchar(128) = NULL,
	@Status tinyint,
	@TaxRate smallmoney = 0,
	@Freight money,
	@CarrierTrackingNumber nvarchar(25)
AS
BEGIN
  SET @ShipDate = ISNULL(@ShipDate, SYSDATETIME())

  BEGIN TRAN
	DECLARE @now datetime2 = SYSDATETIME()

	UPDATE Sales.SalesOrderDetail_ondisk 
	SET CarrierTrackingNumber = @CarrierTrackingNumber, ModifiedDate = @now
	WHERE SalesOrderID = @SalesOrderID

	UPDATE Sales.SalesOrderHeader_ondisk
	SET RevisionNumber = RevisionNumber + 1,
		ShipDate = @ShipDate,
		Status = @Status,
		TaxAmt = SubTotal * @TaxRate,
		Freight = @Freight,
		ModifiedDate = @now
	WHERE SalesOrderID = @SalesOrderID
  COMMIT

END
GO
/*************************** Demo harness **********************************/

IF object_id('Demo.usp_DemoInsertSalesOrders') IS NOT NULL
	DROP PROCEDURE Demo.usp_DemoInsertSalesOrders 
go
IF object_id('Demo.usp_DemoInitSeed') IS NOT NULL
	DROP PROCEDURE Demo.usp_DemoInitSeed 
GO
IF object_id('Demo.DemoSalesOrderDetailSeed') IS NOT NULL
	DROP TABLE Demo.DemoSalesOrderDetailSeed 
GO
IF object_id('Demo.DemoSalesOrderHeaderSeed') IS NOT NULL
	DROP TABLE Demo.DemoSalesOrderHeaderSeed 
GO
IF object_id('Demo.usp_DemoReset') IS NOT NULL
	DROP PROCEDURE Demo.usp_DemoReset 
GO
IF schema_id('Demo') IS NOT NULL
	DROP SCHEMA Demo
GO
CREATE SCHEMA Demo
GO


IF object_id('Demo.DemoSalesOrderDetailSeed') IS NOT NULL
	DROP TABLE Demo.DemoSalesOrderDetailSeed 
GO
CREATE TABLE Demo.DemoSalesOrderDetailSeed
(
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL ,
	[SpecialOfferID] [int] NOT NULL,
	OrderID int NOT NULL INDEX IX_OrderID NONCLUSTERED HASH WITH (BUCKET_COUNT=1000000),
	LocalID int IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED	
) WITH (MEMORY_OPTIMIZED=ON)
GO

IF object_id('Demo.DemoSalesOrderHeaderSeed') IS NOT NULL
	DROP TABLE Demo.DemoSalesOrderHeaderSeed 
GO
CREATE TABLE Demo.DemoSalesOrderHeaderSeed
(
	DueDate [datetime2](7) NOT NULL,
	CustomerID [int] NOT NULL,
	SalesPersonID [int] NOT NULL,
	BillToAddressID [int] NOT NULL,
	ShipToAddressID [int] NOT NULL,
	ShipMethodID [int] NOT NULL,
	LocalID int IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED	
) WITH (MEMORY_OPTIMIZED=ON)
GO


IF object_id('Demo.usp_DemoInitSeed') IS NOT NULL
	DROP PROCEDURE Demo.usp_DemoInitSeed 
GO
CREATE PROCEDURE Demo.usp_DemoInitSeed @items_per_order int = 5
AS
BEGIN
	DECLARE @ProductID int, @SpecialOfferID int,
		@i int = 1
	DECLARE @seed_order_count int = (SELECT COUNT(*)/@items_per_order FROM Sales.SpecialOfferProduct_inmem)

	DECLARE seed_cursor CURSOR FOR 
		SELECT 
			ProductID,
			SpecialOfferID 
		FROM Sales.SpecialOfferProduct_inmem

	OPEN seed_cursor

	FETCH NEXT FROM seed_cursor 
	INTO @ProductID, @SpecialOfferID

	BEGIN TRAN

		DELETE FROM Demo.DemoSalesOrderHeaderSeed

		INSERT INTO Demo.DemoSalesOrderHeaderSeed
		(
			DueDate,
			CustomerID,
			SalesPersonID,
			BillToAddressID,
			ShipToAddressID,
			ShipMethodID
		)
		SELECT
			dateadd(d, (rand(BillToAddressID*CustomerID)*10)+1,cast(sysdatetime() as date)),
			CustomerID,
			SalesPersonID,
			BillToAddressID,
			ShipToAddressID,
			ShipMethodID
		FROM Sales.SalesOrderHeader_inmem


		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT Demo.DemoSalesOrderDetailSeed
			SELECT 
				@i % 6 + 1,
				@ProductID,
				@SpecialOfferID,
				@i % (@seed_order_count+1)

			SET @i += 1

			FETCH NEXT FROM seed_cursor 
			INTO @ProductID, @SpecialOfferID
		END

		CLOSE seed_cursor
		DEALLOCATE seed_cursor
	COMMIT

	UPDATE STATISTICS Demo.DemoSalesOrderDetailSeed
	WITH FULLSCAN, NORECOMPUTE
END
GO


/*
IF object_id('Demo.usp_DemoInsertSalesOrders') IS NOT NULL
	DROP PROCEDURE Demo.usp_DemoInsertSalesOrders 
go
CREATE PROCEDURE Demo.usp_DemoInsertSalesOrders @use_inmem bit = 1, @order_count int = 100000, @include_update bit = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @max_OrderID int = (SELECT MAX(OrderID) FROM Demo.DemoSalesOrderDetailSeed)

	DECLARE @i int = 1
	DECLARE
		@SalesOrderID int,
		@DueDate datetime2,
		@now datetime2 = sysdatetime(),
		@OnlineOrderFlag bit = 1

	DECLARE @Comment nvarchar(128)
	DECLARE @TaxRate smallmoney
	DECLARE @Freight money
	DECLARE @CarrierTrackingNumber nvarchar(25),
		@ShipDate datetime2
	
	WHILE @i <= @order_count
	BEGIN
		IF @use_inmem = 1
		BEGIN
			DECLARE @od Sales.SalesOrderDetailType_inmem
			
			SET @DueDate = DATEADD(d, (@i % 10) + 2, @now)

			DELETE FROM @od

			INSERT @od
			SELECT OrderQty, ProductID, SpecialOfferID
			FROM Demo.DemoSalesOrderDetailSeed
			WHERE OrderID = @i % @max_OrderID


			EXEC Sales.usp_InsertSalesOrder_inmem
				@SalesOrderID = @SalesOrderID, 
				@DueDate = @DueDate,
				@OnlineOrderFlag = @OnlineOrderFlag,
				@SalesOrderDetails = @od

			IF @include_update = 1
			BEGIN
				SET @Comment = N'comment' + cast(@i as nvarchar)
				SET @TaxRate = (@i % 10) / 100
				SET @Freight = (@i % 500)/10
				SET @CarrierTrackingNumber = N'DemoTrackingNr' + cast (@i AS nvarchar)
				SET @ShipDate = @now
				EXEC Sales.usp_UpdateSalesOrderShipInfo_inmem 
					@SalesOrderID = @SalesOrderID, 
					@ShipDate = @ShipDate, 
					@Comment = @Comment, 
					@Status=2, 
					@TaxRate = @TaxRate, 
					@Freight = @Freight,
					@CarrierTrackingNumber = @CarrierTrackingNumber
			END
		END
		ELSE BEGIN
			DECLARE @odd Sales.SalesOrderDetailType_ondisk
			SET @DueDate = DATEADD(d, (@i % 10) + 2, @now)

			DELETE FROM @odd

			INSERT @odd
			SELECT OrderQty, ProductID, SpecialOfferID
			FROM Demo.DemoSalesOrderDetailSeed
			WHERE OrderID = @i % @max_OrderID

			EXEC Sales.usp_InsertSalesOrder_ondisk
				@SalesOrderID = @SalesOrderID, 
				@DueDate = @DueDate,
				@OnlineOrderFlag = @OnlineOrderFlag,
				@SalesOrderDetails = @odd

			IF @include_update = 1
			BEGIN
				SET @Comment = N'comment' + cast(@i as nvarchar)
				SET @TaxRate = (@i % 10) / 100
				SET @Freight = (@i % 500)/10
				SET @CarrierTrackingNumber = N'DemoTrackingNr' + cast (@i AS nvarchar)
				SET @ShipDate = @now
				EXEC Sales.usp_UpdateSalesOrderShipInfo_ondisk
					@SalesOrderID = @SalesOrderID, 
					@ShipDate = @ShipDate, 
					@Comment = @Comment, 
					@Status=2, 
					@TaxRate = @TaxRate, 
					@Freight = @Freight,
					@CarrierTrackingNumber = @CarrierTrackingNumber
			END
		END

		SET @i += 1
	END

END
GO

*/

IF object_id('Demo.usp_DemoReset') IS NOT NULL
	DROP PROCEDURE Demo.usp_DemoReset 
GO
CREATE PROCEDURE Demo.usp_DemoReset
AS
BEGIN
	truncate table Sales.SalesOrderDetail_ondisk
	delete from Sales.SalesOrderDetail_inmem
	truncate table Sales.SalesOrderHeader_ondisk
	delete from Sales.SalesOrderHeader_inmem
	
	CHECKPOINT

	SET IDENTITY_INSERT Sales.SalesOrderHeader_inmem ON
	INSERT INTO Sales.SalesOrderHeader_inmem
		([SalesOrderID],
		[RevisionNumber],
		[OrderDate],
		[DueDate],
		[ShipDate],
		[Status],
		[OnlineOrderFlag],
		[PurchaseOrderNumber],
		[AccountNumber],
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
		[Comment],
		[ModifiedDate])
	SELECT
		[SalesOrderID],
		[RevisionNumber],
		[OrderDate],
		[DueDate],
		[ShipDate],
		[Status],
		[OnlineOrderFlag],
		[PurchaseOrderNumber],
		[AccountNumber],
		[CustomerID],
		ISNULL([SalesPersonID],-1),
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
		[Comment],
		[ModifiedDate]
	FROM Sales.SalesOrderHeader
	SET IDENTITY_INSERT Sales.SalesOrderHeader_inmem OFF


	SET IDENTITY_INSERT Sales.SalesOrderHeader_ondisk ON
	INSERT INTO Sales.SalesOrderHeader_ondisk
		([SalesOrderID],
		[RevisionNumber],
		[OrderDate],
		[DueDate],
		[ShipDate],
		[Status],
		[OnlineOrderFlag],
		[PurchaseOrderNumber],
		[AccountNumber],
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
		[Comment],
		[ModifiedDate])
	SELECT *
	FROM Sales.SalesOrderHeader_inmem
	SET IDENTITY_INSERT Sales.SalesOrderHeader_ondisk OFF


	SET IDENTITY_INSERT Sales.SalesOrderDetail_inmem ON
	INSERT INTO Sales.SalesOrderDetail_inmem
		([SalesOrderID],
		[SalesOrderDetailID],
		[CarrierTrackingNumber],
		[OrderQty],
		[ProductID],
		[SpecialOfferID],
		[UnitPrice],
		[UnitPriceDiscount],
		[ModifiedDate])
	SELECT
		[SalesOrderID],
		[SalesOrderDetailID],
		[CarrierTrackingNumber],
		[OrderQty],
		[ProductID],
		[SpecialOfferID],
		[UnitPrice],
		[UnitPriceDiscount],
		[ModifiedDate]
	FROM Sales.SalesOrderDetail
	SET IDENTITY_INSERT Sales.SalesOrderDetail_inmem OFF


	SET IDENTITY_INSERT Sales.SalesOrderDetail_ondisk ON
	INSERT INTO Sales.SalesOrderDetail_ondisk
		([SalesOrderID],
		[SalesOrderDetailID],
		[CarrierTrackingNumber],
		[OrderQty],
		[ProductID],
		[SpecialOfferID],
		[UnitPrice],
		[UnitPriceDiscount],
		[ModifiedDate])
	SELECT *
	FROM Sales.SalesOrderDetail_inmem
	SET IDENTITY_INSERT Sales.SalesOrderDetail_ondisk OFF

	CHECKPOINT
END
GO
/*************************************  Initialize Demo seed table ********************************************/

EXEC Demo.usp_DemoInitSeed
GO

/************************************* Helper functions for generating integrity checks that are 
									   not supported with memory-optimized tables in SQL Server 2014 ***********************/

IF object_id('dbo.usp_GenerateFKCheck') IS NOT NULL
	DROP PROCEDURE dbo.usp_GenerateFKCheck
go
IF object_id('dbo.usp_GenerateUQCheck') IS NOT NULL
	DROP PROCEDURE dbo.usp_GenerateUQCheck
go
IF type_id('dbo.ColumnList') IS NOT NULL
	DROP TYPE dbo.ColumnList 
go
CREATE TYPE dbo.ColumnList AS TABLE
(
	[id] int IDENTITY NOT NULL INDEX ix_id clustered,
	name nvarchar(128) NOT NULL
)
GO

IF object_id('dbo.usp_GenerateFKCheck') IS NOT NULL
	DROP PROCEDURE dbo.usp_GenerateFKCheck
go
/*********************
Procedure for generating checks useful for validating and enforcing referential integrity, in the absence of foreign key constraints
	to generate a point lookup check, suitable for enforcement at insert time, provide @reference_parameters; 
		from @from_object and @from_clist are not needed in this case
	to generate a validation query, suitable for referential integrity checks after the fact, provide @from_object and @from_clist; 
		to validate integrity for the entire @from_object, do not provide @reference_parameters
*********************/
CREATE PROCEDURE dbo.usp_GenerateFKCheck
		@from_object int = NULL,
		@to_object int,
		@from_clist dbo.ColumnList READONLY,
		@to_clist dbo.ColumnList READONLY,
		@reference_parameters dbo.ColumnList READONLY,
		@sql_check_fk nvarchar(max) OUTPUT
AS
BEGIN		

	IF (@from_object IS NULL OR (SELECT COUNT(*) FROM @from_clist) = 0) AND (SELECT COUNT(*) FROM @reference_parameters)=0
	BEGIN
		;THROW 50001, N'Either provide @reference_parameters, for a point lookup, or provide @from_object and @from_clist to validate the entire table', 1
	END

	-- logic in case of from object is specified
	IF @from_object IS NOT NULL AND (SELECT COUNT(*) FROM @from_clist) > 0
	BEGIN
		IF (SELECT COUNT(*) FROM @to_clist) != (SELECT COUNT(*) FROM @from_clist)
		BEGIN
			;THROW 50001, N'Parameter @to_clist must contain the same number of entries as @from_clist', 1
		END

		SET @sql_check_fk = N'	DECLARE @fk_violation bit = 0 
		' 
			+ N'SELECT @fk_violation=1 FROM ' 
			+ quotename(object_schema_name(@from_object))
			+ N'.' 
			+ quotename(object_name(@from_object))
			+ N' t1'

		SET @sql_check_fk += N'
		WHERE NOT EXISTS (SELECT * FROM '
			+ quotename(object_schema_name(@to_object))
			+ N'.' 
			+ quotename(object_name(@to_object))
			+ N' t2 WHERE 1=1'

		SELECT @sql_check_fk += N' AND (t1.' 
			+ QUOTENAME(f.name) 
			+ N' IS NULL OR TRY_CAST(t1.'
			+ QUOTENAME(f.name) 
			+ ' AS int) = -1 OR t1.'
			+ QUOTENAME(f.name) 
			+ N'=t2.' 
			+ QUOTENAME(t.name) 
			+ N')'
		FROM @from_clist f JOIN @to_clist t ON f.id=t.id

		SELECT @sql_check_fk += N')'
	END
	ELSE
	-- logic if there is no from object
	BEGIN

		SET @sql_check_fk = N'	DECLARE @fk_violation bit = 1 
		' 
			+ N'SELECT @fk_violation=0 FROM ' 
			+ quotename(object_schema_name(@to_object))
			+ N'.' 
			+ quotename(object_name(@to_object))
			+ N' t1'

		SET @sql_check_fk += N'
		WHERE 1=1'

	END

	-- filter parameters
	IF EXISTS (SELECT id FROM @reference_parameters)
	BEGIN
		SELECT @sql_check_fk += N' AND t1.' + QUOTENAME(t.name) 
			+ N'=' 
			+ p.name 
		FROM @to_clist t JOIN @reference_parameters p ON t.id=p.id
	END

/*
	SELECT @sql_check_fk += N'
	OPTION (LOOP JOIN)'
*/

	SET @sql_check_fk += N'
	IF @fk_violation=1
	BEGIN
		'
		+ 'DECLARE @msg nvarchar(256) = N''Violation of referential integrity'
	
	IF @from_object IS NOT NULL
		SET @sql_check_fk += ' from table '
			+ quotename(object_schema_name(@from_object))
			+ N'.' 
			+ quotename(object_name(@from_object))

	SET @sql_check_fk += ' to table '
		+ quotename(object_schema_name(@to_object))
		+ N'.' 
		+ quotename(object_name(@to_object))
		+ ''''


	SET @sql_check_fk += '
		;THROW 50001, @msg, 1
	END
	'
END
GO


IF object_id('dbo.usp_GenerateCKCheck') IS NOT NULL
	DROP PROCEDURE dbo.usp_GenerateCKCheck
go
/*********************
 Procedure for generating checks validating integrity of the data in a table, in the absence of check constraints
	to generate a single value check, suitable for enforcement at insert time, only @ck_expression; 
		do not provide @on_object
	to generate a validation query, suitable for integrity checks after the fact, provide @on_object
*********************/
CREATE PROCEDURE dbo.usp_GenerateCKCheck
		@ck_expression nvarchar(1000),
		@on_object int = NULL,
		@sql_check_ck nvarchar(max) OUTPUT
AS
BEGIN		

	IF @ck_expression IS NULL
	BEGIN
		;THROW 50001, N'Provide a valid logical expression for @ck_expression', 1
	END

	-- logic in case of on object is specified
	IF @on_object IS NOT NULL
	BEGIN
		SET @sql_check_ck = N'	DECLARE @ck_violation bit = 0 
		' 
			+ N'SELECT @ck_violation=1 FROM ' 
			+ quotename(object_schema_name(@on_object))
			+ N'.' 
			+ quotename(object_name(@on_object))
			+ N' t1'

		SET @sql_check_ck += N'
		WHERE NOT ('
			+ @ck_expression
			+ N')'
	END
	ELSE
	-- logic if there is no on object
	BEGIN

		SET @sql_check_ck = N'	DECLARE @ck_violation bit = 1 
		' 
			+ N'IF ' 
			+ @ck_expression
			+ N'
				SET @ck_violation=0' 
	END

	SET @sql_check_ck += N'
	IF @ck_violation=1
	BEGIN
		'
		+ 'DECLARE @msg nvarchar(256) = N''Violation of integrity constraint ['
		+ replace(@ck_expression, '''', '''''')
		+ ']'
	
	IF @on_object IS NOT NULL
		SET @sql_check_ck += ' on table '
			+ quotename(object_schema_name(@on_object))
			+ N'.' 
			+ quotename(object_name(@on_object))

	SET @sql_check_ck += ''''


	SET @sql_check_ck += '
		;THROW 50001, @msg, 1
	END
	'
END
GO


IF object_id('dbo.usp_GenerateUQCheck') IS NOT NULL
	DROP PROCEDURE dbo.usp_GenerateUQCheck
go
/*********************
Procedure for generating checks useful for validating and enforcing uniqueness, in the absence of unique constraints
	to generate a point lookup check, suitable for enforcement at insert time, provide @reference_parameters
	to generate a validation query, suitable for referential integrity checks after the fact, 
		to validate integrity for the entire @on_object, do not provide @reference_parameters
*********************/
CREATE PROCEDURE dbo.usp_GenerateUQCheck
		@on_object int,
		@on_clist dbo.ColumnList READONLY,
		@reference_parameters dbo.ColumnList READONLY,
		@sql_check_uq nvarchar(max) OUTPUT
AS
BEGIN		

	IF @on_object IS NULL OR (SELECT COUNT(*) FROM @on_clist) = 0
	BEGIN
		;THROW 50001, N'Provide @on_object and @on_clist to validate uniqueness', 1
	END

	-- logic in case of no reference parameters
	IF (SELECT COUNT(*) FROM @reference_parameters) = 0
	BEGIN
		SET @sql_check_uq = N'	DECLARE @uq_violation bit = 0 
		' 
			+ N'IF (SELECT COUNT(*) FROM ' 
			+ quotename(object_schema_name(@on_object))
			+ N'.' 
			+ quotename(object_name(@on_object))
			+ N') > (SELECT COUNT (*) FROM (SELECT DISTINCT 1 AS [1dummycolumn1]'

		SELECT @sql_check_uq += N', ' 
			+ QUOTENAME(f.name) 
		FROM @on_clist f

		SET @sql_check_uq += N' FROM '
			+ quotename(object_schema_name(@on_object))
			+ N'.' 
			+ quotename(object_name(@on_object))
			+ N') a)
			SET @uq_violation=1'

	END
	ELSE
	-- logic if there are reference parameters
	BEGIN

		IF (SELECT COUNT(*) FROM @reference_parameters) != (SELECT COUNT(*) FROM @on_clist)
		BEGIN
			;THROW 50001, N'Parameters @reference_parameters and @on_clist must have the same cardinality', 1
		END

		SET @sql_check_uq = N'	DECLARE @fk_violation bit = 0
		' 
			+ N'SELECT @fk_violation=1 FROM ' 
			+ quotename(object_schema_name(@on_object))
			+ N'.' 
			+ quotename(object_name(@on_object))
			+ N' '

		SET @sql_check_uq += N'
		WHERE 1=1'

		SELECT @sql_check_uq += N' AND ' + QUOTENAME(t.name) 
			+ N'=' 
			+ p.name 
		FROM @on_clist t JOIN @reference_parameters p ON t.id=p.id
	END



	SET @sql_check_uq += N'
	IF @uq_violation=1
	BEGIN
		'
		+ 'DECLARE @msg nvarchar(256) = N''Violation of uniqueness'
	
	SET @sql_check_uq += ' on table '
		+ quotename(object_schema_name(@on_object))
		+ N'.' 
		+ quotename(object_name(@on_object))
		+ ''''


	SET @sql_check_uq += '
		;THROW 50001, @msg, 1
	END
	'
END
GO


/**************** tables with metadata about database integrity *****************/


IF object_id('dbo.ReferentialIntegrity') IS NOT NULL
	DROP TABLE dbo.ReferentialIntegrity
go
CREATE TABLE dbo.ReferentialIntegrity
(
	from_object nvarchar(256) not null,
	to_object nvarchar(256) not null,
	number smallint not null default (1),
	from_column nvarchar(128) not null,
	to_column nvarchar(128) not null,

	index ix_ReferentialIntegrity clustered (from_object)
)
GO
IF object_id('dbo.DomainIntegrity') IS NOT NULL
	DROP TABLE dbo.DomainIntegrity
go
CREATE TABLE dbo.DomainIntegrity
(
	on_object nvarchar(256) not null,
	expression nvarchar(1000) not null,
	index ix_ci clustered (on_object)
)
GO

IF object_id('dbo.UniqueIntegrity') IS NOT NULL
	DROP TABLE dbo.UniqueIntegrity
go
CREATE TABLE dbo.UniqueIntegrity
(
	on_object nvarchar(256) not null,
	number smallint not null,
	column_name nvarchar(256) not null,
	index ix_ci clustered (on_object, number) 
)
GO

-- insert information about integrity for the migrated tables
INSERT dbo.UniqueIntegrity (on_object, number, column_name) VALUES 
	('Production.Product_inmem', 1, 'Name'),
	('Production.Product_inmem', 2, 'ProductNumber')

INSERT dbo.ReferentialIntegrity (from_object, to_object, number, from_column, to_column) VALUES 
	('Production.Product_inmem', 'Production.ProductModel', 1, 'ProductModelID', 'ProductModelID'),
	('Production.Product_inmem', 'Production.ProductSubcategory', 1, 'ProductSubcategoryID', 'ProductSubcategoryID'),
	('Production.Product_inmem', 'Production.UnitMeasure', 1, 'SizeUnitMeasureCode', 'UnitMeasureCode'),
	('Production.Product_inmem', 'Production.UnitMeasure', 2, 'WeightUnitMeasureCode', 'UnitMeasureCode')

INSERT dbo.DomainIntegrity (on_object, expression) VALUES
	('Production.Product_inmem', '(upper([Class])=''H'' OR upper([Class])=''M'' OR upper([Class])=''L'' OR [Class] IS NULL)'),
	('Production.Product_inmem', '[DaysToManufacture]>=(0)'),
	('Production.Product_inmem', '[ListPrice]>=(0.00)'),
	('Production.Product_inmem', '(upper([ProductLine])=''R'' OR upper([ProductLine])=''M'' OR upper([ProductLine])=''T'' OR upper([ProductLine])=''S'' OR [ProductLine] IS NULL)'),
	('Production.Product_inmem', '[ReorderPoint]>(0)'),
	('Production.Product_inmem', '[SafetyStockLevel]>(0)'),
	('Production.Product_inmem', '[SellEndDate]>=[SellStartDate] OR [SellEndDate] IS NULL'),
	('Production.Product_inmem', '[StandardCost]>=(0.00)'),
	('Production.Product_inmem', 'upper([Style])=''U'' OR upper([Style])=''M'' OR upper([Style])=''W'' OR [Style] IS NULL'),
	('Production.Product_inmem', '[Weight]>(0.00)')

INSERT dbo.DomainIntegrity (on_object, expression) VALUES
	('Sales.SpecialOffer_inmem', '[DiscountPct]>=(0.00)'),
	('Sales.SpecialOffer_inmem', '[EndDate]>=[StartDate]'),
	('Sales.SpecialOffer_inmem', '[MaxQty]>=(0)'),
	('Sales.SpecialOffer_inmem', '[MinQty]>=(0)')

INSERT dbo.ReferentialIntegrity (from_object, to_object, from_column, to_column) VALUES 
	('Sales.SpecialOfferProduct_inmem', 'Production.Product', 'ProductID', 'ProductID'),
	('Sales.SpecialOfferProduct_inmem', 'Sales.SpecialOffer', 'SpecialOfferID', 'SpecialOfferID')


INSERT dbo.ReferentialIntegrity (from_object, to_object, number, from_column, to_column) VALUES 
	('Sales.SalesOrderHeader_inmem', 'Person.Address', 1, 'BillToAddressID', 'AddressID'),
	('Sales.SalesOrderHeader_inmem', 'Person.Address', 2, 'ShipToAddressID', 'AddressID'),
	('Sales.SalesOrderHeader_inmem', 'Sales.CreditCard', 1, 'CreditCardID', 'CreditCardID'),
	('Sales.SalesOrderHeader_inmem', 'Sales.CurrencyRate', 1, 'CurrencyRateID', 'CurrencyRateID'),
	('Sales.SalesOrderHeader_inmem', 'Sales.Customer', 1, 'CustomerID', 'CustomerID'),
	('Sales.SalesOrderHeader_inmem', 'Sales.SalesPerson', 1, 'SalesPersonID', 'BusinessEntityID'),
	('Sales.SalesOrderHeader_inmem', 'Sales.SalesTerritory', 1, 'TerritoryID', 'TerritoryID'),
	('Sales.SalesOrderHeader_inmem', 'Purchasing.ShipMethod', 1, 'ShipMethodID', 'ShipMethodID')

INSERT dbo.DomainIntegrity (on_object, expression) VALUES
	('Sales.SalesOrderHeader_inmem', '[DueDate]>=[OrderDate]'),
	('Sales.SalesOrderHeader_inmem', '[Freight]>=(0.00)'),
	('Sales.SalesOrderHeader_inmem', '[ShipDate]>=[OrderDate] OR [ShipDate] IS NULL'),
	('Sales.SalesOrderHeader_inmem', '[Status]>=(0) AND [Status]<=(8)'),
	('Sales.SalesOrderHeader_inmem', '[SubTotal]>=(0.00)'),
	('Sales.SalesOrderHeader_inmem', '[TaxAmt]>=(0.00)')

INSERT dbo.ReferentialIntegrity (from_object, to_object, number, from_column, to_column) VALUES 
	('Sales.SalesOrderDetail_inmem', 'Sales.SalesOrderHeader_inmem', 1, 'SalesOrderID', 'SalesOrderID'),
	('Sales.SalesOrderDetail_inmem', 'Sales.SpecialOfferProduct_inmem', 1, 'SpecialOfferID', 'SpecialOfferID'),
	('Sales.SalesOrderDetail_inmem', 'Sales.SpecialOfferProduct_inmem', 1, 'ProductID', 'ProductID')

INSERT dbo.DomainIntegrity (on_object, expression) VALUES
	('Sales.SalesOrderDetail_inmem', '[OrderQty]>(0)'),
	('Sales.SalesOrderDetail_inmem', '[UnitPrice]>=(0.00)'),
	('Sales.SalesOrderDetail_inmem', '[UnitPriceDiscount]>=(0.00)')
GO

IF object_id('dbo.usp_ValidateIntegrity') IS NOT NULL
	DROP PROCEDURE dbo.usp_ValidateIntegrity
go
-- proc to validate referential and domain integrity for a given object, based on the contents
--   of the tables dbo.ReferentialIntegrity and dbo.DomainIntegrity
CREATE PROCEDURE dbo.usp_ValidateIntegrity @object_id int = NULL
AS
BEGIN
	SET NOCOUNT ON

	IF @object_id IS NOT NULL AND NOT EXISTS (SELECT * FROM sys.tables WHERE object_id=@object_id)
	BEGIN
		;THROW 50001, N'Parameter @object_id must be the object_id of a table in the current database', 1
	END

	DECLARE @fk_count int = 0,
		@ck_count int = 0,
		@uq_count int = 0

	DECLARE @from_object nvarchar(256), 
		@to_object nvarchar(256), 
		@number int, 
		@expression nvarchar(1000),
		@prev_from_object nvarchar(256)
	BEGIN TRY
		DECLARE fk_cursor CURSOR FOR 
			SELECT DISTINCT from_object, to_object, number 
			FROM dbo.ReferentialIntegrity
			WHERE @object_id IS NULL OR object_id(from_object) = @object_id
			ORDER BY from_object, to_object, number 

		OPEN fk_cursor

		FETCH NEXT FROM fk_cursor 
		INTO @from_object, @to_object, @number

		PRINT N'Referential integrity validation:'
		PRINT N''

		WHILE @@FETCH_STATUS=0
		BEGIN
			SET @prev_from_object = @from_object

			DECLARE 
				@to_clist dbo.ColumnList ,
				@from_clist dbo.ColumnList ,
				@sql_check_fk nvarchar(1000),
				@reference_parameters dbo.ColumnList

			DELETE FROM @to_clist
			DELETE FROM @from_clist

			INSERT @from_clist 
			SELECT from_column FROM dbo.ReferentialIntegrity
			WHERE from_object=@from_object AND to_object=@to_object and number=@number
			ORDER BY from_column, to_column

			INSERT @to_clist 
			SELECT to_column FROM dbo.ReferentialIntegrity
			WHERE from_object=@from_object AND to_object=@to_object and number=@number
			ORDER BY from_column, to_column

			declare @from_object_id int = object_id(@from_object)
			declare @to_object_id int = object_id(@to_object)
			EXEC usp_GenerateFKCheck @from_object_id, @to_object_id, @from_clist, @to_clist, @reference_parameters, @sql_check_fk OUTPUT
			EXEC sp_executesql @sql_check_fk
			SET @sql_check_fk = N''

			SET @fk_count += 1

			FETCH NEXT FROM fk_cursor 
			INTO @from_object, @to_object, @number

			IF (object_id(@from_object)!=object_id(@prev_from_object)) OR @@FETCH_STATUS!=0
			BEGIN
				PRINT @prev_from_object
					+ N': validated '
					+ cast(@fk_count as nvarchar) 
					+ N' referential integrity rules'

				SET @fk_count = 0
			END
		END

		CLOSE fk_cursor
		DEALLOCATE fk_cursor			

		DECLARE ck_cursor CURSOR FOR 
			SELECT on_object, expression
			FROM dbo.DomainIntegrity
			WHERE @object_id IS NULL OR object_id(on_object) = @object_id
			ORDER BY on_object

		OPEN ck_cursor

		FETCH NEXT FROM ck_cursor 
		INTO @from_object, @expression

		PRINT N''
		PRINT N''
		PRINT N'Domain integrity validation:'
		PRINT N''

		WHILE @@FETCH_STATUS=0
		BEGIN
			SET @prev_from_object = @from_object

			DECLARE 
				@sql_check_ck nvarchar(max) 

			SET @from_object_id = object_id(@from_object)
			EXEC usp_GenerateCKCheck @expression, @from_object_id, @sql_check_ck output
			EXEC sp_executesql @sql_check_ck
			SET @sql_check_fk = N''

			SET @ck_count += 1

			FETCH NEXT FROM ck_cursor 
			INTO @from_object, @expression 

			IF (object_id(@from_object)!=object_id(@prev_from_object)) OR @@FETCH_STATUS!=0
			BEGIN
				PRINT @prev_from_object
					+ N': validated '
					+ cast(@ck_count as nvarchar) 
					+ N' domain integrity rules'

				SET @ck_count = 0
			END
		END

		CLOSE ck_cursor
		DEALLOCATE ck_cursor			


		DECLARE uq_cursor CURSOR FOR 
			SELECT DISTINCT on_object, number 
			FROM dbo.UniqueIntegrity
			WHERE @object_id IS NULL OR object_id(on_object) = @object_id
			ORDER BY on_object, number 

		OPEN uq_cursor

		FETCH NEXT FROM uq_cursor 
		INTO @from_object, @number

		PRINT N''
		PRINT N''
		PRINT N'Uniqueness validation:'
		PRINT N''

		WHILE @@FETCH_STATUS=0
		BEGIN
			SET @prev_from_object = @from_object

			DECLARE 
				@sql_check_uq nvarchar(1000)

			DELETE FROM @reference_parameters
			DELETE FROM @from_clist

			INSERT @from_clist 
			SELECT column_name FROM dbo.UniqueIntegrity
			WHERE on_object=@from_object AND number=@number
			ORDER BY column_name

			SET @from_object_id = object_id(@from_object)
			EXEC dbo.usp_GenerateUQCheck @from_object_id, @from_clist, @reference_parameters, @sql_check_uq OUTPUT
			EXEC sp_executesql @sql_check_uq
			SET @sql_check_uq = N''

			SET @uq_count += 1

			FETCH NEXT FROM uq_cursor 
			INTO @from_object, @number

			IF (object_id(@from_object)!=object_id(@prev_from_object)) OR @@FETCH_STATUS!=0
			BEGIN
				PRINT @prev_from_object
					+ N': validated '
					+ cast(@uq_count as nvarchar) 
					+ N' uniqueness rules'

				SET @uq_count = 0
			END
		END

		CLOSE uq_cursor
		DEALLOCATE uq_cursor			

		

	END TRY
	BEGIN CATCH
		IF CURSOR_STATUS('local', 'fk_cursor') >= 0
		BEGIN
			CLOSE fk_cursor
			DEALLOCATE fk_cursor			
		END
		IF CURSOR_STATUS('local', 'ck_cursor') >= 0
		BEGIN
			CLOSE ck_cursor
			DEALLOCATE ck_cursor			
		END
		IF CURSOR_STATUS('local', 'uq_cursor') >= 0
		BEGIN
			CLOSE uq_cursor
			DEALLOCATE uq_cursor			
		END
		PRINT N'T-SQL executed before the error condition:'
		PRINT @sql_check_fk
		PRINT @sql_check_ck
		PRINT @sql_check_uq
		;THROW
	END CATCH
END
GO


/****************************** demonstrate integrity enforcement ******************************/

IF object_id('Sales.usp_InsertSpecialOfferProduct_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSpecialOfferProduct_inmem
go
-- validate referential integrity on insert of records in the table Sales.SpecialOfferProduct_inmem
CREATE PROCEDURE Sales.usp_InsertSpecialOfferProduct_inmem @SpecialOfferID int NOT NULL, @ProductID int NOT NULL
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
-- neads REPEATABLE READ isolation: the referenced specialoffer and product must exist at the time of the
--   insert, which is at the end of the transaction
BEGIN ATOMIC 
WITH (TRANSACTION ISOLATION LEVEL=REPEATABLE READ, LANGUAGE=N'us_english')

	DECLARE @exists bit NOT NULL = 0

	-- verify referential integrity for SpecialOfferID
	SELECT @exists=1 FROM Sales.SpecialOffer_inmem WHERE SpecialOfferID = @SpecialOfferID
	IF @exists=0
	BEGIN
		DECLARE @msg nvarchar(256) = N'Referential integrity with Sales.SpecialOffer_inmem is violated for SpecialOfferID ' + cast(@SpecialOfferID as nvarchar)
		;THROW 50001, @msg, 1
	END
	
	SET @exists=0

	-- verify referential integrity for ProductID
	SELECT @exists=1 FROM Production.Product_inmem WHERE ProductID = @ProductID
	IF @exists=0
	BEGIN
		DECLARE @msg2 nvarchar(256) = N'Referential integrity with Production.Product_inmem is violated for ProductID ' + cast(@ProductID as nvarchar)
		;THROW 50001, @msg2, 1
	END

	INSERT Sales.SpecialOfferProduct_inmem (SpecialOfferID, ProductID) VALUES (@SpecialOfferID, @ProductID)
END
GO

IF object_id('Sales.usp_InsertSpecialOffer_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSpecialOffer_inmem
go
-- validate domain integrity on insert of records in the table Sales.SpecialOffer_inmem
CREATE PROCEDURE Sales.usp_InsertSpecialOffer_inmem 
	@Description nvarchar(255) NOT NULL, 
	@DiscountPct smallmoney NOT NULL = 0,
	@Type nvarchar(50) NOT NULL,
	@Category nvarchar(50) NOT NULL,
	@StartDate datetime2 NOT NULL,
	@EndDate datetime2 NOT NULL,
	@MinQty int NOT NULL = 0,
	@MaxQty int = NULL,
	@SpecialOfferID int OUTPUT
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC 
WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'us_english')
	DECLARE @msg nvarchar(256)

	-- verify domain integrity
	-- ('Sales.SpecialOffer_inmem', '[DiscountPct]>=(0.00)'),
	IF NOT @DiscountPct >= 0
	BEGIN
		SET @msg = N'Domain integrity violation: @DiscountPct is negative'
		;THROW 50001, @msg, 1
	END
	-- ('Sales.SpecialOffer_inmem', '[EndDate]>=[StartDate]'),
	IF NOT @EndDate>=@StartDate
	BEGIN
		SET @msg = N'Domain integrity violation: @EndDate<@StartDate'
		;THROW 50001, @msg, 1
	END
	--('Sales.SpecialOffer_inmem', '[MaxQty]>=(0)'),
	IF NOT @MaxQty>=(0)
	BEGIN
		SET @msg = N'Domain integrity violation: @MaxQty<0'
		;THROW 50001, @msg, 1
	END
	-- ('Sales.SpecialOffer_inmem', '[MinQty]>=(0)')	
	IF NOT @MinQty>=(0)
	BEGIN
		SET @msg = N'Domain integrity violation: @MinQty<0'
		;THROW 50001, @msg, 1
	END
	

	INSERT Sales.SpecialOffer_inmem (Description, 
		DiscountPct,
		Type,
		Category,
		StartDate,
		EndDate,
		MinQty,
		MaxQty) 
	VALUES (@Description, 
		@DiscountPct,
		@Type,
		@Category,
		@StartDate,
		@EndDate,
		@MinQty,
		@MaxQty)

	SET @SpecialOfferID = SCOPE_IDENTITY()
END
GO


IF object_id('Sales.usp_DeleteSpecialOffer_inmem') IS NOT NULL
	DROP PROCEDURE Sales.usp_DeleteSpecialOffer_inmem
go
-- validate referential integrity on delete of records in the table Sales.SpecialOffer_inmem
CREATE PROCEDURE Sales.usp_DeleteSpecialOffer_inmem 
	@SpecialOfferID int NOT NULL
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
-- needs SERIALIZABLE isolation: cannot allow insert of new rows in specialoffer product between the integrity check
--   and the end of the transaction
BEGIN ATOMIC 
WITH (TRANSACTION ISOLATION LEVEL=SERIALIZABLE, LANGUAGE=N'us_english')
	DECLARE @exists bit NOT NULL = 0

	-- verify referential integrity for SpecialOfferID
	SELECT @exists=1 FROM Sales.SpecialOfferProduct_inmem WHERE SpecialOfferID = @SpecialOfferID
	IF @exists=1
	BEGIN
		DECLARE @msg nvarchar(256) = N'Referential integrity with Sales.SpecialOfferProduct_inmem is violated for SpecialOfferID ' + cast(@SpecialOfferID as nvarchar)
		;THROW 50001, @msg, 1
	END

	DELETE FROM Sales.SpecialOffer_inmem WHERE SpecialOfferID=@SpecialOfferID

	IF @@rowcount < 1
	BEGIN
		DECLARE @msg2 nvarchar(256) = N'Record not found for SpecialOfferID ' + cast(@SpecialOfferID as nvarchar)
		;THROW 50001, @msg2, 1
	END
END
GO


IF object_id('Production.usp_InsertProduct_inmem') IS NOT NULL
	DROP PROCEDURE Production.usp_InsertProduct_inmem
go
-- validate domain integrity and uniqueness on insert of records in the table Production.Product_inmem
CREATE PROCEDURE Production.usp_InsertProduct_inmem 
	@Name [nvarchar](50) NOT NULL,
	@ProductNumber [nvarchar](25) NOT NULL,
	@MakeFlag [bit] NOT NULL = 1,
	@FinishedGoodsFlag [bit] NOT NULL = 1,
	@Color [nvarchar](15) = NULL,
	@SafetyStockLevel [smallint] NOT NULL,
	@ReorderPoint [smallint] NOT NULL,
	@StandardCost [money] NOT NULL,
	@ListPrice [money] NOT NULL,
	@Size [nvarchar](5) = NULL,
	@SizeUnitMeasureCode [nchar](3) = NULL,
	@WeightUnitMeasureCode [nchar](3) = NULL,
	@Weight [decimal](8, 2) = NULL,
	@DaysToManufacture [int] NOT NULL,
	@ProductLine [nchar](2) = NULL,
	@Class [nchar](2) = NULL,
	@Style [nchar](2) = NULL,
	@ProductSubcategoryID [int] = NULL,
	@ProductModelID [int] = NULL,
	@SellStartDate [datetime2](7) NOT NULL,
	@SellEndDate [datetime2](7) = NULL,
	@DiscontinuedDate [datetime2](7) = NULL,
	@ProductID int OUTPUT
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
-- needs SERIALIZABLE isolation for the uniqueness checks: cannot allow insert of rows violating uniqueness between
--   the uniqueness check and the end of the transaction
BEGIN ATOMIC 
WITH (TRANSACTION ISOLATION LEVEL=SERIALIZABLE, LANGUAGE=N'us_english')
	DECLARE @msg nvarchar(256)

	-- verify domain integrity
	-- (upper([Class])='H' OR upper([Class])='M' OR upper([Class])='L' OR [Class] IS NULL)
	IF NOT (@Class COLLATE Latin1_General_100_BIN2 = 'H' 
			OR @Class COLLATE Latin1_General_100_BIN2 = 'M'
			OR @Class COLLATE Latin1_General_100_BIN2 = 'L'
			OR @Class COLLATE Latin1_General_100_BIN2 IS NULL)
	BEGIN
		SET @msg = N'Domain integrity violation: @Class must be H, M, L, or NULL'
		;THROW 50001, @msg, 1
	END
	-- [DaysToManufacture]>=(0)
	IF NOT @DaysToManufacture>=(0)
	BEGIN
		SET @msg = N'Domain integrity violation: [DaysToManufacture]<(0)'
		;THROW 50001, @msg, 1
	END
	--[ListPrice]>=(0.00)
	IF NOT @ListPrice>=(0.00)
	BEGIN
		SET @msg = N'Domain integrity violation: [ListPrice]<(0.00)'
		;THROW 50001, @msg, 1
	END
	-- (([ProductLine])='R' OR ([ProductLine])='M' OR ([ProductLine])='T' OR ([ProductLine])='S' OR [ProductLine] IS NULL)	
	IF NOT ((@ProductLine) COLLATE Latin1_General_100_BIN2 = 'R'
			OR (@ProductLine) COLLATE Latin1_General_100_BIN2 = 'M'
			OR (@ProductLine) COLLATE Latin1_General_100_BIN2 = 'T'
			OR (@ProductLine) COLLATE Latin1_General_100_BIN2 = 'S'
			OR @ProductLine COLLATE Latin1_General_100_BIN2 IS NULL)
	BEGIN
		SET @msg = N'Domain integrity violation: ProductLine must be R, M, T, S, or NULL'
		;THROW 50001, @msg, 1
	END
	--[ReorderPoint]>(0)
	IF NOT @ReorderPoint>(0)
	BEGIN
		SET @msg = N'Domain integrity violation: [ReorderPoint]<=(0)'
		;THROW 50001, @msg, 1
	END
	--[SafetyStockLevel]>(0)
	IF NOT @SafetyStockLevel>(0)
	BEGIN
		SET @msg = N'Domain integrity violation: [SafetyStockLevel]<=(0)'
		;THROW 50001, @msg, 1
	END	
	--[SellEndDate]>=[SellStartDate] OR [SellEndDate] IS NULL
	IF NOT (@SellEndDate>=@SellStartDate OR @SellEndDate IS NULL)
	BEGIN
		SET @msg = N'Domain integrity violation: [SellEndDate]<[SellStartDate] AND [SellEndDate] IS NOT NULL'
		;THROW 50001, @msg, 1
	END	
	--[StandardCost]>=(0.00)
	IF NOT @StandardCost>=(0.00)
	BEGIN
		SET @msg = N'Domain integrity violation: [StandardCost]<(0.00)'
		;THROW 50001, @msg, 1
	END	
	--[Weight]>(0.00)
	IF NOT @Weight>(0.00)
	BEGIN
		SET @msg = N'Domain integrity violation: [Weight]<=(0)'
		;THROW 50001, @msg, 1
	END	
	--upper([Style])='U' OR upper([Style])='M' OR upper([Style])='W' OR [Style] IS NULL
	IF NOT ((@Style) COLLATE Latin1_General_100_BIN2 = 'U' 
			OR (@Style) COLLATE Latin1_General_100_BIN2 = 'M' 
			OR (@Style) COLLATE Latin1_General_100_BIN2 = 'W' 
			OR @Style COLLATE Latin1_General_100_BIN2 IS NULL)
	BEGIN
		SET @msg = N'Domain integrity violation: Style must be U, M, W or NULL'
		;THROW 50001, @msg, 1
	END
	-- Verify uniqueness of Name
	DECLARE @exists bit NOT NULL = 0
	SELECT @exists=1 FROM Production.Product_inmem WHERE Name=@Name COLLATE Latin1_General_100_BIN2
	IF @exists=1
	BEGIN
		SET @msg = N'Uniqueness violation for @Name ' + @Name
		;THROW 50001, @msg, 1
	END

	-- Verify uniqueness of ProductNumber
	SET @exists = 0
	SELECT @exists=1 FROM Production.Product_inmem WHERE ProductNumber=@ProductNumber COLLATE Latin1_General_100_BIN2
	IF @exists=1
	BEGIN
		SET @msg = N'Uniqueness violation for @ProductNumber ' + @ProductNumber
		;THROW 50001, @msg, 1
	END

	INSERT Production.Product_inmem (
		Name ,
		ProductNumber,
		MakeFlag ,
		FinishedGoodsFlag,
		Color ,
		SafetyStockLevel ,
		ReorderPoint ,
		StandardCost ,
		ListPrice ,
		Size ,
		SizeUnitMeasureCode ,
		WeightUnitMeasureCode ,
		Weight ,
		DaysToManufacture ,
		ProductLine ,
		Class ,
		Style ,
		ProductSubcategoryID ,
		ProductModelID ,
		SellStartDate ,
		SellEndDate ,
		DiscontinuedDate ) 
	VALUES (
		@Name ,
		@ProductNumber,
		@MakeFlag ,
		@FinishedGoodsFlag,
		@Color ,
		@SafetyStockLevel ,
		@ReorderPoint ,
		@StandardCost ,
		@ListPrice ,
		@Size ,
		@SizeUnitMeasureCode ,
		@WeightUnitMeasureCode ,
		@Weight ,
		@DaysToManufacture ,
		@ProductLine ,
		@Class ,
		@Style ,
		@ProductSubcategoryID ,
		@ProductModelID ,
		@SellStartDate ,
		@SellEndDate ,
		@DiscontinuedDate ) 

	SET @ProductID = SCOPE_IDENTITY()
END
GO


IF object_id('Production.usp_DeleteProduct_inmem') IS NOT NULL
	DROP PROCEDURE Production.usp_DeleteProduct_inmem
go
-- validate referential integrity on delete of records in the table Sales.SpecialOffer_inmem
CREATE PROCEDURE Production.usp_DeleteProduct_inmem
	@ProductID int NOT NULL
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
-- needs SERIALIZABLE isolation: cannot allow insert of new rows in specialofferproduct between the integrity check
--   and the end of the transaction
BEGIN ATOMIC 
WITH (TRANSACTION ISOLATION LEVEL=SERIALIZABLE, LANGUAGE=N'us_english')
	DECLARE @exists bit NOT NULL = 0

	-- verify referential integrity for ProductID
	SELECT @exists=1 FROM Sales.SpecialOfferProduct_inmem WHERE ProductID = @ProductID
	IF @exists=1
	BEGIN
		DECLARE @msg nvarchar(256) = N'Referential integrity with Sales.SpecialOfferProduct_inmem is violated for ProductID ' + cast(@ProductID as nvarchar)
		;THROW 50001, @msg, 1
	END

	DELETE FROM Production.Product_inmem WHERE ProductID=@ProductID

	IF @@rowcount < 1
	BEGIN
		DECLARE @msg2 nvarchar(256) = N'Record not found for ProductID ' + cast(@ProductID as nvarchar)
		;THROW 50001, @msg2, 1
	END
END
GO


-- perform integrity validation for migrated data:
EXEC dbo.usp_ValidateIntegrity
GO


