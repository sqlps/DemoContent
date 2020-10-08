-- ============================================================================================================
-- Step 0) What snapshots do I have?
-- ============================================================================================================
use Master
Go
select * from sys.fn_db_backup_file_snapshots ('AdventureworksDW_Azure') ;  
GO  

-- Cleanup backups
Select 'exec sys.sp_delete_backup_file_snapshot N''AdventureworksDW_Azure'', N'''+snapshot_url+''';'
From sys.fn_db_backup_file_snapshots ('AdventureworksDW_Azure') ;  
GO  

-- ============================================================================================================
-- Step 1) To initiate need a full backup of the database with file_snapshot option 
-- ============================================================================================================
BACKUP DATABASE AdventureworksDW_Azure
TO URL = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure.bak',
  URL = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure.bak'
With compression, FORMAT, STATS = 10
GO

/*
Processed 545584 pages for database 'AdventureworksDW_Azure', file 'AdventureworksDW2008_Data' on file 1.
Processed 1 pages for database 'AdventureworksDW_Azure', file 'AdventureworksDW2008_log' on file 1.
BACKUP DATABASE successfully processed 545585 pages in 73.123 seconds (58.290 MB/sec).
*/

BACKUP DATABASE AdventureworksDW_Azure 
TO URL = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_AzureSnapTest20.bak' 
with File_Snapshot, STATS = 10
GO


-- ============================================================================================================
-- Step 2) What are the top tables
-- ============================================================================================================
Use AdventureworksDW_Azure
go

SELECT top 5 t.NAME AS TableName,i.name as indexName,sum(p.rows) as RowCounts,sum(a.total_pages) as TotalPages, sum(a.used_pages) as UsedPages, sum(a.data_pages) as DataPages,(sum(a.total_pages) * 8) / 1024 as TotalSpaceMB, (sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, (sum(a.data_pages) * 8) / 1024 as DataSpaceMB
FROM sys.tables t INNER JOIN  sys.indexes i ON t.OBJECT_ID = i.object_id INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.NAME NOT LIKE 'dt%' AND i.OBJECT_ID > 255 AND i.index_id <= 1
GROUP BY t.NAME, i.object_id, i.index_id, i.name 
ORDER BY 9 desc
-- ============================================================================================================
-- Step 3) take a snapshot backup and record the LogFilename
-- ============================================================================================================

DECLARE @Log_Filename AS VARCHAR (300);
SET @Log_Filename = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_'+ 
REPLACE (REPLACE (REPLACE (CONVERT (VARCHAR (40), GETDATE (), 120), '-','_'),':', '_'),' ', '_') + '.trn';

BACKUP LOG AdventureworksDW_Azure
 TO URL = @Log_Filename WITH FILE_SNAPSHOT;
Print @Log_FileName
go
-- AdventureworksDW_Azure_Log_2019_03_08_11_31_56.trn
-- ============================================================================================================
-- Step 4) Record the current time
-- ============================================================================================================
select getdate()

--2019-03-08 11:32:10.850

-- ============================================================================================================
-- Step 5) Be Malicious
-- ============================================================================================================
Use AdventureworksDW_Azure
Go

Drop Table FactResellerSales
Drop Table FactResellerSales_NCCI
GO

Select top 10 * from FactResellerSales
go

-- ============================================================================================================
-- Step 6) Take another snapshot backup and record log name
-- ============================================================================================================

-- Back up the AdventureWorks2016 log using a time stamp in the backup file name.
DECLARE @Log_Filename AS VARCHAR (300);
SET @Log_Filename = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_'+ 
REPLACE (REPLACE (REPLACE (CONVERT (VARCHAR (40), GETDATE (), 120), '-','_'),':', '_'),' ', '_') + '.trn'

BACKUP LOG AdventureworksDW_Azure
 TO URL = @Log_Filename WITH FILE_SNAPSHOT;

Print @Log_Filename
--
go

https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_2019_03_08_11_33_15.trn
-- ============================================================================================================
-- Step 7) Recover to point in time
-- ============================================================================================================
Use Master
Go
RESTORE DATABASE AdventureworksDW_Azure1
FROM URL = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_2019_03_08_11_31_56.trn' 
WITH RECOVERY, REPLACE
,STOPAT = '2019-03-08 11:32:10.850';
Restore Database AdventureworksDW_Azure with recovery
GO

/*
RESTORE DATABASE AdventureworksDW_Azure1
FROM URL = 'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_AzureSnapTest20.bak' 
WITH RECOVERY, REPLACE
*/

-- ============================================================================================================
-- Step 8) Validate I can see data
-- ============================================================================================================
use AdventureworksDW_Azure
Go
Select top 10 * from FactResellerSales