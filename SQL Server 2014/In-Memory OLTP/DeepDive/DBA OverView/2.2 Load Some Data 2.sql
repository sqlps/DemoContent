--Let's load some data
--Adhoc Insert of 1M rows takes about 60 seconds
Use IMOLTP_Demo
GO
exec dbo.InsertRecords_Standard 1000000
Go

Select Count(*) from IMOLTP_Tbl1

Truncate Table dbo.IMOLTP_Tbl1
--Delete from dbo.IMOLTP_Tbl1
GO

exec dbo.InsertRecords 1000000
Go

-- memory usage
Select * from sys.dm_db_xtp_hash_index_stats 
GO

select object_name(object_id) as 'Object name', memory_used_by_table_kb,memory_used_by_indexes_kb
from sys.dm_db_xtp_table_memory_stats 
where object_id = object_id('IMOLTP_Tbl1')


-- show memory usage report in SSMS as well
