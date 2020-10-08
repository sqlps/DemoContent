USE [Adventureworks2016CTP3]
GO

Select * into Sales.SalesOrderDetail_ondisk_historical from Sales.SalesOrderDetail_ondisk
GO
Select * into Sales.SalesOrderHeader_ondisk_historical from Sales.SalesOrderHeader_ondisk
GO


USE [Adventureworks2016CTP3]
GO

/****** Object:  Index [ODPK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID]    Script Date: 5/5/2016 2:49:33 PM ******/
ALTER TABLE [Sales].[SalesOrderDetail_ondisk_historical] ADD  CONSTRAINT [ODPK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID_historical] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC,
	[SalesOrderDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

USE [Adventureworks2016CTP3]
GO

/****** Object:  Index [IX_ProductID]    Script Date: 5/5/2016 2:50:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_ProductID_Historical] ON [Sales].[SalesOrderDetail_ondisk_historical]
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

USE [AdventureWorks2016CTP3]
GO

/****** Object:  Index [PK__SalesOrd__B14003C2B181FB70]    Script Date: 5/5/2016 2:59:26 PM ******/
ALTER TABLE [Sales].[SalesOrderHeader_ondisk_Historical] ADD PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

USE [AdventureWorks2016CTP3]
GO

/****** Object:  Index [IX_CustomerID]    Script Date: 5/5/2016 2:59:54 PM ******/
CREATE NONCLUSTERED INDEX [IX_CustomerID_Historical] ON [Sales].[SalesOrderHeader_ondisk_Historical]
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
USE [AdventureWorks2016CTP3]
GO

/****** Object:  Index [IX_SalesPersonID]    Script Date: 5/5/2016 3:00:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_SalesPersonID_Historical] ON [Sales].[SalesOrderHeader_ondisk_Historical]
(
	[SalesPersonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO






USE [Adventureworks2016CTP3]
GO
/****** Object:  StoredProcedure [Sales].[usp_InsertSalesOrder_ondisk]    Script Date: 5/5/2016 2:44:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Sales].[usp_InsertSalesOrder_ondisk_Historical]
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

		SELECT @SubTotal = ISNULL(SUM(p.ListPrice * (1 - ISNULL(so.DiscountPct, 0))),0)
		FROM @SalesOrderDetails od 
			JOIN Production.Product_ondisk p on od.ProductID=p.ProductID
			LEFT JOIN Sales.SpecialOffer_ondisk so on od.SpecialOfferID=so.SpecialOfferID

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

		INSERT INTO Sales.SalesOrderDetail_ondisk_Historical
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
			JOIN Production.Product_ondisk p on od.ProductID=p.ProductID
			LEFT JOIN Sales.SpecialOffer_ondisk so on od.SpecialOfferID=so.SpecialOfferID

	COMMIT
END
