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
