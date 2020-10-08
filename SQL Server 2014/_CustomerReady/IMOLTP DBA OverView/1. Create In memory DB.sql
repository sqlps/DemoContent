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
drop database IMOLTP_Demo
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