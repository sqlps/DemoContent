--From http://blogs.msdn.com/b/sql_pfe_blog/archive/2013/08/13/oops-i-forgot-to-leave-an-empty-sql-table-partition-how-can-i-split-it-with-minimal-io-impact.aspx

/*****************************************************
Step 1: Scenario SETUP
*************************************************/
use master
go
drop database PartitionTest
go
create database PartitionTest
go
use PartitionTest
go
-- Add Filegroups
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG1];
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG2];
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG3];
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG4];
GO
Alter database PartitionTest set recovery simple
go

-- Add Files
ALTER DATABASE [PartitionTest] ADD FILE ( NAME = N'PartitionTest_1', FILENAME = N'D:\PartitionTest_1.ndf') TO FILEGROUP [FG1]
ALTER DATABASE [PartitionTest] ADD FILE ( NAME = N'PartitionTest_2', FILENAME = N'D:\PartitionTest_2.ndf') TO FILEGROUP [FG2]
ALTER DATABASE [PartitionTest] ADD FILE ( NAME = N'PartitionTest_3', FILENAME = N'D:\PartitionTest_3.ndf') TO FILEGROUP [FG3]
ALTER DATABASE [PartitionTest] ADD FILE ( NAME = N'PartitionTest_4', FILENAME = N'D:\PartitionTest_4.ndf') TO FILEGROUP [FG4]
GO

-- Create partition function
CREATE PARTITION FUNCTION [Orders__Function](datetime) AS RANGE LEFT FOR VALUES 
(N'2012-12-31T23:59:59.997', 
N'2013-03-31T23:59:59.997',
N'2013-06-30T23:59:59.997')
go

-- Create partition Scheme
CREATE PARTITION SCHEME [Orders__Scheme] AS PARTITION [Orders__Function] TO 
([FG1],[FG2],[FG3],[FG4])

-- Create table
CREATE TABLE [dbo].[Orders](
	[OrdDate] [datetime] NOT NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Addr] varchar(100) NOT NULL)
	
-- Partition the table
CREATE UNIQUE CLUSTERED INDEX IX_Orders
ON [Orders](OrdDate asc,ID asc)
ON [Orders__Scheme] (OrdDate);
GO

-- Insert rows into  partitions (partition 4 in this case)
Use PartitionTest
set nocount on
go
declare @i int
set @i = 1
declare @date Datetime
while (@i < 1000)
begin
set @date = dateadd(mi,@i,'2012-11-01T10:17:01.000')
--insert into testtable values (@date)
insert into [Orders] values (@date, 'Denzil')
insert into [Orders] values (dateadd(month,3,@date), 'Denzil')
insert into [Orders] values (dateadd(month,6,@date), 'Denzil')
insert into [Orders] values (dateadd(month,9,@date), 'Denzil')
set @i = @i+1;
end

-- Check the rowcount in each partition
select $PARTITION.[Orders__Function](Orddate) as PartionNum,COUNT(*) as CountRows from  Orders
Group by $PARTITION.[Orders__Function](Orddate)





/******************************************************************************

Step 2: Split as a non-logged operation

******************************************************************************/

-- View Metadata before split
SELECT 
t.name as TableName,
i.name as IndexName,
--i.data_space_id,
p.partition_id as partitionID,
p.partition_number,
rows
, fg.name
FROM sys.tables AS t  
	  INNER JOIN sys.indexes AS i ON (t.object_id = i.object_id)
     INNER JOIN sys.partitions AS p ON (t.object_id = p.object_id and i.index_id = p.index_id) 
	 INNER JOIN sys.destination_data_spaces dds ON (p.partition_number = dds.destination_id) 
	 INNER JOIN sys.filegroups AS fg ON (dds.data_space_id = fg.data_space_id) 
WHERE (t.name = 'Orders') and (i.index_id IN (0,1))


--- We now want to SPLIT a non-empty partition, so preparing for that
-- Add new Filegroup and file
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG5];
ALTER DATABASE [PartitionTest] ADD FILE 
( NAME = N'PartitionTest_5', FILENAME = N'D:\PartitionTest_5.ndf' , SIZE = 3072KB , FILEGROWTH = 1024KB ) 
TO FILEGROUP [FG5]
GO

-- Set the next used partition
Alter partition scheme [Orders__Scheme] NEXT USED [FG5]

