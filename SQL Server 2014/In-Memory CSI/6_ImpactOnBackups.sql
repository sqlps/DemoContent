------------------------------------------------------------------------------
-- STEP 1: Create the Database												--
------------------------------------------------------------------------------
use master
go

If Exists (Select name from sys.sysdatabases where Name = 'CSI_BackupDemo')
	Drop Database CSI_BackupDemo
GO

CREATE DATABASE [CSI_BackupDemo]
 ON  PRIMARY 
( NAME = N'CSI_BackupDemo', FILENAME = N'D:\DATA\CSI_BackupDemo.mdf' , SIZE = 1024000KB , FILEGROWTH = 512000KB )
 LOG ON 
( NAME = N'CSI_BackupDemo_log', FILENAME = N'D:\LOG\CSI_BackupDemo_log.ldf' , SIZE = 256000KB , FILEGROWTH = 256000KB )
GO

------------------------------------------------------------------------------
-- STEP 2: Populate with Some data											--
------------------------------------------------------------------------------
Select top 1000000 * Into [CSI_BackupDemo]..FactSales
From AdventureWorksDW2008Big..FactSales

------------------------------------------------------------------------------
-- STEP 3: Backup Database As is											--
------------------------------------------------------------------------------
Backup Database [CSI_BackupDemo]
To Disk = 'D:\Backup\CSI_BackupDemo_Original.bak' with  NAME = N'CSI_BackupDemo - No backup compression', NO_COMPRESSION,  FORMAT, INIT
------------------------------------------------------------------------------
-- STEP 4: Backup Database with compression									--
------------------------------------------------------------------------------
Backup Database [CSI_BackupDemo]
To Disk = 'D:\Backup\CSI_BackupDemo_Original_Compressed.bak' With NAME = N'CSI_BackupDemo - backup compression',Compression,  FORMAT, INIT 
------------------------------------------------------------------------------
-- STEP 5: Create CCI														--
------------------------------------------------------------------------------
USE [CSI_BackupDemo]
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_FactSales] ON [dbo].[FactSales] WITH (DROP_EXISTING = OFF)
GO
------------------------------------------------------------------------------
-- STEP 6: Backup Database with CCI											--
------------------------------------------------------------------------------
Backup Database [CSI_BackupDemo]
To Disk = 'D:\Backup\CSI_BackupDemo_CCI_NoCompression.bak' with  NAME = N'CSI_BackupDemo - CCI and No backup compression', NO_COMPRESSION,  FORMAT, INIT
------------------------------------------------------------------------------
-- STEP 7: Backup Database with CCI and Compression							--
------------------------------------------------------------------------------
Backup Database [CSI_BackupDemo]
To Disk = 'D:\Backup\CSI_BackupDemo_CCI_Compressed.bak' With NAME = N'CSI_BackupDemo - CCI and backup compression', Compression,  FORMAT, INIT 
------------------------------------------------------------------------------
-- STEP 8: Grab performance metrics											--
------------------------------------------------------------------------------

SELECT  top 4 Database_name, Name, backup_size/(1024*1024)'Backup_Size_MB', compressed_backup_size/(1024*1024)'Compressed_Backup_Size_MB', ((backup_size - compressed_backup_size)/backup_size)*100 '% Compression', DateDiff(ss,backup_start_date,backup_finish_date) as 'duration (s)'
FROM msdb..backupset
Where database_Name = 'CSI_BackupDemo' 
order by backup_start_date desc

