--First need to add a filegroup and file for in-memory tables
--if not you will get:
----Msg 41337, Level 16, State 100, Line 1
----Cannot create memory optimized tables in a database that does not have an online and non-empty MEMORY_OPTIMIZED_DATA filegroup.

USE [MyDemoDB]
GO
ALTER DATABASE MyDemoDB ADD FILEGROUP IMOLTP_mod CONTAINS MEMORY_OPTIMIZED_DATA
ALTER DATABASE MyDemoDB ADD FILE( NAME = 'IMOLTP_mod' , FILENAME = 'D:\Data\MyDemoDB_mod') TO FILEGROUP IMOLTP_mod;
GO

Use MyDemoDB
GO

Select name,collation_name from sys.databases
where name = 'MyDemoDB'

--Try creating without collation

CREATE TABLE Employees (
  EmployeeID int NOT NULL , 
  LastName nvarchar(20) NOT NULL INDEX IX_LastName NONCLUSTERED, 
  --LastName nvarchar(20) COLLATE Latin1_General_100_BIN2 NOT NULL INDEX IX_LastName NONCLUSTERED, 
  FirstName nvarchar(10) NOT NULL ,
  CONSTRAINT PK_Employees PRIMARY KEY NONCLUSTERED HASH(EmployeeID)  WITH (BUCKET_COUNT=1024)
) WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA)
GO

DROP Table Employees