---  Traditional Split
-- Clear Records to demonstrate Log records generated
checkpoint
go
-- Select to demonstrate that there are no log records for that table 
select Operation,count(*) as NumLogRecords from fn_dblog(NULL,NULL)
where AllocUnitName= 'dbo.Orders.IX_Orders'
group by Operation
order by count(*) desc



-- Split the non-empty partition
ALTER PARTITION FUNCTION Orders__Function() SPLIT RANGE ('2013-09-30 23:59:59.99')

-- Show how many log records generated, there is data movement Deletes followed by inserts
select Operation,AllocUnitName,count(*) as NumLogRecords from fn_dblog(NULL,NULL)
where AllocUnitName= 'dbo.Orders.IX_Orders'
group by Operation,AllocUnitName
order by count(*) desc




/**********************************************************************************
Rerun Step 1 to recreate the scenario

**********************************************************************************/
/*****************************************************
Step 1: Scenario SETUP
*************************************************/
use master
go
drop database PartitionTest
go
create database PartitionTest
go

use PartitionTest
go

-- Add Filegroups
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG1];
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG2];
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG3];
ALTER DATABASE [PartitionTest] ADD FILEGROUP [FG4];
GO
Alter database PartitionTest set recovery simple
go

-- Add Files
ALTER DATABASE [PartitionTest] ADD FILE 
( NAME = N'PartitionTest_1', FILENAME = N'D:\PartitionTest_1.ndf' , SIZE = 3072KB , FILEGROWTH = 1024KB ) 
TO FILEGROUP [FG1]
ALTER DATABASE [PartitionTest] ADD FILE 
( NAME = N'PartitionTest_2', FILENAME = N'D:\PartitionTest_2.ndf' , SIZE = 3072KB , FILEGROWTH = 1024KB ) 
TO FILEGROUP [FG2]

ALTER DATABASE [PartitionTest] ADD FILE 
( NAME = N'PartitionTest_3', FILENAME = N'D:\PartitionTest_3.ndf' , SIZE = 3072KB , FILEGROWTH = 1024KB ) 
TO FILEGROUP [FG3]

ALTER DATABASE [PartitionTest] ADD FILE 
( NAME = N'PartitionTest_4', FILENAME = N'D:\PartitionTest_4.ndf' , SIZE = 3072KB , FILEGROWTH = 1024KB ) 
TO FILEGROUP [FG4]
GO


-- Create partition function
CREATE PARTITION FUNCTION [Orders__Function](datetime) AS RANGE LEFT FOR VALUES 
(N'2012-12-31T23:59:59.997', 
N'2013-03-31T23:59:59.997',
N'2013-06-30T23:59:59.997')
go

-- Create partition Scheme
CREATE PARTITION SCHEME [Orders__Scheme] AS PARTITION [Orders__Function] TO 
([FG1],[FG2],[FG3],[FG4])


-- Create table
CREATE TABLE [dbo].[Orders](
	[OrdDate] [datetime] NOT NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Addr] varchar(100) NOT NULL)
	
-- Partition the table
CREATE UNIQUE CLUSTERED INDEX IX_Orders
ON [Orders](OrdDate asc,ID asc)
ON [Orders__Scheme] (OrdDate);
GO


-- Insert rows into  partitions (partition 4 in this case)
Use PartitionTest
go
set nocount on
go
declare @i int
set @i = 1
declare @date Datetime
while (@i < 1000)
begin
set @date = dateadd(mi,@i,'2012-11-01T10:17:01.000')
--insert into testtable values (@date)
insert into [Orders] values (@date, 'Denzil')
insert into [Orders] values (dateadd(month,3,@date), 'Denzil')
insert into [Orders] values (dateadd(month,6,@date), 'Denzil')
insert into [Orders] values (dateadd(month,9,@date), 'Denzil')
set @i = @i+1;
end

-- Check the rowcount in each partition
select $PARTITION.[Orders__Function](Orddate) as PartionNum,COUNT(*) as CountRows from  Orders
Group by $PARTITION.[Orders__Function](Orddate)


/*****************************************************************************************
Split a non-empty partition in most efficient way, primarily non-logged
**************************************************************************************/


-- Create a copy table with intent to switch in
CREATE TABLE [dbo].[Orders_Copy](
	[OrdDate] [datetime] NOT NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Addr] varchar(100) NOT NULL)
	
