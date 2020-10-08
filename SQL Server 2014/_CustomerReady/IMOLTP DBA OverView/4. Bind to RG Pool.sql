/* This Sample Code is provided for the purpose of illustration only and is not intended
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys fees, that arise or
result from the use or distribution of the Sample Code.*/

--TO SAVE TIME RUN SCRIPT FIRST THEN EXPLAIN. STOP AFTER TRYING TO LOAD AT 40%


--Memory RG integration
use master
dbcc traceoff (9864, -1)
go

-- configure IM pool to be ~1.6GB
EXEC sp_configure 'show advanced options', 1
EXEC sp_configure 'max server memory (MB)', 4000
EXEC sp_configure 'min server memory (MB)', 4000
RECONFIGURE
go

-- check the max server memory
select * from sys.configurations where name like '%server memory (MB)'

-- create the resoure pool
CREATE RESOURCE POOL PoolHkDb1 WITH (MIN_MEMORY_PERCENT = 5, MAX_MEMORY_PERCENT = 10);
ALTER RESOURCE GOVERNOR RECONFIGURE;
go


-- check pool memory settings
select pool_id,name, min_memory_percent, max_memory_percent, max_memory_kb/1024 as max_memory_in_MB, used_memory_kb/1024 as used_memory_in_MB, target_memory_kb/1024 as target_memory_in_MB 
from sys.dm_resource_governor_resource_pools where name in ('internal','PoolHkDb1')

-- check DB and pool binding
SELECT d.database_id, d.name AS DbName, d.resource_pool_id AS PoolId
       , p.name AS PoolName, p.min_memory_percent, p.max_memory_percent
FROM sys.databases d
       LEFT OUTER JOIN sys.resource_governor_resource_pools p ON p.pool_id = d.resource_pool_id

-- bind the database to the pool
EXEC sp_xtp_bind_db_resource_pool 'IMOLTP_Demo', 'PoolHkdb1'

alter database IMOLTP_Demo set offline
go
alter database IMOLTP_Demo set online
go

USE IMOLTP_Demo
go

CREATE TABLE dbo.t_large (
       c1 int NOT NULL,
       c2 char(40) NOT NULL,
       c3 char(8000) NOT NULL,

       CONSTRAINT [pk_t1_c1] PRIMARY KEY NONCLUSTERED HASH (c1) WITH (BUCKET_COUNT = 100000)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
go

-- load 200K rows. you will hit OOM
-- Msg 701, Level 17, State 103, Line 106
-- There is insufficient system memory in resource pool 'PoolHkDb1' to run this query.
CREATE PROCEDURE dbo.InsertRecords_LARGE @RecordsToInsert int, @LargeColumn varchar(8000)
  WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS Owner
AS 
BEGIN ATOMIC WITH 
(	TRANSACTION ISOLATION LEVEL = SNAPSHOT,	LANGUAGE = N'us_english')
Declare @Counter int = 0
	while (@Counter <= @RecordsToInsert)
	begin
		   insert dbo.t_large values (@Counter, 'a', @LargeColumn)
		   set @Counter += 1;
	end
END
GO

Declare @LargeColumn varchar(8000) = replicate('b',8000)
Exec dbo.InsertRecords_LARGE 50000, @largeColumn
GO

/************/
/*STOP HERE */
/************/

Select Count(*) from t_large

-- change the setting to allow up to 80% of memory to the pool
alter resource pool PoolHkDb1 with (MAX_MEMORY_PERCENT = 40)
ALTER RESOURCE GOVERNOR RECONFIGURE;
go

Declare @LargeColumn varchar(8000) = replicate('b',8000)
Exec dbo.InsertRecords_LARGE 50000, @largeColumn
GO
-- pool management: cleaning up

EXEC sp_xtp_unbind_db_resource_pool 'IMOLTP_Demo'
DROP RESOURCE POOL PoolHkDb1
go

drop procedure InsertRecords_LARGE;
drop table t_large;
go


-------------- end -----------------