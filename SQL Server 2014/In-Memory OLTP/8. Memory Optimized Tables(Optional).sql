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

IF EXISTS (SELECT * FROM sys.objects WHERE name='InsertOrder')
		DROP PROC dbo.InsertOrder
go
IF EXISTS (SELECT * FROM sys.objects WHERE name='InsertOrders')
		DROP PROC dbo.InsertOrders
go
IF EXISTS (SELECT * FROM sys.objects WHERE name='SalesOrders')
		DROP TABLE dbo.SalesOrders
go
CREATE TABLE dbo.SalesOrders
(
	order_id INT NOT NULL, 
	order_date DATETIME NOT NULL,
	order_status TINYINT NOT NULL,

   CONSTRAINT PK_SalesOrders PRIMARY KEY 
		NONCLUSTERED HASH (order_id) WITH (BUCKET_COUNT = 2000000)
) WITH (MEMORY_OPTIMIZED = ON)
GO

SELECT name, object_id, is_memory_optimized, durability, durability_desc 
FROM sys.tables WHERE type='U'
GO

select db_id()
go
-- show generated files


SET NOCOUNT ON
GO
BEGIN TRAN
  DECLARE 
    @id int = 1,
	@status tinyint = 1

  WHILE @id <= 1000000
  BEGIN
    INSERT dbo.SalesOrders VALUES (@id, getdate(), @status)
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
    INSERT dbo.SalesOrders VALUES (@id, getdate(), @status)
    SET @id += 1
  END
END
GO

set statistics time on
EXEC dbo.InsertOrders 
set statistics time off
GO

SELECT TOP 100 * FROM dbo.SalesOrders 
GO
DELETE FROM dbo.SalesOrders 
GO

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
    SET @order_date = getdate()
    EXEC dbo.InsertOrder @id, @order_date, @status
    SET @id += 1
  END
COMMIT
GO


-- ============ end of tables demo


-- ============ start of transactions demo

IF EXISTS (SELECT * FROM sys.objects WHERE name='SalesOrders_disk')
		DROP TABLE dbo.SalesOrders_disk
go
CREATE TABLE dbo.SalesOrders_disk
(
	order_id INT NOT NULL, 
	order_date DATETIME NOT NULL,
	order_status TINYINT NOT NULL,

   CONSTRAINT PK_SalesOrders_disk PRIMARY KEY  (order_id) 
) 
GO
INSERT dbo.SalesOrders_disk VALUES (1, getdate(), 1)
INSERT dbo.SalesOrders_disk VALUES (2, getdate(), 2)
GO

-- update disk-based table
BEGIN TRAN
  UPDATE dbo.SalesOrders_disk 
    SET order_status=2 
    WHERE order_id=1
COMMIT
GO

-- update memory-optimized table
BEGIN TRAN
  UPDATE dbo.SalesOrders WITH (SNAPSHOT) 
    SET order_status=2 
	WHERE order_id=1
COMMIT
GO

SELECT * FROM dbo.SalesOrders WHERE order_id=1
GO

-- T1
-- step 1
BEGIN TRAN
  SELECT * FROM dbo.SalesOrders_disk WITH (REPEATABLEREAD)
    WHERE order_id=2

-- step 3
  UPDATE dbo.SalesOrders_disk WITH (REPEATABLEREAD)
    SET order_status=3
	WHERE order_id=1
COMMIT
GO

-- T1
-- step 1
BEGIN TRAN
  SELECT * FROM dbo.SalesOrders WITH (REPEATABLEREAD)
    WHERE order_id=2

-- step 3
  UPDATE dbo.SalesOrders WITH (REPEATABLEREAD)
    SET order_status=3
	WHERE order_id=1
-- step 5
COMMIT



-- T1
-- step 1
BEGIN TRAN
  UPDATE dbo.SalesOrders_disk WITH (READCOMMITTED)
    SET order_status=4
	WHERE order_id=1

-- step 3
  SELECT * FROM dbo.SalesOrders_disk WITH (READCOMMITTED)
    WHERE order_id=2
COMMIT


-- T1
-- step 1
BEGIN TRAN
  UPDATE dbo.SalesOrders WITH (SNAPSHOT)
    SET order_status=4
	WHERE order_id=1

-- step 3
  SELECT * FROM dbo.SalesOrders WITH (SNAPSHOT)
    WHERE order_id=2
COMMIT






-- all databases
select * from sys.databases
go

-- all tables
select * from sys.tables where type='U'
go

-- all SQL modules
select * from sys.sql_modules
go