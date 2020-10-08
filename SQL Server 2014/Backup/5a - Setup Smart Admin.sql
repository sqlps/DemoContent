/****************************************************/
/* Important Notes:                                 */
/* 1) Smart_Admin only supports DB in full recovery */
/* 2) You can enable at DB or Instance              */
/* RULES:
   Full: 
	- Initial Configuration
	- The log growth since last full database backup is equal to or larger than 1 GB.
	- The maximum time interval of one week has passed since the last full database backup.
	- The log chain is broken. 
	Log:
	- No Log backup history found
	- The transaction log space used is 5 MB or larger.
	- The maximum time interval of 2 hours since the last log backup is reached.
	- Any time the transaction log backup is lagging behind a full database backup. The goal is to keep the log chain ahead of full backup.
*/
/* Resources:
http://blogs.technet.com/b/dataplatforminsider/archive/2013/10/24/backup-and-restore-enhancements-in-sql-server-2014-ctp2.aspx
--How to Monitor Smart Backups see: 
http://msdn.microsoft.com/en-us/library/dn449498.aspx
http://msdn.microsoft.com/en-us/library/dn449491.aspx
*/

-- 1. Create Credential
CREATE CREDENTIAL mycredential 
WITH IDENTITY= '<insert your Azure storage name here>'
, SECRET = '<insert your Azure storage secret key here>'
GO

-- Alternatively you can do this from the GUI under Management->Managed Backup. 

-- 2. Enable Smart Backup
USE msdb
GO

EXEC smart_admin.sp_set_db_backup
	@database_name='MyDemoDB',
	@storage_url= 'https://pankajtsp.blob.core.windows.net',
	@retention_days=7,
	@credential_name='BackuptoURL',
	@enable_backup=1,
	@encryption_algorithm=NO_ENCRYPTION
GO

-- 3. Show backup event log
EXEC smart_admin.sp_get_backup_diagnostics
GO

-- 4. Turn off or disable Smart Backup
EXEC smart_admin.sp_set_db_backup
	@database_name='MyDemoDB',
	@storage_url= 'https://pankajtsp.blob.core.windows.net',
	@retention_days=7,
	@credential_name='BackuptoURL',
	@enable_backup=0,
	@encryption_algorithm=NO_ENCRYPTION
GO

-- 6. Use master switch
-- Reference: http://msdn.microsoft.com/en-us/library/dn451010.aspx
-- Pauses and Resumes Backup to Windows Azure
EXEC smart_admin.sp_backup_master_switch @new_state=0 -- disable
EXEC smart_admin.sp_backup_master_switch @new_state=1 -- enable

-- 7. Create Certificate to backup database with encryption

USE master;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd';
GO

Use Master
GO
CREATE CERTIFICATE DBBackupEncryptCert
   WITH SUBJECT = 'Backup Encryption Certificate';
GO
BACKUP CERTIFICATE DBBackupEncryptCert TO FILE = 'C:\SQL\Certs\DBBackupEncryptCert'
    WITH PRIVATE KEY ( FILE = 'C:\SQL\Certs\DBBackupEncryptKey' , 
    ENCRYPTION BY PASSWORD = 'P@ssw0rd' );
GO

-- 7.2 Reconfigure Backup options
Use msdb;
 GO
 EXEC smart_admin.sp_set_db_backup 
 @database_name='MyDemoDB' 
 ,@enable_backup=1
 ,@retention_days = 7 
 ,@credential_name ='BackuptoURL'
 ,@encryption_algorithm ='AES_256'
 ,@encryptor_type= 'Certificate'
 ,@encryptor_name='DBBackupEncryptCert';
 GO
 
Use msdb
GO
SELECT * FROM smart_admin.fn_backup_db_config('MyDemoDB')

-- 8 Run a Backup
Exec msdb.smart_admin.sp_backup_on_demand 'MyDemoDB', 'Database'

-- 9 View the status
Exec msdb.smart_admin.sp_get_backup_diagnostics
-- Lookup the location in SSMS when connected to the storage account

-- 10 View Extended Event Default Configuration
SELECT * FROM smart_admin.fn_get_current_xevent_settings()
