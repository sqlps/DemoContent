--Reference: http://blogs.technet.com/b/dataplatforminsider/archive/2013/11/12/sql-server-2014-in-memory-oltp-nonclustered-indexes-for-memory-optimized-tables.aspx

Use IMOLTP_Demo
Go

--Exact match to key of Hash index: Seek 
Select  * from IMOLTP_Tbl1
Where CustomerNo = 904762
Go

--Range scans on key of Hash index: Table Scan. Won't use Hash Index 
Select * from IMOLTP_Tbl1
Where CustomerNo between 904762 and 904770
Go

--Exact match on NC in memory index: Seek
Select * from IMOLTP_Tbl1
Where OrderDate = '2012-12-16'
Go

--Range scans also suited fro NC indexes

--Exact match on NC in memory index: Seek
Select * from IMOLTP_Tbl1
Where OrderDate Between '2012-12-16' and '2012-12-17'
Go