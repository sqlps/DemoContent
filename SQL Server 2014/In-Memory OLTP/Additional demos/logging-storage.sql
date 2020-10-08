use master
go


drop database StorageDemo
go


CREATE DATABASE StorageDemo ON  
 PRIMARY (NAME = [StorageDemo_data], FILENAME = 'C:\data\StorageDemo_data.mdf'), 

 FILEGROUP [StorageDemo_FG] CONTAINS MEMORY_OPTIMIZED_DATA 
 (NAME = [StorageDemo_container1],  FILENAME = 'C:\data\StorageDemo_mod_container1')

 LOG ON (name = [hktest_log], Filename='C:\data\StorageDemo.ldf', size=100MB)

go

-- add container to the filegroup on separate disk to speed up recovery
  ALTER DATABASE StorageDemo
	ADD FILE (NAME='StorageDemo_container2', FILENAME='C:\data\StorageDemo_mod_container2') 
	TO FILEGROUP [StorageDemo_FG]
	go

use StorageDemo
go


IF EXISTS (SELECT * FROM sys.objects WHERE name='t1_inmem')
		DROP TABLE [dbo].[t1_inmem]
go


-- create a simple table
CREATE TABLE [dbo].[t1_inmem]
( [c1] int NOT NULL, 
  [c2] char(100) NOT NULL,  

  CONSTRAINT [pk_index91] PRIMARY KEY NONCLUSTERED HASH ([c1]) WITH(BUCKET_COUNT = 1000000)
) WITH (MEMORY_OPTIMIZED = ON, 
 DURABILITY = SCHEMA_AND_DATA)
go

-- show checkpoint files

IF EXISTS (SELECT * FROM sys.objects WHERE name='t1_disk')
		DROP TABLE [dbo].[t1_disk]
go
CREATE TABLE [dbo].[t1_disk]
( [c1] int NOT NULL, 
  [c2] char(100) NOT NULL)
go

create unique nonclustered index t1_disk_index on t1_disk(c1)
go


begin tran
declare @i int = 0
while (@i < 100)
begin
	insert into t1_disk values (@i, replicate ('1', 100))
	set @i = @i + 1
end
commit

-- you will see that SQL Server logged 200 log records
select * from sys.fn_dblog(NULL, NULL) 
where PartitionId in (select partition_id from sys.partitions where object_id=object_id('t1_disk'))
order by [Current LSN] asc

select sum([Log Record Length]) from sys.fn_dblog(NULL, NULL) 
where PartitionId in (select partition_id from sys.partitions where object_id=object_id('t1_disk'))


-- insert 100 rows
begin tran
declare @i int = 0
while (@i < 100)
begin
	insert into t1_inmem values (@i, replicate ('1', 100))
	set @i = @i + 1
end
commit


-- look at the log
select * from sys.fn_dblog(NULL, NULL) order by [Current LSN] desc --where PartitionId in (select partition_id from sys.partitions where object_id=object_id('t1'))


-- we can then look into inside of LOP_HK using
select [current lsn], [transaction id], operation, 
       operation_desc, tx_end_timestamp, total_size, table_id
from sys.fn_dblog_xtp(null, null)
where [Current LSN] = '00000020:000001de:0002'




-- show checkpoint files
set nocount on
go
begin tran
declare @i int = 1000
while (@i < 5000000)
begin
	insert into t1_inmem values (@i, replicate ('1', 100))
	set @i = @i + 1
end
commit
go

checkpoint
go

-- show checkpoint files