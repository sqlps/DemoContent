-- Create the Table
CREATE TABLE SalesOrder_Staging ( 
    order_id    INT NOT NULL IDENTITY(1,1) PRIMARY KEY --4bytes
               NONCLUSTERED HASH WITH (BUCKET_COUNT = 10000), 
			   -- Hash Index Need to round up to a ^2 = 2^20 = 1048576. Size = 1048576*8bytes = 8MB
	Order_date datetime NULL,
    order_status int NOT NULL, 
    orderQty    INT NOT NULL, 
	SalesAmount	 Float NOT NULL)
  
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

--Populate Staging Table
SET IDENTITY_INSERT SalesOrder_Staging On
Insert SalesOrder_staging (order_id, order_date, order_status, OrderQty, Salesamount)
Select top 100000 order_id, order_date, order_status, OrderQty, Salesamount from SalesOrder
GO

--Create Native proc to insert records
CREATE PROCEDURE dbo.Insert100K_Rows_in_SalesOrder
  WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS Owner
AS 
BEGIN ATOMIC WITH 
(	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'us_english')

Insert dbo.SalesOrder ( order_date, order_status, OrderQty, Salesamount)
Select order_date, order_status, OrderQty, Salesamount from dbo.SalesOrder_staging
end
GO
