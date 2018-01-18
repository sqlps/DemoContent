/*
Author: SQLMaestros.com
*/
USE INMEM_DB
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF(OBJECT_ID('GenerateOrders') IS NOT NULL)
DROP PROCEDURE [dbo].[GenerateOrders]
GO
IF(OBJECT_ID('InsertOrder1') IS NOT NULL)
DROP PROCEDURE [dbo].[InsertOrder1]
GO
IF(OBJECT_ID('InsertOrder') IS NOT NULL)
DROP PROCEDURE [dbo].[InsertOrder]
GO

IF(OBJECT_ID('orders') IS NOT NULL)
DROP TABLE [dbo].orders
GO
IF(OBJECT_ID('orders1') IS NOT NULL)
DROP TABLE [dbo].orders1
GO
CREATE TABLE orders(
  OrderID INT IDENTITY(1,1),
  OrderUserID INT FOREIGN KEY REFERENCES [dbo].[Users] ([UserID]),
  OrderDate DATETIME NOT NULL,
  OrderShipped TINYINT NOT NULL,
  OrderTrackingNumber varchar(80),
  ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
  OrderQuantity INT NOT NULL,
  OrderTax float NOT NULL
  PRIMARY KEY (OrderID)
);


CREATE TABLE [dbo].[orders1]
(
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[OrderUserID] [int] NULL,
	[OrderDate] [datetime] NOT NULL,
	[OrderShipped] [tinyint] NOT NULL,
	[OrderTrackingNumber] [varchar](80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ProductID] [int] NULL,
	[OrderQuantity] [int] NOT NULL,
	[OrderTax] [float] NOT NULL,

CONSTRAINT [orders_primaryKey] PRIMARY KEY NONCLUSTERED HASH 
(
	[OrderID]
)WITH ( BUCKET_COUNT = 100000)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )
USE [INMEM_DB]
GO

CREATE PROCEDURE [dbo].[InsertOrder1]
		(@productID INT,
		@quantity INT,
		@taxAmount FLOAT,
		@NoOfOrders INT)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC 
WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT,LANGUAGE = N'ENGLISH')
	
	DECLARE @i INT = 0
	DECLARE @OrderUserID INT
	WHILE (@i < @NoOfOrders)
	BEGIN
		
		SET @OrderUserID = 1 + CONVERT(INT, (1000)*RAND())

		INSERT INTO dbo.orders1
		SELECT
			@OrderUserID,		
			GETDATE(),
			0,
			80000000 + CONVERT(BIGINT, (90000000 - 80000000 + 1)*RAND()),
			@productID,
			@quantity,
			@taxAmount

		SET @i = @i + 1

	END
END

GO


CREATE PROCEDURE [dbo].[InsertOrder]
	(
		@productID INT,
		@quantity INT,
		@taxAmount FLOAT,
		@NoOfOrders INT
	)
AS
BEGIN
	
	DECLARE @i INT = 0
	DECLARE @OrderUserID INT
	WHILE (@i < @NoOfOrders)
	BEGIN
		
		SET @OrderUserID = 1 + CONVERT(INT, (1000)*RAND())

		INSERT INTO dbo.orders
		SELECT
			@OrderUserID,		
			GETDATE(),
			0,
			80000000 + CONVERT(BIGINT, (90000000 - 80000000 + 1)*RAND()),
			@productID,
			@quantity,
			@taxAmount

		SET @i = @i + 1

	END

END

GO

CREATE PROCEDURE [dbo].[GenerateOrders]
       (@batchSize INT = 100,
       @isInMem BIT,
       @TotalPrice DECIMAL(10,2) OUTPUT)
AS
BEGIN
       DECLARE @i INT = 0
       DECLARE @productID INT,
                                  @quantity INT,
                                  @taxAmount FLOAT,
                                  @noOfOrders INT = 0,
                                  @noofproducts INT,
                                  @prodPrice DECIMAL(10,2)

       SELECT @noofproducts = COUNT(1)
       FROM dbo.Products

       SET @TotalPrice = 0
       BEGIN TRANSACTION
       WHILE @i < @batchSize
       BEGIN
       
                     SET @productID = (1 + CONVERT(INT,(@noofproducts)*RAND()))
                     SET @quantity = (1 + CONVERT(INT,(19+1)*RAND()))
                     SET @taxAmount = (50 + CONVERT(INT,(100-50+1)*RAND()))
                     SET @noOfOrders = (10 + CONVERT(INT, (50-20+1)*RAND()))
                     IF(@batchSize - @noOfOrders - @i <=0)
                           SET @noOfOrders = @batchSize - @i

                     IF(@isInMem = 0)
                     EXEC InsertOrder
                                  @productID,
                                  @quantity,
                                  @taxAmount,
                                  @noOfOrders
                     ELSE
                     EXEC InsertOrder1
                                  @productID,
                                  @quantity,
                                  @taxAmount,
                                  @noOfOrders

                     SET @i = @i + @noOfOrders

                     SELECT @prodPrice = (ProductSalePrice + @taxAmount) * @quantity * @noOfOrders
                     FROM Products
                     WHERE ProductID = @ProductID

                     SET @TotalPrice = @TotalPrice + @prodPrice
                     --SELECT @TotalPrice, @prodPrice, @taxAmount, @quantity, @noOfOrders, @i

       END
       COMMIT TRANSACTION
       RETURN
       
END

GO
