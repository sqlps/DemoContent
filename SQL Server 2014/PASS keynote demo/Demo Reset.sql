USE master
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name LIKE 'Fabrikam')
BEGIN
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'Fabrikam'
END
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name LIKE 'Fabrikam')
BEGIN
	ALTER DATABASE [Fabrikam] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE [Fabrikam]
END
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name LIKE 'FabrikamDev')
BEGIN
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'FabrikamDev'
END
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name LIKE 'FabrikamDev')
BEGIN
	ALTER DATABASE [FabrikamDev] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE [FabrikamDev]
END
GO

USE [master]
RESTORE DATABASE [Fabrikam] FROM DISK = N'C:\PASS keynote demo\Fabrikam_Back.bak' WITH FILE = 1,  NOUNLOAD,  STATS = 5
GO

USE [master]
RESTORE DATABASE [FabrikamDev] FROM DISK = N'C:\PASS keynote demo\Fabrikam_Dev.bak' WITH FILE = 1,  NOUNLOAD,  STATS = 5
GO

ALTER AUTHORIZATION ON DATABASE::Fabrikam TO [SQL2014CTP2\Administrator]
ALTER AUTHORIZATION ON DATABASE::FabrikamDev TO [SQL2014CTP2\Administrator]
GO

----------------------------------
-- Run the script starting here --
----------------------------------

USE Fabrikam
GO

CREATE TABLE purchase_history
(
	AppId int not null,
	CustomerId int not null,
	Total money not null,
	[Time] datetime2(7) not null,
	Review nchar(3500) not null
)
GO

CREATE CLUSTERED COLUMNSTORE INDEX ccix_purchase_history ON purchase_history
GO

-- Offload a batch of sales transactions to the Apollo table for storage
-- Offload a batch of sales transactions to the Apollo table for storage
CREATE PROCEDURE [dbo].[sp_update_hotlist]
AS BEGIN
	BEGIN TRANSACTION
		INSERT INTO purchase_history (AppId, CustomerId, Total, [Time], Review)
		SELECT 
			o.ProductId, 
			o.CustomerId, 
			o.OrderTotal, 
			o.OrderTime, 
			N'bxfihrcu5tneqvs_fqstafk@kjgf8@u@kc62yonnztz4rpwjgkshg@jui9ftlcuz@uyu_23zoqavfbfjqg8olbxskdoetluqe9@qqjidvjledkroctayswuks@xk1' AS review
		FROM FabrikamDev.dbo.order_archive_source o
		INSERT INTO FabrikamDev.dbo.t_last_updated (ts) VALUES (CURRENT_TIMESTAMP)
	COMMIT TRANSACTION
END
GO

USE FabrikamDev
GO

CREATE SEQUENCE sq_order AS int START WITH 1 INCREMENT BY 1
GO

ALTER PROCEDURE [dbo].[sp_insert_orders] 
	@order_set t_order_set READONLY
AS BEGIN
	WAITFOR DELAY N'00:00:03.7'
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
	SET m.Ranking = NEXT VALUE FOR sq_order
	FROM most_recommended_products_after m, @order_set o
	WHERE m.ProductId = o.ProductId
END
GO
ALTER PROCEDURE [dbo].[sp_find_recommended_products]
	@productId int, @CustomerId int
AS BEGIN
	WAITFOR DELAY N'00:00:06.2'
	SELECT TOP 5 RecommendedProductId AS ProductId FROM product_recommendations WHERE purchasedProductid = @productId ORDER BY RecommendedWeight DESC
END
GO
ALTER PROCEDURE sp_get_last_update
AS BEGIN
	DECLARE @last_update datetime2(7)
	SELECT TOP 1 @last_update = ts FROM t_last_updated ORDER BY ts DESC
	SELECT DATEDIFF(SECOND, @last_update, GETDATE()) as LastUpdate
END
GO

ALTER PROCEDURE [dbo].[sp_find_most_purchased_products_by_type]
	@type int, @top_x int
AS BEGIN
	SELECT TOP 5 ProductId, [Type] as purchases FROM most_recommended_products_before WHERE [type] = @type ORDER BY Ranking DESC
END
GO

CREATE TABLE t_last_updated
(
	ts datetime2(7) not null
)
GO

TRUNCATE TABLE t_last_updated
INSERT INTO t_last_updated (ts) VALUES (DATEADD(HOUR, -15, GETDATE()));
GO

TRUNCATE TABLE FabrikamDev.dbo.order_archive_source
INSERT INTO FabrikamDev.dbo.order_archive_source 
SELECT TOP 500000 * 
FROM FabrikamDev.dbo.order_archive_source_bak

USE Fabrikam
GO
DELETE FROM Fabrikam.dbo.app_criteria WHERE AppId > 60000