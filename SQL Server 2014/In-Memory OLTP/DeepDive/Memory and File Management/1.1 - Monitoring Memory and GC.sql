/***************
 * Start Setup *
 ***************/

-- If IMOLTP_Demo is bound then drop it
select pool_id,name, min_memory_percent, max_memory_percent, max_memory_kb/1024 as max_memory_in_MB, used_memory_kb/1024 as used_memory_in_MB, target_memory_kb/1024 as target_memory_in_MB 
from sys.dm_resource_governor_resource_pools where name in ('internal','PoolHkDb1')


--EXEC sp_xtp_unbind_db_resource_pool 'IMOLTP_Demo'
--DROP RESOURCE POOL PoolHkDb1
go

--TO SAVE TIME RUN SCRIPT FIRST THEN EXPLAIN. STOP AFTER TRYING TO LOAD AT 40%

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
-- check DB and pool binding
SELECT d.database_id, d.name AS DbName, d.resource_pool_id AS PoolId
       , p.name AS PoolName, p.min_memory_percent, p.max_memory_percent
FROM sys.databases d
       LEFT OUTER JOIN sys.resource_governor_resource_pools p ON p.pool_id = d.resource_pool_id


Use Master
GO

if exists (select * from sys.databases where name='IMOLTP_Demo')
begin
	ALTER DATABASE IMOLTP_Demo set single_user with rollback immediate
	drop database IMOLTP_Demo
end
go

CREATE DATABASE [IMOLTP_DEMO]
 ON  PRIMARY 
( NAME = N'IMOLTP_DEMO', FILENAME = N'D:\DATA\IMOLTP_DEMO.mdf' , SIZE = 4096KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'IMOLTP_DEMO_log', FILENAME = N'D:\LOG\IMOLTP_DEMO_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO

----- Enable database for memory optimized tables by adding memory_optimized_data filegroup
ALTER DATABASE IMOLTP_Demo 
    ADD FILEGROUP IMOLTP_Demo_mod CONTAINS MEMORY_OPTIMIZED_DATA
GO

-- add container to the filegroup
ALTER DATABASE IMOLTP_Demo 
ADD FILE (NAME='IMOLTP_Demo_mod', FILENAME='D:\DATA\IMOLTP_Demo_mod') 
TO FILEGROUP IMOLTP_Demo_mod
GO


-- bind the database to the pool
EXEC sp_xtp_bind_db_resource_pool 'IMOLTP_Demo', 'PoolHkdb1'

alter database IMOLTP_Demo set offline
go
alter database IMOLTP_Demo set online
go

USE IMOLTP_Demo
GO

CREATE TABLE dbo.t_memopt(
	c1 int NOT NULL,
	C2 int NOT NULL INdex IDX Nonclustered,
	c3 char(40) NOT NULL,
	c4 char(8000) NOT NULL,

	CONSTRAINT [pk_t_memopt_c1] PRIMARY KEY NONCLUSTERED HASH (c1) WITH (BUCKET_COUNT = 1000000),
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)

/*************/
/* END Setup */
/*************/


--1) Open Perfmon and view Usage and Target for the pool stats
--2) Run query from 1.2
--3) Run the below
SET NOCOUNT ON
GO
Declare @outerloop int = 0
declare @i int = 0
while (@outerloop < 3000000)
begin
	begin tran
		select @i = 0
		while (@i <=3000)
		begin
			insert t_memopt values (@i + @outerloop, @i + @outerloop, 'a', replicate('b',8000))
			set @i += 1;
		end
	commit

	set @outerloop = @outerloop + @i
	set @i=0

	WAITFOR DELAY '00:00:01';

	--select 'rows moved to sql;

	delete	t_memopt
end

--4) After KC kicks in, check query from 1.2 again

/***********/
/* CLEANUP */
/***********/

EXEC sp_xtp_unbind_db_resource_pool 'IMOLTP_Demo'
DROP RESOURCE POOL PoolHkDb1
go
	
use master
GO

ALTER DATABASE IMOLTP_Demo 
     SET SINGLE_USER 
     WITH ROLLBACK IMMEDIATE
Go
DROP DATABASE IMOLTP_DEMO
GO

EXEC sp_configure 'show advanced options', 1
EXEC sp_configure 'max server memory (MB)', 11000
EXEC sp_configure 'min server memory (MB)', 11000
