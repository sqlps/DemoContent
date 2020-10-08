/******************
 * TALKING POINTS *
 ******************
 1) In-Memory OLTP FileGroup – notice no file specified. In-Memory OLTP will generate the files in this folder.
 2) Collation – has to be a non-SQL (Windows) Bin2 collation for In-Memory OLTP.
 3) Point out the new Memory Allocated and Memory Used Fields on the General Page of a DB Object*/

If Exists (Select name from sys.databases where name = 'IMOLTP_DEMO')
	DROP Database IMOLTP_DEMO
GO
CREATE DATABASE [IMOLTP_Demo]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'IMOLTP_Demo', FILENAME = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\IMOLTP_Demo.mdf' , SIZE = 1024MB , FILEGROWTH = 256MB ),

FILEGROUP [IMOLTP_Mem] CONTAINS MEMORY_OPTIMIZED_DATA 
(NAME = [IMOLTP_MemData], FILENAME = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\IMOLTP_Demo_MOD_dir')
 LOG ON 
( NAME = N'IMOLTP_Demo_log', FILENAME = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\IMOLTP_Demo_log.ldf' , SIZE = 256MB , FILEGROWTH = 64MB )
COLLATE Latin1_General_100_BIN2;

Select DB_ID('IMOLTP_Demo')