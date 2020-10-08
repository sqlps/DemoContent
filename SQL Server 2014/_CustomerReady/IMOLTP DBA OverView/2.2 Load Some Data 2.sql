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
