
use master
go

/*
ALTER DATABASE storageDemo 
     SET SINGLE_USER 
     WITH ROLLBACK IMMEDIATE
Go
Drop database StorageDemo
Go
*/

CREATE DATABASE StorageDemo ON  
 PRIMARY (NAME = [StorageDemo_data], FILENAME = 'D:\sqlservr\data\StorageDemo_data.mdf'), 
 FILEGROUP [StorageDemo_FG] CONTAINS MEMORY_OPTIMIZED_DATA 
 (NAME = [StorageDemo_container1],  FILENAME = 'D:\sqlservr\data\StorageDemo_mod_container1')
 LOG ON (name = [hktest_log], Filename='D:\sqlservr\data\StorageDemo.ldf', size=100MB)
COLLATE Latin1_General_100_BIN2
go

use StorageDemo
go


IF EXISTS (SELECT * FROM sys.objects WHERE name='t1_inmem')
DROP TABLE [dbo].[t1_inmem]
go


-- create a simple in-mem table
CREATE TABLE [dbo].[t1_inmem]
( [c1] int NOT NULL, 
  [c2] char(100) NOT NULL,  

  CONSTRAINT [pk_index] PRIMARY KEY NONCLUSTERED HASH ([c1]) WITH(BUCKET_COUNT = 1000000),
  INDEX [IX_c2] NONCLUSTERED ([c2])
) WITH (MEMORY_OPTIMIZED = ON,  DURABILITY = SCHEMA_AND_DATA)
go

-- show checkpoint files
select * from sys.dm_db_xtp_checkpoint_files order by file_type_desc


-- log size comparison - create a comparable disk-based table
IF EXISTS (SELECT * FROM sys.objects WHERE name='t1_disk')
DROP TABLE [dbo].[t1_disk]
go
CREATE TABLE [dbo].[t1_disk]
( [c1] int primary key, 
  [c2] char(100) NOT NULL)
go
create nonclustered index t1_disk_index on t1_disk(c2)
go


-- insert into disk-based table
set nocount on
go
begin tran
declare @i int = 0
while (@i < 100)
begin
insert into t1_disk values (@i, replicate ('1', 100))
set @i = @i + 1
end
commit

-- you will see that SQL Server logged 200 log records (heap and index)
select partitionId,* from sys.fn_dblog(NULL, NULL) 
where PartitionId in (select partition_id from sys.partitions where object_id=object_id('t1_disk'))
order by [Current LSN] asc

-- log size
select sum([Log Record Length]) from sys.fn_dblog(NULL, NULL) 
where PartitionId in (select partition_id from sys.partitions where object_id=object_id('t1_disk'))


-- insert 100 rows in mem
set nocount on
go
begin tran
declare @i int = 0
while (@i < 100)
begin
insert into t1_inmem values (@i, replicate ('1', 100))
set @i = @i + 1
end
commit


-- look at the log - roughly the size of data
select PartitionId,* from sys.fn_dblog(NULL, NULL) 
order by [Current LSN] desc


-- we can then look into inside of LOP_HK using
select [current lsn], [transaction id], operation, 
       operation_desc, tx_end_timestamp, total_size, table_id
from sys.fn_dblog_xtp(null, null)
where [Current LSN] = '0000001f:000006c7:0003'


checkpoint
go

-- show active checkpoint files
select * from sys.dm_db_xtp_checkpoint_files where state <>0 

-- delete all data in in-mem table
delete from [dbo].[t1_inmem]
go

checkpoint
go

-- show active checkpoint files again

------------- end --------------











--------
drop procedure x;
go

create procedure x
as
begin
select 1;
select @@version;
end


select * from sys.sysprocesses 
where dbid 
  in (select database_id from sys.databases where name = 'StorageDemo')