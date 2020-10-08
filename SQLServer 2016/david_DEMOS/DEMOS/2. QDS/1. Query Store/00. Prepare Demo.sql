use [AdventureWorks2014]
go
alter database [AdventureWorks2014] set query_store (interval_length_minutes = 1)
alter database [AdventureWorks2014] set query_store = ON;
go
