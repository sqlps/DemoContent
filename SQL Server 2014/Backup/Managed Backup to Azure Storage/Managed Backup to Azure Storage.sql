-- Simple Test of Automatic Backup to Azure Storage

-- 0. Pre-demo
-- Create a container called backup
-- Download AdventureWorks database from sample database site http://msftdbprodsamples.codeplex.com/releases/view/55330 
-- Make sure you start SQL Server with a trace flag -T10100 and recovery model is Full

-- 1. Create Credential
CREATE CREDENTIAL mycredential 
WITH IDENTITY= '<insert your Azure storage name here>'
, SECRET = '<insert your Azure storage secret key here>'
GO

-- 2. Enable Smart Backup
USE msdb
GO

EXEC smart_admin.sp_set_db_backup
	@database_name='AdventureWorks',
	@storage_url= 'https://<Your Azure storage URL>/',
	@retention_days=30,
	@credential_name='mycredential',
	@enable_backup=1,
	@encryption_algorithm=NO_ENCRYPTION
GO

-- 3. Show backup event log
EXEC smart_admin.sp_get_backup_diagnostics
GO

-- 4. Turn off or disable Smart Backup
EXEC smart_admin.sp_set_db_backup
	@database_name='AdventureWorks',
	@storage_url= 'https://<Your Azure storage URL>/',
	@retention_days=30,
	@credential_name='mycredential',
	@enable_backup=0,
	@encryption_algorithm=NO_ENCRYPTION
GO

-- 6. Use master switch
EXEC smart_admin.sp_backup_master_switch @new_state=0 -- disable
EXEC smart_admin.sp_backup_master_switch @new_state=1 -- enable

-- 7. Cleanup 
USE master
GO
DROP CREDENTIAL mycredential
GO

