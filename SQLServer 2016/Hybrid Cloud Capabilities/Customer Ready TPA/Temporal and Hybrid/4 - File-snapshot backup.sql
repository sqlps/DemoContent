/* This Sample Code is provided for the purpose of illustration only and is not intended 
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE 
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR 
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You 
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or 
result from the use or distribution of the Sample Code.
*/

-- ============================================================================================================
-- Step 1) To initiate need a full backup of the database with file_snapshot option 
-- ============================================================================================================
BACKUP DATABASE AdventureworksDW_Azure
TO URL = 'https://StorageAccount.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure.bak' 
with compression, FORMAT, STATS = 10
GO

/*
Processed 545584 pages for database 'AdventureworksDW_Azure', file 'AdventureworksDW2008_Data' on file 1.
Processed 1 pages for database 'AdventureworksDW_Azure', file 'AdventureworksDW2008_log' on file 1.
BACKUP DATABASE successfully processed 545585 pages in 73.123 seconds (58.290 MB/sec).
*/

BACKUP DATABASE AdventureworksDW_Azure 
TO URL = 'https://StorageAccount.blob.core.windows.net/sqlbackups/AdventureworksDW2008_AzureSnapTest1.bak' 
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
SET @Log_Filename = 'https://StorageAccount.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_'+ 
REPLACE (REPLACE (REPLACE (CONVERT (VARCHAR (40), GETDATE (), 120), '-','_'),':', '_'),' ', '_') + '.trn';

BACKUP LOG AdventureworksDW_Azure
 TO URL = @Log_Filename WITH FILE_SNAPSHOT;
Print @Log_FileName
go
-- AdventureworksDW_Azure_Log_2016_06_23_01_54_23.trn
-- ============================================================================================================
-- Step 4) Record the current time
-- ============================================================================================================
select getdate()

--2016-06-23 01:54:47.510

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


-- OMG


-- ============================================================================================================
-- Step 6) Take another snapshot backup and record log name
-- ============================================================================================================

-- Back up the AdventureWorks2016 log using a time stamp in the backup file name.
DECLARE @Log_Filename AS VARCHAR (300);
SET @Log_Filename = 'https://StorageAccount.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_'+ 
REPLACE (REPLACE (REPLACE (CONVERT (VARCHAR (40), GETDATE (), 120), '-','_'),':', '_'),' ', '_') + '.trn'

BACKUP LOG AdventureworksDW_Azure
 TO URL = @Log_Filename WITH FILE_SNAPSHOT;

Print @Log_Filename
--
go
-- ============================================================================================================
-- Step 7) Recover to point in time
-- ============================================================================================================
Use Master
Go
RESTORE DATABASE AdventureworksDW_Azure
FROM URL = 'https://StorageAccount.blob.core.windows.net/sqlbackups/AdventureworksDW_Azure_Log_2016_06_23_01_54_23.trn' 
WITH RECOVERY, REPLACE, Stats = 5
,STOPAT = '2016-06-23 01:54:47.510';
Restore Database AdventureworksDW_Azure with recovery
GO
/*
RESTORE DATABASE AdventureworksDW_Azure
FROM URL = 'https://StorageAccount.blob.core.windows.net/sqlbackups/AdventureworksDW2008_AzureSnapTest2.bak' 
WITH RECOVERY, credential = 'BackuptoUrl', REPLACE
*/


-- ============================================================================================================
-- Step 8) Validate I can see data
-- ============================================================================================================
use AdventureworksDW_Azure
Go
Select top 10 * from FactResellerSales