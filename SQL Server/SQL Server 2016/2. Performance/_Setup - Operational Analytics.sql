
-- ===================================================================================================================================================
-- Step 1) Create a sales.SalesOrderDetail_inmem2 table and pump the data over
-- ===================================================================================================================================================
-- 2. Create a sales.SalesOrderDetail_inmem2 table and pump the data over
/****** Object:  Table [Sales].[SalesOrderDetail_inmem2]    Script Date: 1/25/2016 10:52:57 PM ******/
Use Adventureworks2016CTP3
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE sales.usp_InsertSalesOrder_inmem2
--DROP TABLE [Sales].[SalesOrderDetail_inmem2]
CREATE TABLE [Sales].[SalesOrderDetail_inmem2]
(
	[SalesOrderID] [int] NOT NULL,
	[SalesOrderDetailID] [bigint] IDENTITY(1,1) NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[ModifiedDate] [datetime2](7) NOT NULL,

/****** Object:  Index [cci_SalesOrderDetail_inmem2]    Script Date: 1/25/2016 10:52:57 PM ******/
INDEX [cci_SalesOrderDetail_inmem2] CLUSTERED COLUMNSTORE WITH (COMPRESSION_DELAY = 60),
--The valid range for disk-based table is between (0, 10080) minutes and for memory-optimized table is 0 or between (60, 10080) minutes.
-- = 168hrs == 7 Days
INDEX NCI_ModifiedDate NONCLUSTERED (ModifiedDate),
 CONSTRAINT [imPK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID2]  PRIMARY KEY NONCLUSTERED HASH 
(
	[SalesOrderID],
	[SalesOrderDetailID]
)WITH ( BUCKET_COUNT = 67108864),
INDEX [IX_ProductID] NONCLUSTERED HASH 
(
	[ProductID]
)WITH ( BUCKET_COUNT = 1048576),
INDEX [IX_SalesOrderID] NONCLUSTERED HASH 
(
	[SalesOrderID]
)WITH ( BUCKET_COUNT = 16777216)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )

GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2]  WITH NOCHECK ADD  CONSTRAINT [IMFK_SalesOrderDetail_SalesOrderHeader_SalesOrderID2] FOREIGN KEY([SalesOrderID])
REFERENCES [Sales].[SalesOrderHeader_inmem] ([SalesOrderID])
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2] CHECK CONSTRAINT [IMFK_SalesOrderDetail_SalesOrderHeader_SalesOrderID2]
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2]  WITH NOCHECK ADD  CONSTRAINT [IMFK_SalesOrderDetail_SpecialOfferProduct_SpecialOfferIDProductID2] FOREIGN KEY([SpecialOfferID], [ProductID])
REFERENCES [Sales].[SpecialOfferProduct_inmem] ([SpecialOfferID], [ProductID])
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2] CHECK CONSTRAINT [IMFK_SalesOrderDetail_SpecialOfferProduct_SpecialOfferIDProductID2]
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2]  WITH NOCHECK ADD  CONSTRAINT [IMCK_SalesOrderDetail_OrderQty2] CHECK  (([OrderQty]>(0)))
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2] CHECK CONSTRAINT [IMCK_SalesOrderDetail_OrderQty2]
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2]  WITH NOCHECK ADD  CONSTRAINT [IMCK_SalesOrderDetail_UnitPrice2] CHECK  (([UnitPrice]>=(0.00)))
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2] CHECK CONSTRAINT [IMCK_SalesOrderDetail_UnitPrice2]
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2]  WITH NOCHECK ADD  CONSTRAINT [IMCK_SalesOrderDetail_UnitPriceDiscount2] CHECK  (([UnitPriceDiscount]>=(0.00)))
GO

ALTER TABLE [Sales].[SalesOrderDetail_inmem2] CHECK CONSTRAINT [IMCK_SalesOrderDetail_UnitPriceDiscount2]
GO

-- ===================================================================================================================================================
-- Step 2) Mod the proc
-- ===================================================================================================================================================
USE [AdventureWorks2016CTP3]
GO

/****** Object:  StoredProcedure [Sales].[usp_InsertSalesOrder_inmem2]    Script Date: 1/25/2016 10:54:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Sales].[usp_InsertSalesOrder_inmem2]
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
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH
  (TRANSACTION ISOLATION LEVEL = SNAPSHOT,
   LANGUAGE = N'us_english')

	DECLARE @OrderDate datetime2 NOT NULL = SYSDATETIME()

	DECLARE @SubTotal money NOT NULL = 0

	SELECT @SubTotal = ISNULL(SUM(p.ListPrice * (1 - ISNULL(so.DiscountPct, 0))),0)
	FROM @SalesOrderDetails od 
		JOIN Production.Product_inmem p on od.ProductID=p.ProductID
		LEFT JOIN Sales.SpecialOffer_inmem so on od.SpecialOfferID=so.SpecialOfferID

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

	INSERT INTO Sales.SalesOrderDetail_inmem2
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
		ISNULL(p.ListPrice * so.DiscountPct, 0),
		@OrderDate
	FROM @SalesOrderDetails od 
		JOIN Production.Product_inmem p on od.ProductID=p.ProductID
		LEFT JOIN Sales.SpecialOffer_inmem so on od.SpecialOfferID=so.SpecialOfferID

END
GO

-- ===================================================================================================================================================
-- Step 3) Mod the files on disk C:\Demos\SQLServer2016CTP3Samples\In-Memory OLTP and copy data into inmem_2
-- ===================================================================================================================================================
	SET Identity_Insert Sales.SalesOrderDetail_inmem2 ON
	INSERT INTO Sales.SalesOrderDetail_inmem2
	(
		SalesOrderID,SAlesOrderDetailID,CarrierTrackingNumber,OrderQty,ProductID,SpecialOfferID,UnitPrice,
		UnitPriceDiscount,ModifiedDate
	)
	Select * from Sales.SalesOrderDetail_inmem
	SET Identity_Insert Sales.SalesOrderDetail_inmem2 OFF
-- ==================================================================================================================================================
-- Step 4) Update ModifiedDate in [Sales].[SalesOrderDetail_ondisk]
-- ===================================================================================================================================================
Update Sales.SalesOrderDetail_ondisk 
Set ModifiedDate = '2014-01-11 00:00:00.0000000'
-- ===================================================================================================================================================
-- Step 5) Create the NCCI on [Sales].[SalesOrderDetail_ondisk]
-- ===================================================================================================================================================

CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCI_SalesOrderDetail_ondisk] ON [Sales].[SalesOrderDetail_ondisk]
(
	[ModifiedDate],
	[SalesOrderID],
	[SalesOrderDetailID],
	[CarrierTrackingNumber],
	[OrderQty],
	[ProductID],
	[SpecialOfferID],
	[UnitPrice],
	[UnitPriceDiscount]
)Where ModifiedDate < '2016-01-01' WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 5 )

GO

