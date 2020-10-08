-- See: https://msdn.microsoft.com/en-us/library/dn589807.aspx for logic behind how many delta stores are created

-----------------
-- START SETUP --
-----------------
Use master
go

If Exists(Select name from sys.databases where name = 'IMOLTP_DEMO')
Begin
	ALTER DATABASE IMOLTP_DEMO SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	Drop Database IMOLTP_DEMO
End

--Restore from Azure Blob Store

USE [master]
RESTORE DATABASE [IMOLTP_DEMO] FROM  URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/Imoltp_Demo.bak' 
WITH  CREDENTIAL = N'BackuptoURL' ,  FILE = 1,  NOUNLOAD,  STATS = 5
GO

USE IMOLTP_DEMO
GO

 -- Table definition
CREATE TABLE CCITest ( 
    CustomerNo    INT, 
    Firstname   Char(50) NOT NULL, 
    Lastname    CHAR(50) NOT NULL)
GO
 
-- Creating our Clustered Columnstore Index
create clustered columnstore index CCL_CCITest
	on dbo.CCITest;
GO


---------------
-- END SETUP --
---------------

--Load 100K record inIn-Mem OLTP Table
exec dbo.InsertRecords 100000
Go 

Insert CCITest
Select CustomerNo, FirstName, LastName from IMOLTP_Tbl1
GO 10

Delete  from IMOLTP_Tbl1

exec dbo.InsertRecords 48576
Go 

Insert CCITest
Select CustomerNo, FirstName, LastName from IMOLTP_Tbl1
go

select *
	from sys.column_store_row_groups

--What's the size uncompressed
sp_spaceUsed 'CCITest'

--Here comes the tipping point
Delete  from IMOLTP_Tbl1

exec dbo.InsertRecords 1
Go 

Insert CCITest
Select CustomerNo, FirstName, LastName from IMOLTP_Tbl1
go

select *
	from sys.column_store_row_groups

exec sp_spaceUsed 'CCITest'
--If closed we now need to wait for the Tuple move

alter INDEX CCL_CCITest ON dbo.CCITest
REORGANIZE
GO 2 --Doing 2 passes since the first time it compresses and then a second time to remove the old row store

select *
	from sys.column_store_row_groups

sp_spaceUsed 'CCITest'
	
--Take a look at the stats
-- See: http://social.technet.microsoft.com/wiki/contents/articles/7404.using-statistics-with-columnstore-indexes.aspx for CSI stat recommendations
SELECT sch.name + '.' + so.name AS 'Table', ss.name AS 'Statistic', 
	CASE
		WHEN ss.auto_Created = 0 AND ss.user_created = 0 THEN 'Index Statistic'
		WHEN ss.auto_created = 0 AND ss.user_created = 1 THEN 'User Created'
		WHEN ss.auto_created = 1 AND ss.user_created = 0 THEN 'Auto Created'
		WHEN ss.AUTO_created = 1 AND ss.user_created = 1 THEN 'Not Possible?'
	END AS 'Statistic Type',
	CASE
		WHEN ss.has_filter = 1 THEN 'Filtered Index'
		WHEN ss.has_filter = 0 THEN 'No Filter'
	END AS 'Filtered?', 
	CASE
		WHEN ss.filter_definition IS NULL THEN ''
		WHEN ss.filter_definition IS NOT NULL THEN ss.filter_definition
	END AS 'Filter Definition', 
	sp.last_updated AS 'Stats Last Updated', sp.rows AS 'Rows', sp.rows_sampled AS 'Rows Sampled', Cast((sp.rows_sampled/(sp.rows*1.00))*100.0 AS numeric (5,2)) AS '%Sample',
	sp.unfiltered_rows AS 'Unfiltered Rows', sp.modification_counter AS 'Row Modifications',
	sp.steps AS 'Histogram Steps'
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp 
WHERE so.name = 'CCITest'
ORDER BY sp.last_updated
DESC;
