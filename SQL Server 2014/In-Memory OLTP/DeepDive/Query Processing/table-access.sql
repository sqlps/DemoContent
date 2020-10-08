-- ================================ Start of table access demo

-- sample database: [http://msdn.microsoft.com/en-us/library/dn511655.aspx]

-- reset workload
USE AdventureWorks2012
GO
SET NOCOUNT ON
GO
EXEC Demo.usp_DemoReset
GO


-- insert sales order in disk-based tables
IF object_id('Sales.usp_InsertSalesOrder_ondisk') IS NOT NULL
	DROP PROCEDURE Sales.[usp_InsertSalesOrder_ondisk] 
GO
CREATE PROCEDURE [Sales].[usp_InsertSalesOrder_ondisk]
	@SalesOrderID int OUTPUT,
	@DueDate [datetime2](7) ,
	@CustomerID [int] ,
	@BillToAddressID [int] ,
	@ShipToAddressID [int] ,
	@ShipMethodID [int] ,
	@SalesOrderDetails Sales.SalesOrderDetailType_inmem READONLY,
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
		(	DueDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, Comment, OrderDate, SubTotal, ModifiedDate)
		VALUES
		(	@DueDate, @Status, @OnlineOrderFlag, @PurchaseOrderNumber, @AccountNumber, @CustomerID, @SalesPersonID, @TerritoryID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @CreditCardID, @CreditCardApprovalCode, @CurrencyRateID, @Comment, @OrderDate, @SubTotal, @OrderDate )

		SET @SalesOrderID = SCOPE_IDENTITY()

		INSERT INTO Sales.SalesOrderDetail_ondisk
		(
			SalesOrderID, OrderQty, ProductID, SpecialOfferID,
			UnitPrice,
			UnitPriceDiscount,
			ModifiedDate
		)
		SELECT 
			@SalesOrderID, od.OrderQty, od.ProductID, od.SpecialOfferID,
			p.ListPrice,
			p.ListPrice * so.DiscountPct,
			@OrderDate
		FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_ondisk so on od.SpecialOfferID=so.SpecialOfferID
			JOIN Production.Product_ondisk p on od.ProductID=p.ProductID
	COMMIT
END
GO

IF object_id('Sales.usp_InsertSalesOrder_interop') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSalesOrder_interop 
GO
CREATE PROCEDURE [Sales].usp_InsertSalesOrder_interop
	@SalesOrderID int OUTPUT,
	@DueDate [datetime2](7),
	@CustomerID [int] ,
	@BillToAddressID [int] ,
	@ShipToAddressID [int] ,
	@ShipMethodID [int] ,
	@SalesOrderDetails Sales.SalesOrderDetailType_inmem READONLY,
	@Status [tinyint] = 1,
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
		FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_inmem so on od.SpecialOfferID=so.SpecialOfferID
			JOIN Production.Product_inmem p on od.ProductID=p.ProductID

		INSERT INTO Sales.SalesOrderHeader_inmem
		(	DueDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, Comment, OrderDate, SubTotal, ModifiedDate)
		VALUES
		(	@DueDate, @Status, @OnlineOrderFlag, @PurchaseOrderNumber, @AccountNumber, @CustomerID, @SalesPersonID, @TerritoryID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @CreditCardID, @CreditCardApprovalCode, @CurrencyRateID, @Comment, @OrderDate, @SubTotal, @OrderDate )

		SET @SalesOrderID = SCOPE_IDENTITY()

		INSERT INTO Sales.SalesOrderDetail_inmem
		(
			SalesOrderID, OrderQty, ProductID, SpecialOfferID,
			UnitPrice,
			UnitPriceDiscount,
			ModifiedDate
		)
		SELECT 
			@SalesOrderID, od.OrderQty, od.ProductID, od.SpecialOfferID,
			p.ListPrice,
			p.ListPrice * so.DiscountPct,
			@OrderDate
		FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_inmem so on od.SpecialOfferID=so.SpecialOfferID
			JOIN Production.Product_inmem p on od.ProductID=p.ProductID
	COMMIT
END
GO

-- native procedure create [recreate to reset stats]
IF object_id('Sales.usp_InsertSalesOrder_native') IS NOT NULL
	DROP PROCEDURE Sales.usp_InsertSalesOrder_native 
GO
CREATE PROCEDURE [Sales].usp_InsertSalesOrder_native
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

	DECLARE @OrderDate datetime2 = sysdatetime()

	DECLARE @SubTotal money = 0

	SELECT @SubTotal = ISNULL(SUM(p.ListPrice * (1 - so.DiscountPct)),0)
	FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_inmem so on od.SpecialOfferID=so.SpecialOfferID
		JOIN Production.Product_inmem p on od.ProductID=p.ProductID

	INSERT INTO Sales.SalesOrderHeader_inmem
	(	DueDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, Comment, OrderDate, SubTotal, ModifiedDate)
	VALUES
	(	@DueDate, @Status, @OnlineOrderFlag, @PurchaseOrderNumber, @AccountNumber, @CustomerID, @SalesPersonID, @TerritoryID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @CreditCardID, @CreditCardApprovalCode, @CurrencyRateID, @Comment, @OrderDate, @SubTotal, @OrderDate )

    SET @SalesOrderID = SCOPE_IDENTITY()

	INSERT INTO Sales.SalesOrderDetail_inmem
	(
		SalesOrderID, OrderQty, ProductID, SpecialOfferID,
		UnitPrice,
		UnitPriceDiscount,
		ModifiedDate
	)
	SELECT 
		@SalesOrderID, od.OrderQty, od.ProductID, od.SpecialOfferID,
		p.ListPrice,
		p.ListPrice * so.DiscountPct,
		@OrderDate
	FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_inmem so on od.SpecialOfferID=so.SpecialOfferID
		JOIN Production.Product_inmem p on od.ProductID=p.ProductID

END
GO

-- enable stats collection for natively compiled procs
exec sp_xtp_control_proc_exec_stats 1
go
dbcc freeproccache
go

-- run insert sales orders workload
SET NOCOUNT ON
GO
declare @start datetime2
set @start = SYSDATETIME()

DECLARE 
	@i int = 0, 
	@od Sales.SalesOrderDetailType_inmem, 
	@SalesOrderID int, 
	@DueDate datetime2 = sysdatetime(), 
	@CustomerID int = rand() * 8000, 
	@BillToAddressID int = rand() * 10000, 
	@ShipToAddressID int = rand() * 10000, 
	@ShipMethodID int = (rand() * 5) + 1; 

INSERT INTO @od 
SELECT OrderQty, ProductID, SpecialOfferID 
FROM Demo.DemoSalesOrderDetailSeed 
WHERE OrderID= cast((rand()*106) + 1 as int); 

WHILE (@i < 20000) 
BEGIN; 
	EXEC Sales.usp_InsertSalesOrder_ondisk @SalesOrderID OUTPUT, @DueDate, @CustomerID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @od; 
	SET @i += 1 
END
select cast(total_worker_time as decimal)/1000/1000 as 'disk-based: total worker time (s)' from sys.dm_exec_procedure_stats
where object_id=object_id('Sales.usp_InsertSalesOrder_ondisk')

set @i = 0
WHILE (@i < 20000) 
BEGIN; 
	EXEC Sales.usp_InsertSalesOrder_interop @SalesOrderID OUTPUT, @DueDate, @CustomerID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @od; 
	SET @i += 1 
END
select cast(total_worker_time as decimal)/1000/1000 as 'interop: total worker time (s)' from sys.dm_exec_procedure_stats
where object_id=object_id('Sales.usp_InsertSalesOrder_interop')

set @i = 0
WHILE (@i < 20000) 
BEGIN; 
	EXEC Sales.usp_InsertSalesOrder_native @SalesOrderID OUTPUT, @DueDate, @CustomerID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @od; 
	SET @i += 1 
END
select cast(total_worker_time as decimal)/1000/1000 as 'native: total worker time (s)' from sys.dm_exec_procedure_stats
where object_id=object_id('Sales.usp_InsertSalesOrder_native')
GO

-- reset workload
USE AdventureWorks2012
GO
SET NOCOUNT ON
GO
EXEC Demo.usp_DemoReset
GO
drop proc Sales.usp_InsertSalesOrder_interop
drop proc Sales.usp_InsertSalesOrder_native
go

-- insert sales order in disk-based tables
IF object_id('Sales.usp_InsertSalesOrder_ondisk') IS NOT NULL
	DROP PROCEDURE Sales.[usp_InsertSalesOrder_ondisk] 
GO
CREATE PROCEDURE [Sales].[usp_InsertSalesOrder_ondisk]
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
		(	DueDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, Comment, OrderDate, SubTotal, ModifiedDate)
		VALUES
		(	@DueDate, @Status, @OnlineOrderFlag, @PurchaseOrderNumber, @AccountNumber, @CustomerID, @SalesPersonID, @TerritoryID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @CreditCardID, @CreditCardApprovalCode, @CurrencyRateID, @Comment, @OrderDate, @SubTotal, @OrderDate )

		SET @SalesOrderID = SCOPE_IDENTITY()

		INSERT INTO Sales.SalesOrderDetail_ondisk
		(
			SalesOrderID, OrderQty, ProductID, SpecialOfferID,
			UnitPrice,
			UnitPriceDiscount,
			ModifiedDate
		)
		SELECT 
			@SalesOrderID, od.OrderQty, od.ProductID, od.SpecialOfferID,
			p.ListPrice,
			p.ListPrice * so.DiscountPct,
			@OrderDate
		FROM @SalesOrderDetails od JOIN Sales.SpecialOffer_ondisk so on od.SpecialOfferID=so.SpecialOfferID
			JOIN Production.Product_ondisk p on od.ProductID=p.ProductID
	COMMIT
END
GO

-- ============ end of table access demo

