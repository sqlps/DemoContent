-- ================================ Start of native proc monitoring demo

-- sample database: [http://msdn.microsoft.com/en-us/library/dn511655.aspx]

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

-- check query plan [actual execution plan (STATISTICS XML) not supported
--  note that parameters are not required for checking the plan
SET SHOWPLAN_XML ON
GO
EXEC Sales.usp_InsertSalesOrder_native
GO
SET SHOWPLAN_XML OFF
GO


-- run insert sales orders workload - insert 20,000 orders
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
	EXEC Sales.usp_InsertSalesOrder_native @SalesOrderID OUTPUT, @DueDate, @CustomerID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @od; 
	SET @i += 1 
END
GO

-- monitoring queries, showing nothing, as stats collection was not enabled
select st.objectid, 
       object_name(st.objectid) as 'object name', 
       SUBSTRING(st.text, (qs.statement_start_offset/2) + 1, ((qs.statement_end_offset-qs.statement_start_offset)/2) + 1) as 'query text', 
       qs.creation_time,
       qs.last_execution_time,
       qs.execution_count,
       qs.total_worker_time,
       qs.last_worker_time,
       qs.min_worker_time,
       qs.max_worker_time,
       qs.total_elapsed_time,
       qs.last_elapsed_time,
       qs.min_elapsed_time,
       qs.max_elapsed_time
from sys.dm_exec_query_stats qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  st.dbid=db_id() and st.objectid in (select object_id 
from sys.sql_modules where uses_native_compilation=1)
order by qs.total_worker_time desc
go



-- enable stats collection, rerun workload
EXEC sp_xtp_control_proc_exec_stats @new_collection_value=1
EXEC sp_xtp_control_query_exec_stats @new_collection_value=1
GO

-- run insert sales orders workload - insert 20,000 orders
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
	EXEC Sales.usp_InsertSalesOrder_native @SalesOrderID OUTPUT, @DueDate, @CustomerID, @BillToAddressID, @ShipToAddressID, @ShipMethodID, @od; 
	SET @i += 1 
END
GO

-- native procedure execution stats
select object_id,
       object_name(object_id) as 'object name',
       cached_time,
       last_execution_time,
       execution_count,
       total_worker_time,
       last_worker_time,
       min_worker_time,
       max_worker_time,
       total_elapsed_time,
       last_elapsed_time,
       min_elapsed_time,
       max_elapsed_time 
from sys.dm_exec_procedure_stats
where database_id=db_id() and object_id in (select object_id 
from sys.sql_modules where uses_native_compilation=1)
order by total_worker_time desc

-- native query execution stats
select st.objectid, 
       object_name(st.objectid) as 'object name', 
       SUBSTRING(st.text, (qs.statement_start_offset/2) + 1, ((qs.statement_end_offset-qs.statement_start_offset)/2) + 1) as 'query text', 
       qs.creation_time,
       qs.last_execution_time,
       qs.execution_count,
       qs.total_worker_time,
       qs.last_worker_time,
       qs.min_worker_time,
       qs.max_worker_time,
       qs.total_elapsed_time,
       qs.last_elapsed_time,
       qs.min_elapsed_time,
       qs.max_elapsed_time
from sys.dm_exec_query_stats qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  st.dbid=db_id() and st.objectid in (select object_id 
from sys.sql_modules where uses_native_compilation=1)
order by qs.total_worker_time desc
go



-- disable stats collection
EXEC sp_xtp_control_proc_exec_stats @new_collection_value=0
EXEC sp_xtp_control_query_exec_stats @new_collection_value=0
GO

-- clean up
DROP PROC Sales.usp_InsertSalesOrder_native