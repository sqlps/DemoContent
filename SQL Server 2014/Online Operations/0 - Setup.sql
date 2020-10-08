-- Step 0 - restore ADWorks database, copy ADWorks.bak into your backup directory
USE [master]
RESTORE DATABASE [AdventureWorks] FROM  
DISK = N'D:\Backup\ADWorks.bak' WITH  FILE = 1,  
MOVE N'AdventureWorks2008R2_Data' TO N'D:\DATA\AdventureWorks2008R2_Data.mdf',  MOVE N'AdventureWorks2008R2_Log' TO N'D:\Log\AdventureWorks2008R2_Log.ldf',  NOUNLOAD,  STATS = 5

GO
