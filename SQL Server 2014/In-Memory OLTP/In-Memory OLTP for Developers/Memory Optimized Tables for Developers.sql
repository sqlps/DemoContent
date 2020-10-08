-- ============ start of tables demo

USE master
GO
SET NOCOUNT ON
GO

if exists (select * from sys.databases where name='ContosoOLTP')
		drop database ContosoOLTP
go
CREATE DATABASE ContosoOLTP
GO

----- Enable database for memory optimized tables
-- add memory_optimized_data filegroup
ALTER DATABASE ContosoOLTP 
    ADD FILEGROUP contoso_mod CONTAINS MEMORY_OPTIMIZED_DATA
GO

-- add container to the filegroup
ALTER DATABASE ContosoOLTP 
	ADD FILE (NAME='contoso_mod', FILENAME='c:\data\contoso_mod') 
	TO FILEGROUP contoso_mod
GO

USE ContosoOLTP
GO

CREATE TABLE dbo.SalesOrders
(
	order_id INT NOT NULL, 
	order_date DATETIME2 NOT NULL,
	order_status TINYINT NOT NULL,

    CONSTRAINT PK_SalesOrders PRIMARY KEY 
		NONCLUSTERED HASH (order_id) WITH (BUCKET_COUNT = 2000000),

	INDEX ix_order_date_status NONCLUSTERED (order_date DESC)
) WITH (MEMORY_OPTIMIZED = ON)
GO


SELECT name, object_id, is_memory_optimized, durability, durability_desc 
FROM sys.tables WHERE type='U'
GO


-- show generated files
select db_id() as 'database_id'
go

















-- ======================== indexes demo

-- insert sample data

INSERT dbo.SalesOrders VALUES (1, '2013-12-02 12:38', 1)
INSERT dbo.SalesOrders VALUES (2, '2013-12-03 11:14', 1)
INSERT dbo.SalesOrders VALUES (3, '2013-12-01 10:01', 1)
INSERT dbo.SalesOrders VALUES (4, '2013-12-08 17:08', 1)
INSERT dbo.SalesOrders VALUES (5, '2013-12-07 21:11', 1)
GO

-- hash index:
--    CONSTRAINT PK_SalesOrders PRIMARY KEY 
--		NONCLUSTERED HASH (order_id) WITH (BUCKET_COUNT = 2000000),


-- point lookup query: sales order with ID 4

SELECT order_id, order_date, order_status
FROM dbo.SalesOrders
WHERE order_id=4
GO


-- nonclustered index:
--	INDEX ix_order_date_status NONCLUSTERED (order_date DESC)

-- range query: all orders on or after Dec 3rd

SELECT order_id, order_date, order_status
FROM dbo.SalesOrders
WHERE order_date >='2013-12-03'
GO

-- order by query: all orders, sorted on order date

SELECT order_id, order_date, order_status
FROM dbo.SalesOrders
ORDER BY order_date DESC
GO



-- clean up
DELETE FROM dbo.SalesOrders
GO



-- ======================== data access demo

SET NOCOUNT ON
GO
BEGIN TRAN
  DECLARE 
    @id int = 1,
	@status tinyint = 1

  WHILE @id <= 1000000
  BEGIN
    INSERT dbo.SalesOrders VALUES (@id, sysdatetime(), @status)
    SET @id += 1
  END
COMMIT
GO

SELECT TOP 100 * FROM dbo.SalesOrders
GO
SELECT TOP 100 * FROM dbo.SalesOrders ORDER BY order_id
GO
DELETE FROM dbo.SalesOrders 
GO

CREATE PROCEDURE dbo.InsertOrders
  WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS 
BEGIN ATOMIC WITH 
(	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'us_english')
  DECLARE 
    @id int = 1,
	@status tinyint = 1
 
  WHILE @id <= 1000000
  BEGIN
    INSERT dbo.SalesOrders VALUES (@id, sysdatetime(), @status)
    SET @id += 1
  END
END
GO

set statistics time on
EXEC dbo.InsertOrders -- this time it will be much faster
set statistics time off
GO

SELECT TOP 100 * FROM dbo.SalesOrders 
GO
DELETE FROM dbo.SalesOrders 
GO



-- ============ optional

CREATE PROCEDURE dbo.InsertOrder @id INT, @date datetime, @status tinyint
  WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS 
BEGIN ATOMIC WITH 
(	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'us_english')

  INSERT dbo.SalesOrders VALUES (@id, @date, @status)

END
GO

BEGIN TRAN
  DECLARE 
    @id int = 1,
	@order_date datetime,
	@status tinyint = 1

  WHILE @id <= 1000000
  BEGIN
    SET @order_date = sysdatetime()
    EXEC dbo.InsertOrder @id, @order_date, @status
    SET @id += 1
  END
COMMIT
GO


