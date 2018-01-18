-- ================================================
-- Step 1) Setup
-- ================================================
/*
USE [master]
RESTORE DATABASE [AdventureWorks2016DW] FROM  DISK = N'D:\Backup\Adventureworks2016DW.bak' WITH  FILE = 1,  MOVE N'AdventureWorksDW2008_Data' TO N'D:\Data\AdventureWorksDW2008BigOrig.mdf',  MOVE N'AdventureWorksDW2008_Log' TO N'D:\Log\AdventureWorksDW2008BigOrig.ldf',  NOUNLOAD,  STATS = 5
*/
GO



ALTER DATABASE AdventureWorks2016DW ADD FILEGROUP AdventureWorks2016DW_XTP CONTAINS MEMORY_OPTIMIZED_DATA
ALTER DATABASE AdventureWorks2016DW ADD FILE( NAME = 'AdventureWorks2016DW_XTP' , FILENAME = 'D:\Data\AdventureWorks2016DW_XTP') TO FILEGROUP AdventureWorks2016DW_XTP;

USE [AdventureWorks2016DW]
GO
--Drop Table [FactSales_InMem]
CREATE TABLE [dbo].[FactSales_InMem](
	[pk_FactSales] [int] Identity(1,1) PRIMARY  KEY --4bytes
    NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000000),
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
	[CustomerPONumber] [nvarchar](25) NULL,
	INDEX FactSales_InMem_cci CLUSTERED COLUMNSTORE
) WITH (MEMORY_OPTIMIZED = ON)
GO

CREATE TABLE [dbo].[FactSales_staging](
	[pk_FactSales] [int] Identity(1,1) PRIMARY  KEY --4bytes
    NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000),
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
) WITH (MEMORY_OPTIMIZED = ON)
GO

Insert [FactSales_staging]
select top 100000 * from FactResellerSalesCacheBig

GO

CREATE PROCEDURE dbo.Insert100K_Rows_in_FactSales_InMem
  WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS Owner
AS 
BEGIN ATOMIC WITH 
(	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'us_english')

Insert dbo.[FactSales_InMem] 
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
  FROM [dbo].[FactSales_staging]
end

exec Insert100K_Rows_in_FactSales_InMem 
GO 30

Declare @ObjectId int
Select @ObjectId = object_id('FactSales_InMem')
Exec sys.sp_memory_optimized_cs_migration @ObjectId


Select * Into FactSalesXL From FactSales_InMem

GO

-- Added on 10/12/2016
CREATE TABLE OrderQty(Total bigint) 
GO

CREATE Procedure dbo.usp_BikeTotals
  AS
 BEGIN
 Declare @PriorTotal bigint,
			@Total bigint
	
	Select @PriorTotal = Total from OrderQty
	Select @Total = SUM(OrderQuantity)
	FROM FactSales_InMem f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
	where OrderDateKey = 20040708

	If (@PriorTotal is NULL)
		Insert OrderQty VALUES (@Total)
	Else 
	BEGIN
		Update OrderQty
		Set Total = @Total
	END

	Select @Total as 'OrderQty', (@Total - @PriorTotal) as 'PriorQty'
END



