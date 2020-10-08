
if exists (select * from sys.databases where name='IMOLTP_Demo')
begin
	ALTER DATABASE IMOLTP_Demo set single_user with rollback immediate
	drop database IMOLTP_Demo
end
go

CREATE DATABASE [IMOLTP_DEMO]
 ON  PRIMARY 
( NAME = N'IMOLTP_DEMO', FILENAME = N'D:\DATA\IMOLTP_DEMO.mdf' , SIZE = 4096KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'IMOLTP_DEMO_log', FILENAME = N'D:\LOG\IMOLTP_DEMO_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO

----- Enable database for memory optimized tables by adding memory_optimized_data filegroup
ALTER DATABASE IMOLTP_Demo 
    ADD FILEGROUP IMOLTP_Demo_mod CONTAINS MEMORY_OPTIMIZED_DATA
GO

-- add container to the filegroup
ALTER DATABASE IMOLTP_Demo 
ADD FILE (NAME='IMOLTP_Demo_mod', FILENAME='D:\DATA\IMOLTP_Demo_mod') 
TO FILEGROUP IMOLTP_Demo_mod
GO


use IMOLTP_DEMO
Go

-- disable auto-merge so that we can shor the merge in a predictable way
-- runs ~ every 2 mins by default
dbcc traceon (9851, -1)

alter database imoltp_demo set recovery full
go

--Data and Delta files will be stored to D:\Data\IMOLTP_Demo_mod\<GUID>

CREATE TABLE dbo.t_memopt(
	c1 int NOT NULL,
	c2 char(40) NOT NULL,
	c3 char(8000) NOT NULL,

	CONSTRAINT [pk_t_memopt_c1] PRIMARY KEY NONCLUSTERED HASH (c1) WITH (BUCKET_COUNT = 1000000),
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)

--Look at D:\Data\IMOLTP_Demo_mod\<GUID>
--8 Pre-Created and 1 Under construction file pair without any rows being inserted
--16MB files created instead of 128MB since I have <= 16GB RAM


--Let's look at the state of the files now

Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn
GO

--Let's look at the size of the DB
BACKUP DATABASE [IMOLTP_DEMO] TO  DISK = N'G:\Backup\IMOLTP_DEMO_nodata.bak' WITH FORMAT, INIT,  
NAME = N'IMOLTP_DEMO-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10
GO

Set NoCount on
GO

declare @i int = 0
while (@i < 8000)
begin
	Insert t_memopt values (@i, 'a', replicate ('b', 8000))
	set @i += 1;
end
GO

-- show the data/delta files are under construction
Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn
GO

--Next do a checkpoint
CHECKPOINT

-- now let's take another look
Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn

--Because we forced a checkpoint the 5th file only has 496 rows
GO

--Let's delete about 1/2 the rows
Declare @i int =0
while (@i <=8000)
begin
	delete t_memopt where c1 = @i
	set @i += 2
end 
go

CHECKPOINT -- This will create a new pair with 0

-- now let's take another look
Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn
GO

--Let's look at the size of the DB
BACKUP DATABASE [IMOLTP_DEMO] TO  DISK = N'G:\Backup\IMOLTP_DEMO_data.bak' WITH FORMAT, INIT,  
NAME = N'IMOLTP_DEMO-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10
GO


--Kick off an manual merge
exec sys.sp_xtp_merge_checkpoint_files 'imoltp_demo', 1877, 12007--'DB, Lower LSN, Upper LSN

-- See merge is still pending
select * from sys.dm_db_xtp_merge_requests

--Merge kicked in but has not happened yet, but now we have a MERGE TARGET
Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn
GO

--RUN Checkpoint to make the merge happen
CHECKPOINT

--Now we should have 1 file that is ACTIVE and contains the Merged records and the record count is???
Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn
GO

-- MERGE is now installed
select * from sys.dm_db_xtp_merge_requests

-- Now let's see garbage collection of the files
CHECKPOINT 
GO

BACKUP LOG [IMOLTP_DEMO] TO  DISK = N'G:\Backup\IMOLTP_DEMO.trn' WITH NOFORMAT, 
INIT,  NAME = N'IMOLTP_DEMO-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

--Now it's saying the files are needed for Backup/HA and will stay in this state for several backup cycles.
Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn
GO

--Run the backups a couple more times so the file get's tombstoned
CHECKPOINT
go
BACKUP LOG [IMOLTP_DEMO] TO  DISK = N'G:\Backup\IMOLTP_DEMO2.bak' WITH NOFORMAT, 
INIT,  NAME = N'IMOLTP_DEMO-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO 

--Now it's saying the files are Tombstoned
Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn
GO

--Clean up the tombstone files
--keep running until num_unprocessed_items = 0
Checkpoint
go

backup log imoltp_demo to disk = 'nul'
go

exec sp_filestream_force_garbage_collection
go

--Now it's saying the files are Tombstoned
Select file_type_desc, state, state_desc, internal_storage_slot, file_size_in_bytes, file_size_used_in_bytes,
inserted_row_count, deleted_row_count, lower_bound_tsn, upper_bound_tsn, last_backup_page_count, logical_deletion_log_block_id,
tombstone_operation_lsn, last_backup_page_count, drop_table_deleted_row_count
from sys.dm_db_xtp_checkpoint_files
--where state = 1
order by file_type_desc, upper_bound_tsn
GO


--Now let's see the size of backup
BACKUP DATABASE [IMOLTP_DEMO] TO  DISK = N'G:\Backup\IMOLTP_DEMO_afterdelete.bak' WITH FORMAT, INIT,  
NAME = N'IMOLTP_DEMO-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10
GO
