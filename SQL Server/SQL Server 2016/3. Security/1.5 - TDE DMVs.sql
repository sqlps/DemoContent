--Check the certifactes. thumbprint will help identify what cert needed to restore a db. on restore, if the cert used to protect the dek is not present it will fail stating what thumbprint is needed.
--ex:
--Msg 33111, Level 16, State 3, Line 1
--Cannot find server certificate with thumbprint '0x182F974A2A11FEC93BB95D67F7EFF247305633B2'.
--Msg 3013, Level 16, State 1, Line 1
--RESTORE FILELIST is terminating abnormally.

Select * from sys.certificates

--Status of encryption scan.Contains percent_omplete
--0 = No database encryption key present, no encryption
--1 = Unencrypted
--2 = Encryption in progress
--3 = Encrypted
--4 = Key change in progress
--5 = Decryption in progress
Select percent_complete, * from sys.dm_database_encryption_keys

select is_encrypted, * from sys.databases
order by 1 desc

--Threads in use
select session_id, status,command, reads as 'physical_reads', 
logical_reads, cpu_time, total_elapsed_time as total_time from sys.dm_exec_requests
Where Command like 'Alter Database E%'
