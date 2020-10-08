---- Memory usage scripts

USE master
GO
SET NOCOUNT ON
GO

if exists (select * from sys.databases where name='IM_OLTP_mem')
drop database IM_OLTP_mem
go
CREATE DATABASE IM_OLTP_mem
GO

----- Enable database for memory optimized tables by adding memory_optimized_data filegroup
ALTER DATABASE IM_OLTP_mem 
    ADD FILEGROUP IM_OLTP_mem_mod CONTAINS MEMORY_OPTIMIZED_DATA
GO

-- add container to the filegroup
ALTER DATABASE IM_OLTP_mem 
ADD FILE (NAME='IM_OLTP_mem_mod', FILENAME='d:\sqlservr\data\IM_OLTP_mem_mod') 
TO FILEGROUP IM_OLTP_mem_mod
GO

USE IM_OLTP_mem
GO



IF EXISTS (SELECT * FROM sys.objects WHERE name='Order Details')
DROP TABLE dbo.[Order Details]
go

-- create a simple table, 5 columns, 3 nonclustered hash indexes and 1 nonclustered (range) index
CREATE TABLE [dbo].[Order Details]
(
[OrderID] [int] NOT NULL,
[ProductID] [int] NOT NULL,
[UnitPrice] [money] NOT NULL,
[Quantity] [smallint] NOT NULL,
[Discount] [real] NOT NULL

INDEX [IX_OrderID] NONCLUSTERED HASH ([OrderID]) WITH ( BUCKET_COUNT = 1048576),
INDEX [IX_ProductID] NONCLUSTERED HASH ([ProductID]) WITH ( BUCKET_COUNT = 1048576),
CONSTRAINT [PK_Order_Details] PRIMARY KEY NONCLUSTERED HASH ([OrderID],[ProductID]) WITH ( BUCKET_COUNT = 1048576),
INDEX [IX_OrderID2] NONCLUSTERED ([OrderID])
) WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )

GO

--hash index size calculation in KB = 24MB
select 3*8*1024


-- show DB memory report
select object_name(object_id) as 'Object name', memory_used_by_table_kb,memory_used_by_indexes_kb
from sys.dm_db_xtp_table_memory_stats 
where object_id = object_id('Order Details')

-- insert 1M rows and recheck memory usage

-- row size calculation (cols + header + Ptrs) = 76B 
select 4+4+8+2+4+22+4*8

--range index dependent on data (key+pointer) in 12 MB
select (4+8)

set nocount on
go
begin tran
declare @i int = 0
while (@i < 1000000)
begin
insert into dbo.[Order Details] values (@i, @i % 100000, @i % 57, @i % 10, 0.5)
set @i = @i + 1
end
commit
go

-- memory usage
select object_name(object_id) as 'Object name', memory_used_by_table_kb,memory_used_by_indexes_kb
from sys.dm_db_xtp_table_memory_stats 
where object_id = object_id('Order Details')


-- show memory usage report in SSMS as well

--------------------- end --------------------


--Memory RG integration



use master
--dbcc traceoff (9864, -1) /* not needed in RTM */
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
CREATE RESOURCE POOL PoolHkDb1 WITH (MIN_MEMORY_PERCENT = 40, MAX_MEMORY_PERCENT = 40);
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
EXEC sp_xtp_bind_db_resource_pool 'IM_OLTP_mem', 'PoolHkdb1'

alter database IM_OLTP_mem set offline
go
alter database IM_OLTP_mem set online
go


USE IM_OLTP_mem
go

CREATE TABLE dbo.t_large (
       c1 int NOT NULL,
       c2 char(40) NOT NULL,
       c3 char(8000) NOT NULL,

       CONSTRAINT [pk_t1_c1] PRIMARY KEY NONCLUSTERED HASH (c1) WITH (BUCKET_COUNT = 100000)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
go

-- load 200K rows. you will hit OOM - in perfmon show target and used for dedicated pool only scale 0.00001
-- Msg 701, Level 17, State 103, Line 106
-- There is insufficient system memory in resource pool 'PoolHkDb1' to run this query.
SET NOCOUNT ON
GO
declare @i int = 0
while (@i <= 200000)
begin
       insert t_large values (@i, 'a', replicate ('b', 8000))
       set @i += 1;
end
go


-- change the setting to allow up to 80% of memory to the pool
alter resource pool PoolHkDb1 with (MAX_MEMORY_PERCENT = 80)
ALTER RESOURCE GOVERNOR RECONFIGURE;
go

-- now we can insert more rows
declare @i int = 200000
while (@i <= 230000)
begin
       insert t_large values (@i, 'a', replicate ('b', 8000))
       set @i += 1;
end
go




-- pool management: cleaning up

EXEC sp_xtp_unbind_db_resource_pool 'IM_OLTP_mem'
DROP RESOURCE POOL PoolHkDb1
go

drop table t_large;
go


-------------- end -----------------


ALTER DATABASE IM_OLTP_mem 
     SET SINGLE_USER 
     WITH ROLLBACK IMMEDIATE
Go
