SELECT * FROM SYS.availability_groups
SELECT * FROM SYS.availability_replicas
SELECT state_desc,* FROM SYS.databases where name='hadrontest'
select * from sys.dm_hadr_availability_replica_states
select * from sys.dm_hadr_availability_group_states
select last_sent_lsn, last_hardened_lsn, * from sys.dm_hadr_database_replica_states
select * from sys.dm_hadr_database_synchronization_states