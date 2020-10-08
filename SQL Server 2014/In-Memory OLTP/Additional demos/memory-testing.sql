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



IF EXISTS (SELECT * FROM sys.objects WHERE name='Order Details')
		DROP TABLE dbo.[Order Details]
go

-- create a simple table
CREATE TABLE [dbo].[Order Details]
(
	[OrderID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[Quantity] [smallint] NOT NULL,
	[Discount] [real] NOT NULL

	INDEX [IX_OrderID] NONCLUSTERED HASH ([OrderID]) WITH ( BUCKET_COUNT = 1048576),
	INDEX [IX_ProductID] NONCLUSTERED HASH (	[ProductID]) WITH ( BUCKET_COUNT = 131072),
	CONSTRAINT [PK_Order_Details] PRIMARY KEY 
		NONCLUSTERED HASH ([OrderID],	[ProductID]) WITH ( BUCKET_COUNT = 1048576)
) WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )

GO

-- show DB memory report

-- insert 1000000 rows.
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

-- show DB memory report


-- memory DMVs
-- finding memory for objects
select object_name(object_id) as 'Object name', * 
from sys.dm_db_xtp_table_memory_stats 
where object_id = object_id('Order Details')


-- GC stats
select name as 'index_name', s.index_id, scans_started, rows_returned, rows_expired, rows_expired_removed 
from sys.dm_db_xtp_index_stats s join sys.indexes i on s.object_id=i.object_id and s.index_id=i.index_id
where object_id('Order Details') = s.object_id


-- delete alternate rows from the table 
set nocount on
go
begin tran
	declare @i int = 0
	while (@i < 1000000)
	begin
		delete from dbo.[Order Details] with (snapshot) where OrderID = @i
		set @i = @i + 2
	end
commit
go

-- GC stats
select name as 'index_name', s.index_id, scans_started, rows_returned, rows_expired, rows_expired_removed 
from sys.dm_db_xtp_index_stats s join sys.indexes i on s.object_id=i.object_id and s.index_id=i.index_id
where object_id('Order Details') = s.object_id

-- scan all indexes
select count(*) from [Order Details] with (index(PK_Order_Details))
select count(*) from [Order Details] with (index(IX_ProductID))
select count(*) from [Order Details] with (index(IX_OrderID))
go

-- GC stats
select name as 'index_name', s.index_id, scans_started, rows_returned, rows_expired, rows_expired_removed 
from sys.dm_db_xtp_index_stats s join sys.indexes i on s.object_id=i.object_id and s.index_id=i.index_id
where object_id('Order Details') = s.object_id



delete from [Order Details]
go 10


-- GC stats
select name as 'index_name', s.index_id, scans_started, rows_returned, rows_expired, rows_expired_removed 
from sys.dm_db_xtp_index_stats s join sys.indexes i on s.object_id=i.object_id and s.index_id=i.index_id
where object_id('Order Details') = s.object_id
go

select count(*) from [Order Details] with (index(PK_Order_Details))
select count(*) from [Order Details] with (index(IX_ProductID))
select count(*) from [Order Details] with (index(IX_OrderID))
go

-- GC stats
select name as 'index_name', s.index_id, scans_started, rows_returned, rows_expired, rows_expired_removed 
from sys.dm_db_xtp_index_stats s join sys.indexes i on s.object_id=i.object_id and s.index_id=i.index_id
where object_id('Order Details') = s.object_id

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


select * from sys.dm_db_xtp_table_memory_stats
select Sum( memory_allocated_for_indexes_kb + memory_allocated_for_table_kb) as memoryallocated_objects_in_kb from sys.dm_db_xtp_table_memory_stats

-- memory allocated for the instance
Select * from  sys.dm_xtp_memory_stats
select sum(total_memory_allocated_for_indexes_kb + total_memory_allocated_for_tables_kb + total_memory_allocated_for_system_kb) from sys.dm_xtp_memory_stats

-- memory consumers (database level)
select object_name(object_id), * from sys.dm_db_xtp_memory_consumers
select distinct memory_consumer_desc from sys.dm_db_xtp_memory_consumers
select sum(allocated_bytes)/1024 from sys.dm_db_xtp_memory_consumers

-- system memory consumers @ instance
select * from sys.dm_xtp_system_memory_consumers
select distinct memory_consumer_desc from sys.dm_xtp_system_memory_consumers
select sum(allocated_bytes)/1024 from sys.dm_xtp_system_memory_consumers

-- consumers for the whole instance
select * from sys.dm_xtp_consumer_memory_usage
select distinct memory_consumer_desc from sys.dm_xtp_consumer_memory_usage
select sum(allocated_bytes)/1024 from sys.dm_xtp_consumer_memory_usage



--summary info
select sum(allocated_bytes)/1024 from sys.dm_db_xtp_memory_consumers
select sum(allocated_bytes)/1024 from sys.dm_xtp_system_memory_consumers
-- this DMV accounts for all memory used by database and system memory consumers
select sum(allocated_bytes)/1024 from sys.dm_xtp_consumer_memory_usage


-- memory clerks/brokers
-- one rows is for DAC
select * from sys.dm_os_memory_brokers where memory_broker_type like '%xtp%'
-- this DMV accounts for all memory used by brokers
select * from sys.dm_os_memory_clerks where type like '%xtp%'
select distinct(name)  from sys.dm_os_memory_clerks 

select * from sys.dm_os_memory_objects where type like '%xtp%'
select sum(pages_in_bytes)/1024 from sys.dm_os_memory_objects where type like '%xtp%'



--
select db1.database_id, sum(db2. pages_in_bytes)/1024
from sys.databases as db1, sys.dm_os_memory_clerks as db2
where db1.database_id = convert (SUBSTRING(db2.name, 8, 32)
and db2.type like '%XTP%'

select convert (int, SUBSTRING('abcdefg123', 8, 100)) - 100
