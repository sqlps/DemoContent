-- ===================================
-- SQL 2014 Rules
-- ===================================
/*
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

-- =================================================================================
-- Step 1) SQL Server 2016 Enables customization, simple recovery & system databases
-- =================================================================================
/* Other Enhancements
Backup striping and faster restore
Maximum backup size is 12 TB+
Granular access and unified credential story (SAS URIs)
Supports all existing backup/restore features (except append)
*/

EXEC msdb.Managed_Backup.sp_backup_config_schedule
@database_name = 'DBA'
,@scheduling_option= 'Custom'  
,@full_backup_freq_type = 'weekly' 
,@days_of_week = 'Saturday'
,@backup_begin_time =  '11:00'
,@backup_duration =  '02:00' --Does not gurantee that backups complete within this window
,@log_backup_freq =  '00:15'
 
-- ==================================================================
-- Step 1) SQL Server 2016 Enables customization and system databases
-- ==================================================================
EXEC msdb.managed_backup.sp_backup_config_basic 
@database_name= 'DBA',
@enable_backup=1, 
@container_url='http://pankajtsp.blob.core.windows.net/managedbackups?sv=2015-04-05&sr=c&sig=kKrMlE%2FGq%2BocXlPoq%2F%2B7d9DXEsBS0cY7HhBRf6oOuls%3D&se=2016-03-01T05%3A55%3A16Z&sp=rwdl'



Use msdb;
Go
EXEC managed_backup.sp_backup_config_basic
                @enable_backup=0;
GO 