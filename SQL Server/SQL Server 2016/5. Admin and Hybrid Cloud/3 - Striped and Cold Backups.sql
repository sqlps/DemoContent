-- ===================================
-- NOTES
-- ===================================
-- Reference: https://msdn.microsoft.com/en-us/library/dn435916.aspx
-- Striped backups only supported by block blobs. Block blobs support a max of 200GB, Page max is 1 TB but cannot strip
-- Cool storage only supports page blobs (as of 05/26/2016)

-- ===================================
-- Step 1) Create Credentials
-- ===================================
-- Regular
CREATE Credential [https://pankajtsp.blob.core.windows.net/sqlbackups] 
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = 'sv=2014-02-14&sr=c&sig=JZUBTZVquYydWqoOLvu81T7SlcmyaTt1AKNxUzTpNAQ%3D&st=2016-05-25T04%3A00%3A00Z&se=2026-06-02T04%3A00%3A00Z&sp=rwdl'
GO

-- Cold storage
CREATE Credential [https://pankajcold.blob.core.windows.net/sqlbackuparchive] 
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = 'sv=2014-02-14&sr=c&sig=razP4M47liz7b5M%2F1mXMS1YLk8V%2FTe1jtAVxR26UIek%3D&st=2016-05-26T04%3A00%3A00Z&se=2026-06-03T04%3A00%3A00Z&sp=rwdl'
GO
--Validate
select * from sys.credentials

-- ===================================
-- Step 2) Backup with no stripe
-- ===================================
--AdventureworksDW2016CTP3 is ~ 1.5GB
Backup Database AdventureworksDW2016CTP3 TO
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2016CTP3.bak' with INIT, compression, FORMAT
-- BACKUP DATABASE successfully processed 186706 pages in 31.266 seconds (46.652 MB/sec).

-- ======================================================
-- Step 3) Backup to regular storage account, but stripe
-- ======================================================
Backup Database AdventureworksDW2016CTP3 TO
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2016CTP3_1.bak', 
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2016CTP3_2.bak',
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2016CTP3_3.bak',
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2016CTP3_4.bak'
with INIT, compression, FORMAT
-- BACKUP DATABASE successfully processed 186706 pages in 27.952 seconds (52.183 MB/sec)

-- ======================================================
-- Step 4) Backup to Cool blob storage account and stripe
-- ======================================================
--Attempt to do a single file. 
Backup Database AdventureworksDW2016CTP3 TO
URL = N'https://pankajcold.blob.core.windows.net/sqlbackuparchive/AdventureworksDW2016CTP3.bak'
-- BACKUP DATABASE successfully processed 186706 pages in 23.436 seconds (62.239 MB/sec).

--Ok let's stripe it. 

Backup Database AdventureworksDW2016CTP3 TO
URL = N'https://pankajcold.blob.core.windows.net/sqlbackuparchive/AdventureworksDW2016CTP3_1.bak', 
URL = N'https://pankajcold.blob.core.windows.net/sqlbackuparchive/AdventureworksDW2016CTP3_2.bak',
URL = N'https://pankajcold.blob.core.windows.net/sqlbackuparchive/AdventureworksDW2016CTP3_3.bak',
URL = N'https://pankajcold.blob.core.windows.net/sqlbackuparchive/AdventureworksDW2016CTP3_4.bak'
with INIT, compression, FORMAT
-- BACKUP DATABASE successfully processed 186706 pages in 20.297 seconds (71.864 MB/sec).
