/* This Sample Code is provided for the purpose of illustration only and is not intended 
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE 
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR 
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You 
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or 
result from the use or distribution of the Sample Code.
*/

/*******************************
 ****		OVERVIEW		****
 *******************************/

/*
CREATE STATISTICS stat ON tbl (col1, col2)
    with INCREMENTAL = ON

UPDATE STATISTICS tbl (stat)
    with RESAMPLE ON PARTITIONS (1, 3, 5)

UPDATE STATISTICS tbl (stat)
    with INCREMENTAL = { ON | OFF }

ALTER DATABASE db
    SET AUTO_CREATE_STATISTICS ON  INCREMENTAL = { ON | OFF }

---- Threshold for auto stats update and query recompile
--To update global			: 500 + 20% of average partition size
--To update per-partition	: 20% data change in a partition

*/
/*******************************
 ****		START SETUP		****
 *******************************/

Use Master
Go
IF DB_ID('SlidingWindow') IS NOT NULL
	Drop Database SlidingWindow
GO

Create Database SlidingWindow
Go

Use [SlidingWindow]
GO

--CREATE PF by Month from 2010101 - 20140101 about 50 Partitions
DECLARE @DatePF nvarchar(max) = N'CREATE PARTITION FUNCTION DatePF(DateTime2) AS RANGE LEFT FOR VALUES('
DECLARE @i datetime2 = '20100101'
While @i < '20140101'
BEGIN
	SET @DatePF +=''''+CAST(@i as nvarchar(10))+ '''' +N', '
	SET @i = DATEADD (MM, 1, @i)
END
SET @DatePF += '''' +CAST(@i AS nvarchar(10)) + '''' + N')'
EXEC sp_executesql @DatePF
GO
--CREATE PS
CREATE PARTITION SCHEME DatePS
AS PARTITION DatePF
ALL TO ([Primary])
GO

--Create Partitioned Table
CREATE TABLE LineItem(shipdate DATETIME2(7), data FLOAT)
ON DatePS(ShipDate)
GO
--Populate the table
DECLARE @i datetime2 = '20100101'
While @i < '20140101'
BEGIN
	INSERT INTO LineItem Values (@i, Round(RAND(),2))
	Set @i = DATEADD (hh,1,@i)
END
GO
/*******************************
 ****		END SETUP		****
 *******************************/

--Maunally create fullscan stats with INCREMENTAL=ON
CREATE STATISTICS Stats_Incremental ON LineItem(Data) WITH Incremental =ON, FULLSCAN
GO

--QUERY Internal DMF to see the per-partition stats
Select * from sys.dm_db_stats_properties_internal(OBJECT_ID('[LineItem]'),2) --ObjectID, StatsID
Where First_child = 0 --Means Leaf Node i.e only the individual partitions and not tine intermediate
ORDER BY left_boundary
GO

Select * from sys.stats
where object_id = object_id('[LineItem]')
GO

--Split the last partition so we will still have an empty partition at the end 
ALTER PARTITION SCHEME DATEPS
NEXT USED [PRIMARY]
ALTER PARTITION FUNCTION DatePF()
SPLIT RANGE ('20140201')
GO

--Populate Staging table
Create Table stagingTable(ShipDate Datetime2(7), Data float) ON DatePS(ShipDate)
GO

DECLARE @i datetime2 = '20140101'
While @i < '20140201'
BEGIN
	Insert into stagingTable Values (@i, ROUND(RAND(),2))
	Set @i = DateADD(hh,1,@i)
END
GO

--Switch staging data into new partition
ALTER TABLE StagingTable Switch PARTITION 50 to LineItem PARTITION 50
GO

--Validate we now see data in Partition 50
Select * from LineItem Where $Partition.DatePF(shipdate)=50
GO

--Trigger an auto stats update with the following query
Select * FROM LineItem where Data !=0.1
GO

--Query the root
Select * from sys.dm_db_stats_properties_internal(OBJECT_ID('[LineItem]'),2) --ObjectID, StatsID
Where node_id = 1
GO

--Query DMF again to see per-partition stats
Select * from sys.dm_db_stats_properties_internal(OBJECT_ID('[LineItem]'),2) --ObjectID, StatsID
Where First_child = 0 
ORDER BY left_boundary
GO

--If you wanted to see all the nodes of the tree that needed to be updatedd as a result of the swtich in 
Select * from sys.dm_db_stats_properties_internal(OBJECT_ID('[LineItem]'),2) --ObjectID, StatsID
Where last_updated > '2014-10-21 10:45' -- Update with the time from the root last_updated

--To Complete sliding window, merge the two "oldest" partitions
ALTER PARTITION SCHEME DatePS
NEXT Used [Primary]
ALTER PARTITION FUNCTION DatePF()
Merge RANGE ('2010-01-01')
GO

--Since this was a simple MetaData update, we would not expect to see this trigger an update stats
Select * from sys.dm_db_stats_properties_internal(OBJECT_ID('[LineItem]'),2) --ObjectID, StatsID
Where node_id = 1
GO

--Since no data change this query should not trigger a update stats
Select * FROM LineItem where Data !=0.1
GO



/*
Select * from sys.dm_db_stats_properties_internal(OBJECT_ID('[LineItem]'),2) --ObjectID, StatsID
Where node_id = 1
GO

-- Notice that we have 51 rows even after the merge as it will not immediately since we do Lazy Updates.
-- Gets updated next time update stats occur
Select * from sys.dm_db_stats_properties_internal(OBJECT_ID('[LineItem]'),2) --ObjectID, StatsID
Where First_child = 0 
ORDER BY left_boundary
GO

--Maually update stats
UPDATE STATISTICS LineItem(Stats_Incremental) with resample on partitions(50)

-- Back to 50
Select * from sys.dm_db_stats_properties_internal(OBJECT_ID('[LineItem]'),2) --ObjectID, StatsID
Where First_child = 0 
ORDER BY left_boundary
GO
*/