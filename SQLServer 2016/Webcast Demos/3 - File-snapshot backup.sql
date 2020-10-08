-- ============================================================================================================
-- Step 1) To initiate need a full backup of the database with file_snapshot option 
-- ============================================================================================================
BACKUP DATABASE AdventureworksDW_Azure 
TO URL = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure.bak' 
with credential = 'Backuptourl', compression
GO
/*
Processed 545584 pages for database 'AdventureworksDW_Azure', file 'AdventureworksDW2008_Data' on file 1.
Processed 1 pages for database 'AdventureworksDW_Azure', file 'AdventureworksDW2008_log' on file 1.
BACKUP DATABASE successfully processed 545585 pages in 73.123 seconds (58.290 MB/sec).
*/

BACKUP DATABASE AdventureworksDW_Azure 
TO URL = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_AzureSnapTest.bak' 
with credential = 'Backuptourl', File_Snapshot
GO


-- ============================================================================================================
-- Step 2) Look at "Disk Usage by Top Tables" report for AdventureworksDW_Azure
-- ============================================================================================================

-- ============================================================================================================
-- Step 3) take a snapshot backup
-- ============================================================================================================

DECLARE @Log_Filename AS VARCHAR (300);
SET @Log_Filename = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_'+ 
REPLACE (REPLACE (REPLACE (CONVERT (VARCHAR (40), GETDATE (), 120), '-','_'),':', '_'),' ', '_') + '.trn';
Print @Log_FileName
BACKUP LOG AdventureworksDW_Azure
 TO URL = @Log_Filename WITH FILE_SNAPSHOT, credential = 'backuptourl';
GO

-- ============================================================================================================
-- Step 4) Record the current time
-- ============================================================================================================
select getdate()

--2016-03-01 12:52:26.770

-- ============================================================================================================
-- Step 5) Be Malicious
-- ============================================================================================================
Use AdventureworksDW_Azure
Go

Drop Table FactResellerSales
Drop Table FactResellerSales_CCI
Drop Table FactResellerSales_NCCI
GO

Select top 10 * from FactResellerSales
go

-- ============================================================================================================
-- Step 6) Take another snapshot backup
-- ============================================================================================================

-- Back up the AdventureWorks2016 log using a time stamp in the backup file name.
DECLARE @Log_Filename AS VARCHAR (300);
SET @Log_Filename = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_'+ 
REPLACE (REPLACE (REPLACE (CONVERT (VARCHAR (40), GETDATE (), 120), '-','_'),':', '_'),' ', '_') + '.trn'
Print @Log_Filename
BACKUP LOG AdventureworksDW_Azure
 TO URL = @Log_Filename WITH FILE_SNAPSHOT, credential = 'BackuptoUrl';
GO
-- ============================================================================================================
-- Step 7) Recover to point in time
-- ============================================================================================================
Use Master
Go
RESTORE DATABASE AdventureworksDW_Azure
FROM URL = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_2016_03_01_12_51_17.trn' 
WITH RECOVERY,REPLACE,STOPAT = '2016-03-01 12:51:26', credential = 'BackuptoUrl';
GO

Restore Database AdventureworksDW_Azure with recovery

-- ============================================================================================================
-- Step 8) Validate I can see data
-- ============================================================================================================
use AdventureworksDW_Azure
Go
Select top 10 * from FactResellerSales