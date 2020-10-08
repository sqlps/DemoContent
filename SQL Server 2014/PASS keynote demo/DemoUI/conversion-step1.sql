USE Fabrikam
GO
DROP TABLE purchases
GO
CREATE TABLE purchases
(
	SyntheticKey uniqueidentifier not null DEFAULT NEWID() PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 3000000),
	AppId int not null,
	CustomerId int not null,
	Total money not null,
	[Time] datetime2(7) not null
	-- Note on indexing:
	-- we want to find out what user has bought what products
	-- we also would like to find out what products have how much sales during a certain time period
	INDEX ix_purchaseTime NONCLUSTERED HASH ([Time]) WITH (BUCKET_COUNT = 3000000)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
GO

------------------------
-- User-defined Types --
------------------------

-- Before dropping these types, we must drop the stored procedures.
DROP PROCEDURE sp_insert_purchases
DROP PROCEDURE sp_read_recent_purchases
GO

DROP TYPE t_order_set
GO
CREATE TYPE t_order_set AS TABLE
(
	ProductId int not null PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 128),
	CustomerId int not null,
	Quantity int not null
	-- look up according to ProductId
) WITH (MEMORY_OPTIMIZED = ON)
GO

-----------------------
-- Stored Procedures --
-----------------------

-- Takes in a TVP for a set of orders
CREATE PROCEDURE sp_insert_purchases 
	@order_set dbo.t_order_set READONLY
AS BEGIN 

	-- calculate the totals and add them to the Orders table
	INSERT INTO dbo.purchases (AppId, CustomerId, Total, [Time])
	SELECT
		s.ProductId,
		s.CustomerId,
		2.99 AS Total,
		GETDATE() AS [Time]
	FROM @order_set s
END
GO

CREATE PROCEDURE sp_read_recent_purchases
	@customerId int --, @iteration int
AS BEGIN 
	SELECT AppId, Total, [Time]
	FROM dbo.purchases WITH (SNAPSHOT)
	WHERE [Time] = DATEADD(SECOND, -5, GETDATE())
END
GO

USE FabrikamDev
GO
ALTER PROCEDURE [dbo].[sp_insert_orders] 
	@order_set t_order_set READONLY
AS BEGIN
	WAITFOR DELAY N'00:00:00.1'
	-- calculate the totals and add them to the Orders table
	INSERT INTO orders (ProductId, CustomerId, Quantity, OrderTotal, OrderTime)
	SELECT
		s.ProductId,
		s.CustomerId,
		s.Quantity,
		s.Quantity * p.Price AS OrderTotal,
		GETDATE() AS OrderTime
	FROM @order_set s
		JOIN products p ON p.ProductId = s.ProductId
	UPDATE m
	SET m.Ranking = 10
	FROM most_recommended_products_after m, @order_set o
	WHERE m.ProductId = o.ProductId
END
GO
