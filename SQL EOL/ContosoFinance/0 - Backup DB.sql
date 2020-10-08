-- =======================================================
-- Step 1) Backup Database to drop location monitored by 
-- MS SQL Server Backup to Azure Tool
-- =======================================================
BACKUP DATABASE [ContosoFinance] TO  DISK = N'C:\SQL\Backup\ContosoFinance.bak'
WITH NOFORMAT, NOINIT,  NAME = N'ContosoFinance-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
select @@version