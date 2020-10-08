--see: https://blogs.msdn.microsoft.com/sqlserverstorageengine/2016/03/21/improving-temp-table-and-table-variable-performance-using-memory-optimization/

-- ===================================
-- Step 0) Enable Query Store
-- ===================================

USE [master]
GO
ALTER DATABASE [INMEM_DB] SET QUERY_STORE = ON
GO
ALTER DATABASE [INMEM_DB] SET QUERY_STORE CLEAR;
GO
ALTER DATABASE [INMEM_DB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, INTERVAL_LENGTH_MINUTES = 1)
GO

-- ===================================
-- Step 1) Create two different Table Types
-- ===================================

use INMEM_DB
Go

--Disk based
DROP TYPE IF EXISTS dbo.test_disk
Go
CREATE TYPE dbo.test_disk AS TABLE
(c1 INT NOT NULL,
 c2 CHAR(10));

 --In-Memory
 DROP TYPE IF EXISTS dbo.test_memory
Go
 CREATE TYPE dbo.test_memory AS TABLE
(c1 INT NOT NULL INDEX ix_c1, --Atleast 1 index
 c2 CHAR(10))
WITH (MEMORY_OPTIMIZED=ON);


-- ===============================================================
-- Step 2) Create two procs using in-mem and global temp tables
-- ===============================================================
--In TempDB
CREATE PROCEDURE sp_temp
AS
    BEGIN
        IF NOT EXISTS (SELECT * FROM tempdb.sys.objects WHERE name=N'##temp1')
             CREATE TABLE ##temp1
                    (
                      c1 INT NOT NULL ,
                      c2 NVARCHAR(4000)
                    );
        BEGIN TRAN
        DECLARE @i INT = 0;
        WHILE @i < 100
            BEGIN
                INSERT  ##temp1
                VALUES  ( @i, N'abc' );
                SET @i += 1;
            END;
        COMMIT
    END;
GO

--In-Mem
CREATE TABLE dbo.temp1
(c1 INT NOT NULL INDEX ix_1 ,
 c2 NVARCHAR(4000))
WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_ONLY);
GO
DROP PROCEDURE IF EXISTS sp_temp_inmem
GO
CREATE PROCEDURE sp_temp_inmem
AS
    BEGIN
        BEGIN TRAN
        DECLARE @i INT = 0;
        WHILE @i < 100
            BEGIN
                INSERT  dbo.temp1
                VALUES  ( @i, N'abc' );
                SET @i += 1;
            END;
        COMMIT
    END;


-- =======================================
-- Step 3) Compare inserts Disk vs In-Mem
-- =======================================
--Record TempDB IO Activity
Select * from sys.dm_io_virtual_file_stats(DB_ID(N'tempdb'),NULL)
--37608
-- Disk
SET NOCOUNT ON
GO
DECLARE @tv dbo.test_disk
INSERT  @tv VALUES  ( 1, 'n' )
INSERT  @tv VALUES  ( 2, 'm' )
DELETE  FROM @tv
GO 10000

--This loads a global temp Table
exec sp_temp
GO 10000

--Look at impact to TempDB
Select * from sys.dm_io_virtual_file_stats(DB_ID(N'tempdb'),NULL)


--InMem
DECLARE @tv_inmem dbo.test_memory
INSERT  @tv_inmem VALUES  ( 1, 'n' )
INSERT  @tv_inmem VALUES  ( 2, 'm' )
DELETE  FROM @tv_inmem
GO 10000
exec sp_temp_inmem
GO 10000


--What's the impact to TempDB

Select * from sys.dm_io_virtual_file_stats(DB_ID(N'tempdb'),NULL)

--Look at QueryStore