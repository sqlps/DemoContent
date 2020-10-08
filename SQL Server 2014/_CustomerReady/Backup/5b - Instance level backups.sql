-- 1 For an instance of SQL Server:
Use msdb;
 GO
 EXEC smart_admin.sp_set_instance_backup
 @enable_backup=1
 ,@retention_days=2 
 ,@credential_name='BackuptoURL'
/* ,@encryption_algorithm ='AES_128'
 ,@encryptor_type= 'Certificate'.
 ,@encryptor_name='DBBackupEncryptCert';
 */
 GO

-- 2 For an instance of SQL Server with encryption
Use master;
 GO
 EXEC msdb.smart_admin.sp_set_instance_backup
 @enable_backup=1
 ,@retention_days=2 
 ,@credential_name='BackuptoURL'
 ,@encryption_algorithm ='AES_128'
 ,@encryptor_type= 'Certificate'
 ,@encryptor_name='DBBackupEncryptCert';
GO

-- 3 Ensure that master switch is on
EXEC msdb.smart_admin.sp_backup_master_switch @new_state=1 -- enable

-- 4 View Instance Config
Use msdb;
GO
SELECT * FROM smart_admin.fn_backup_instance_config ();

-- 5 Cleanup
Use master;
 GO
 EXEC msdb.smart_admin.sp_set_instance_backup
 @enable_backup=0
 ,@retention_days=2 
 ,@credential_name='BackuptoURL'
 ,@encryption_algorithm ='AES_128'
 ,@encryptor_type= 'Certificate'
 ,@encryptor_name='DBBackupEncryptCert';
GO
EXEC msdb.smart_admin.sp_backup_master_switch @new_state=0 -- disable
go