-- Create the clustered index on the copy table on the same filegroup as the partition that we are trying to switch out.
CREATE UNIQUE CLUSTERED INDEX IX_Orders_Copy
ON [Orders_COPY](OrdDate asc,ID asc)
ON [FG4];
GO


	
-- Execute the switch. After this, the last partition should be empty.
ALTER TABLE Orders SWITCH PARTITION 4 TO Orders_Copy; 

-- What happens here is that all the data in partition 4 is now gone to the table Orders_Copy
select count(*)  as NumRows from Orders_copy


-- Check Metadata to get the Partition Number you want to Split
SELECT 
t.name as TableName,
i.name as IndexName,
i.data_space_id,
p.partition_id as partitionID,
p.partition_number,
rows
, fg.name
FROM sys.tables AS t  
	  INNER JOIN sys.indexes AS i ON (t.object_id = i.object_id)
     INNER JOIN sys.partitions AS p ON (t.object_id = p.object_id and i.index_id = p.index_id) 
	 INNER JOIN sys.destination_data_spaces dds ON (p.partition_number = dds.destination_id) 
	 INNER JOIN sys.filegroups AS fg ON (dds.data_space_id = fg.data_space_id) 
WHERE (t.name = 'Orders') and (i.index_id IN (0,1))

-- Mark the  Filegroup used by the last partition as the NEXT USED. This is for the SWITCH to work.
Alter partition scheme [Orders__Scheme]
NEXT USED [FG4]


-- Check Metadata to get the Partition Number you want to Split
SELECT 
t.name as TableName,
i.name as IndexName,
i.data_space_id,
p.partition_id as partitionID,
p.partition_number,
rows
, fg.name
FROM sys.tables AS t  
	  INNER JOIN sys.indexes AS i ON (t.object_id = i.object_id)
     INNER JOIN sys.partitions AS p ON (t.object_id = p.object_id and i.index_id = p.index_id) 
	 INNER JOIN sys.destination_data_spaces dds ON (p.partition_number = dds.destination_id) 
	 INNER JOIN sys.filegroups AS fg ON (dds.data_space_id = fg.data_space_id) 
WHERE (t.name = 'Orders') and (i.index_id IN (0,1))


-- Clear TLog Records
checkpoint
go


-- Split the now partition
ALTER PARTITION FUNCTION Orders__Function() SPLIT RANGE ('2013-09-30 23:59:59.997')


-- Will see no Logged data movement
select Operation,AllocUnitName,count(*) as NumLogRecords from fn_dblog(NULL,NULL)
where AllocUnitName= 'dbo.Orders.IX_Orders'
group by Operation,AllocUnitName
order by count(*) desc


-- Add the necessary check constraints. Otherwise you will see the following error.
--Msg 4982, Level 16, State 1, Line 1
--ALTER TABLE SWITCH statement failed. Check constraints of source table 'PartitionTest.dbo.TransRedemption_Copy' allow values that are not allowed by range defined by partition 4 on target table 'PartitionTest.dbo.TransRedemption'.

ALTER TABLE Orders_Copy ADD CHECK (OrdDate> '2013-06-30T23:59:59.997' and OrdDate <= '2013-09-30 23:59:59.997' );
go
checkpoint
go

-- Switch the partition that we had earlier swapped out to the Test table back.
ALTER TABLE Orders_Copy SWITCH TO Orders PARTITION 4; 
GO

-- Check and will see no logged operations on that table
select Operation,AllocUnitName,count(*) as NumLogRecords from fn_dblog(NULL,NULL)
where AllocUnitName= 'dbo.Orders.IX_Orders'
group by Operation,AllocUnitName
order by count(*) desc

-- Check Metadata
SELECT 
t.name as TableName,
i.name as IndexName,
i.data_space_id,
p.partition_id as partitionID,
p.partition_number,
rows
, fg.name
FROM sys.tables AS t  
	  INNER JOIN sys.indexes AS i ON (t.object_id = i.object_id)
     INNER JOIN sys.partitions AS p ON (t.object_id = p.object_id and i.index_id = p.index_id) 
	 INNER JOIN sys.destination_data_spaces dds ON (p.partition_number = dds.destination_id) 
	 INNER JOIN sys.filegroups AS fg ON (dds.data_space_id = fg.data_space_id) 
WHERE (t.name = 'Orders') and (i.index_id IN (0,1))

