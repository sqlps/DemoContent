-- ====================================
-- Step 1) Create XEvent if not present
-- ====================================

CREATE EVENT SESSION [BackupRestore] ON SERVER 
ADD EVENT sqlserver.backup_restore_progress_trace
ADD TARGET package0.event_file(SET filename=N'C:\Temp\BackupREstore.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

-- ====================================
-- Step 2) Start XEvent if not running
-- ====================================
ALTER EVENT SESSION [BackupRestore] ON SERVER
STATE = START
go

-- Watch Live data

-- ====================================
-- Step 3) Run Backup
-- ====================================
BACKUP DATABASE [Adventureworks2014] TO  DISK = N'D:\Data\Adventureworks2014.bak' WITH NOFORMAT, NOINIT,  NAME = N'Adventureworks2014-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- ====================================
-- Step 4) Run Restore
-- ====================================
USE [master]
go
DROP DATABASE IF EXISTS Adventureworks2014_Restore
Go
RESTORE DATABASE [Adventureworks2014_Restore] FROM  DISK = N'D:\Data\Adventureworks2014.bak' WITH  FILE = 1,  
MOVE N'AdventureWorks2012_Data' TO N'D:\DATA\AdventureWorks2014_Restore_Data.mdf', 
MOVE N'AdventureWorks2012_Log' TO N'D:\DATA\Adventureworks2014_Restore_log.ldf',  NOUNLOAD,  STATS = 5
GO


