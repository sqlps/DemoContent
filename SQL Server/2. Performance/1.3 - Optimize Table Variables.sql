--see: https://blogs.msdn.microsoft.com/sqlserverstorageengine/2016/03/21/improving-temp-table-and-table-variable-performance-using-memory-optimization/

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

-- =======================================
-- Step 2) Compare inserts Disk vs In-Mem
-- =======================================

-- Disk
SET NOCOUNT ON
GO
DECLARE @tv dbo.test_disk
INSERT  @tv VALUES  ( 1, 'n' )
INSERT  @tv VALUES  ( 2, 'm' )
DELETE  FROM @tv
GO 10000




--InMem
DECLARE @tv dbo.test_memory
INSERT  @tv VALUES  ( 1, 'n' )
INSERT  @tv VALUES  ( 2, 'm' )
DELETE  FROM @tv
GO 10000


