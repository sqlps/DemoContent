Use AdventureWorksDW
GO

--Prerequisite. You need to download the AdventureWorks2012DW from codeplex

CREATE PARTITION FUNCTION [ByOrderDateMonthPF](int) AS RANGE RIGHT 
FOR VALUES (
	20010701, 20010801, 20010901, 20011001, 20011101, 20011201,
    20020701, 20020801, 20020901, 20021001, 20021101, 20021201, 
    20030101, 20030201, 20030301, 20030401, 20030501, 20030601, 
    20030701, 20030801, 20030901, 20031001, 20031101, 20031201, 
    20040101, 20040201, 20040301, 20040401, 20040501, 20040601, 
    20040701
) 
GO

CREATE PARTITION SCHEME [ByOrderDateMonthRange] 
AS PARTITION [ByOrderDateMonthPF] 
ALL TO ([PRIMARY]) 
GO

-- Create copy of the partitioned table that has 4 M rows
-- Takes about 2 min on my desktop (8 GB memory) with other programs running
IF OBJECT_ID('dbo.FactResellerSalesPart') IS NOT NULL
 DROP TABLE dbo.FactResellerSalesPart;
IF OBJECT_ID('dbo.FactResellerSalesPartNonAligned') IS NOT NULL
 DROP TABLE dbo.FactResellerSalesPartNonAligned;

go

CREATE TABLE [dbo].[FactResellerSalesPart](
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[ResellerKey] [int] NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[SalesTerritoryKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[ExtendedAmount] [money] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [money] NULL,
	[TotalProductCost] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[Freight] [money] NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[CustomerPONumber] [nvarchar](25) NULL
) ON ByOrderDateMonthRange(OrderDateKey)

GO

INSERT INTO FactResellerSalesPart
	/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [ProductKey]
	  ,[OrderDateKey]
	  ,[DueDateKey]
	  ,[ShipDateKey]
	  ,[ResellerKey]
	  ,[EmployeeKey]
	  ,[PromotionKey]
	  ,[CurrencyKey]
	  ,[SalesTerritoryKey]
	  ,[SalesOrderNumber]
	  ,[SalesOrderLineNumber]
	  ,[RevisionNumber]
	  ,[OrderQuantity]
	  ,[UnitPrice]
	  ,[ExtendedAmount]
	  ,[UnitPriceDiscountPct]
	  ,[DiscountAmount]
	  ,[ProductStandardCost]
	  ,[TotalProductCost]
	  ,[SalesAmount]
	  ,[TaxAmt]
	  ,[Freight]
	  ,[CarrierTrackingNumber]
	  ,[CustomerPONumber]
	  FROM [dbo].[FactResellerSales]
  GO

CREATE TABLE [dbo].[FactResellerSalesPartNonAligned](
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[ResellerKey] [int] NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[SalesTerritoryKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[ExtendedAmount] [money] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [money] NULL,
	[TotalProductCost] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[Freight] [money] NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[CustomerPONumber] [nvarchar](25) NULL
) ON ByOrderDateMonthRange(OrderDateKey)

GO

INSERT INTO FactResellerSalesPartNonAligned
	/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [ProductKey]
	  ,[OrderDateKey]
	  ,[DueDateKey]
	  ,[ShipDateKey]
	  ,[ResellerKey]
	  ,[EmployeeKey]
	  ,[PromotionKey]
	  ,[CurrencyKey]
	  ,[SalesTerritoryKey]
	  ,[SalesOrderNumber]
	  ,[SalesOrderLineNumber]
	  ,[RevisionNumber]
	  ,[OrderQuantity]
	  ,[UnitPrice]
	  ,[ExtendedAmount]
	  ,[UnitPriceDiscountPct]
	  ,[DiscountAmount]
	  ,[ProductStandardCost]
	  ,[TotalProductCost]
	  ,[SalesAmount]
	  ,[TaxAmt]
	  ,[Freight]
	  ,[CarrierTrackingNumber]
	  ,[CustomerPONumber]
	  FROM [dbo].[FactResellerSales]
  GO


/****** Object:  Index [CI_FactReseller]    Script Date: 10/23/2011 8:47:02 PM ******/
CREATE CLUSTERED INDEX [CI_FactResellerPart] ON [dbo].[FactResellerSalesPart]
(
	[OrderDateKey] ASC
) ON ByOrderDateMonthRange(OrderDateKey) --This line makes it partitioned aligned
GO
CREATE CLUSTERED INDEX [CI_FactResellerPartNonAligned] ON [dbo].[FactResellerSalesPartNonAligned]
(
	[OrderDateKey] ASC
) --ON ByOrderDateMonthRange(OrderDateKey) --This line makes it partitioned aligned
GO



--Partioned table.
select * from sys.partitions where object_id= OBJECT_ID('FactResellerSalesPart')
GO

--What if I already have a table in production???
DROP Table FactResellerSalesPart
GO
CREATE TABLE [dbo].[FactResellerSalesPart](
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[ResellerKey] [int] NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[SalesTerritoryKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[ExtendedAmount] [money] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [money] NULL,
	[TotalProductCost] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[Freight] [money] NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[CustomerPONumber] [nvarchar](25) NULL
)-- ON ByOrderDateMonthRange(OrderDateKey)

GO

INSERT INTO FactResellerSalesPart
	/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [ProductKey]
	  ,[OrderDateKey]
	  ,[DueDateKey]
	  ,[ShipDateKey]
	  ,[ResellerKey]
	  ,[EmployeeKey]
	  ,[PromotionKey]
	  ,[CurrencyKey]
	  ,[SalesTerritoryKey]
	  ,[SalesOrderNumber]
	  ,[SalesOrderLineNumber]
	  ,[RevisionNumber]
	  ,[OrderQuantity]
	  ,[UnitPrice]
	  ,[ExtendedAmount]
	  ,[UnitPriceDiscountPct]
	  ,[DiscountAmount]
	  ,[ProductStandardCost]
	  ,[TotalProductCost]
	  ,[SalesAmount]
	  ,[TaxAmt]
	  ,[Freight]
	  ,[CarrierTrackingNumber]
	  ,[CustomerPONumber]
	  FROM [dbo].[FactResellerSales]
  GO

-- Now all my rows are in one partition
select * from sys.partitions where object_id= OBJECT_ID('FactResellerSalesPart')
GO

--Create a partitioned index :)

CREATE CLUSTERED INDEX [CI_FactResellerPart] ON [dbo].[FactResellerSalesPart]
(
	[OrderDateKey] ASC
) ON ByOrderDateMonthRange(OrderDateKey) --This line makes it partitioned aligned
GO

-- And now we have data distributed by partition
select * from sys.partitions where object_id= OBJECT_ID('FactResellerSalesPart')
GO
