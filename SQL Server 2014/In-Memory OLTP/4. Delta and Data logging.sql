
-- PREP
USE [IMOLTP_Demo]
GO

CREATE FUNCTION dbo.fn_GetNumbers
 (
    @Start BIGINT,
    @End BIGINT
 )
    RETURNS @ret TABLE(Number BIGINT)

    AS

    BEGIN
        WITH
            L0 AS (SELECT 1 AS C UNION ALL SELECT 1), --2 rows
            L1 AS (SELECT 1 AS C FROM L0 AS A, L0 AS B),--4 rows
            L2 AS (SELECT 1 AS C FROM L1 AS A, L1 AS B),--16 rows
            L3 AS (SELECT 1 AS C FROM L2 AS A, L2 AS B),--256 rows
            L4 AS (SELECT 1 AS C FROM L3 AS A, L3 AS B),--65536 rows
            L5 AS (SELECT 1 AS C FROM L4 AS A, L4 AS B),--4294967296 rows
            num AS (SELECT ROW_NUMBER() OVER(ORDER BY C) AS N FROM L5)

        INSERT INTO @ret(Number) 
            SELECT N FROM num WHERE N BETWEEN @Start AND @End

    RETURN

    END
GO

CREATE TABLE IMOL_T2 ( 
IDX_Col INT NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000), 
CharCol1 CHAR(4000) NULL, 
CharCol2 CHAR(4000) NULL )
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

INSERT IMOL_T2 
    VALUES (-1, 'a', 'b')
GO

--
-- DEMO # 1
-- Checkpoint Files
--

-- 
-- CHECKPOINT to show file creation
--
USE [IMOLTP_Demo]
GO

CHECKPOINT
GO

SELECT checkpoint_file_id,
checkpoint_pair_file_id,
file_type_desc,
state_desc,
file_size_in_bytes,
file_size_used_in_bytes ,*
FROM sys.dm_db_xtp_checkpoint_files
WHERE internal_storage_slot IS NOT NULL
ORDER BY upper_bound_tsn, file_type
GO

Select * from  sys.dm_db_xtp_checkpoint_files
-- Open folder: D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\IMOLTP_Demo_MOD_dir\$FSLOG

--
-- Show another Checkpoint file pair generated on a manual Checkpoint
--
CHECKPOINT
GO

SELECT file_id,
pair_file_id,
file_type_desc,
is_active,
file_size_in_bytes,
file_size_used_in_bytes
FROM sys.dm_db_xtp_checkpoint_files
WHERE internal_storage_slot IS NOT NULL
ORDER BY transaction_id_upper_bound, file_type

-- Review folder: S:\DBData\IMOLTP_Demo_MOD_dir

--
-- Insert a bunch of records
--

INSERT IMOL_T2 SELECT Number, 'x', 'y'  FROM dbo.fn_GetNumbers(1, 20000)
INSERT IMOL_T2 SELECT Number, 'x', 'y'  FROM dbo.fn_GetNumbers(20001, 40000)
INSERT IMOL_T2 SELECT Number, 'x', 'y'  FROM dbo.fn_GetNumbers(40001, 60000)
INSERT IMOL_T2 SELECT Number, 'x', 'y'  FROM dbo.fn_GetNumbers(60001, 80000)
INSERT IMOL_T2 SELECT Number, 'x', 'y'  FROM dbo.fn_GetNumbers(80001, 100000)
GO;

CHECKPOINT
GO
SELECT checkpoint_file_id,
checkpoint_pair_file_id,
file_type_desc,
state_desc,
file_size_in_bytes,
file_size_used_in_bytes
FROM sys.dm_db_xtp_checkpoint_files
WHERE internal_storage_slot IS NOT NULL
ORDER BY upper_bound_tsn, file_type

-- Review folder: D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\IMOLTP_Demo_MOD_dir





--
-- DEMO # 2
-- Logging
--

-- 
-- Create On-Disk Table, Insert 200 records
--
CREATE TABLE Disk_T3 ( 
IDX_Col INT NOT NULL PRIMARY KEY CLUSTERED , 
CharCol1 CHAR(10) NULL )
GO

INSERT Disk_T3 SELECT Number, 'x' FROM dbo.fn_GetNumbers(1, 200)
GO

-- Review Log records:
SELECT * FROM sys.fn_dblog(NULL, NULL)
WHERE PartitionId IN (SELECT partition_id FROM sys.partitions
WHERE object_id = object_id('Disk_T3'))
ORDER BY [Current LSN] ASC;

-- 
-- Create In-Memory Table, Insert 200 records
--
CREATE TABLE IMOL_T3 ( 
IDX_Col INT NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 1024), 
CharCol1 CHAR(10) NULL )
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

GO
BEGIN TRANSACTION;
INSERT IMOL_T3 SELECT Number, 'x' FROM dbo.fn_GetNumbers(1, 200)
COMMIT TRANSACTION;
GO

-- Review Log records:
SELECT top 3 * FROM sys.fn_dblog(NULL, NULL)
ORDER BY [Current LSN] DESC;



--
-- BONUS:
-- Use this query to split the IMOL transaction into rows:
/*
SELECT[current lsn], 
[transaction id], 
operation,
operation_desc, 
tx_end_timestamp, 
total_size,
object_name(table_id) AS TableName
FROM sys.fn_dblog_xtp(null, null)
WHERE [Current LSN] = '[value from previous query]';
*/

