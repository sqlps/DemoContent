--Let's load some data
--Adhoc Insert of 1M rows takes about 60 seconds

exec dbo.InsertRecords_Standard 1000000
Go

Select Count(*) from InsertRecords_Standard

Delete from dbo.IMOLTP_Tbl1
GO

exec dbo.InsertRecords 1000000
Go
