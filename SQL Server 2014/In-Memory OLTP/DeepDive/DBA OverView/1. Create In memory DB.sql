/******************
 * TALKING POINTS *
 ******************
 1) In-Memory OLTP FileGroup – notice no file specified. In-Memory OLTP will generate the files in this folder.
 2) Point out the new Memory Allocated and Memory Used Fields on the General Page of a DB Object
 3) NOTE: Indexes can only be created on string columns if they use a BIN2 collation. 
    Reference: http://msdn.microsoft.com/en-us/library/dn133182.aspx */

USE master
GO
SET NOCOUNT ON
GO

if exists (select * from sys.databases where name='IMOLTP_Demo')
BEGIN
	ALTER DATABASE IMOLTP_Demo Set Single_User WITH Rollback Immediate
	drop database IMOLTP_Demo
End
go

CREATE DATABASE [IMOLTP_DEMO]
 ON  PRIMARY 
( NAME = N'IMOLTP_DEMO', FILENAME = N'D:\DATA\IMOLTP_DEMO.mdf' , SIZE = 4096KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'IMOLTP_DEMO_log', FILENAME = N'D:\LOG\IMOLTP_DEMO_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO

----- Enable database for memory optimized tables by adding memory_optimized_data filegroup
ALTER DATABASE IMOLTP_Demo 
    ADD FILEGROUP IMOLTP_Demo_mod CONTAINS MEMORY_OPTIMIZED_DATA
GO

-- add container to the filegroup
ALTER DATABASE IMOLTP_Demo 
ADD FILE (NAME='IMOLTP_Demo_mod', FILENAME='D:\DATA\IMOLTP_Demo_mod') 
TO FILEGROUP IMOLTP_Demo_mod
GO

Select DB_ID('IMOLTP_Demo')