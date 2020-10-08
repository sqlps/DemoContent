/* This Sample Code is provided for the purpose of illustration only and is not intended
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys fees, that arise or
result from the use or distribution of the Sample Code.*/

--Check WSFC Cluster node config
use master
go
select * from sys.dm_hadr_cluster_members
go

--Explore Availability DBs
select * from sys.availability_databases_cluster
go
select group_database_id, database_name, is_failover_ready  from sys.dm_hadr_database_replica_cluster_states
go
select database_id, synchronization_state_desc, synchronization_health_desc, last_hardened_lsn, redo_queue_size, log_send_queue_size from sys.dm_hadr_database_replica_states
go


--Explore Availability DBs Health
select dc.database_name, dr.database_id, dr.synchronization_state_desc, 
dr.suspend_reason_desc, dr.synchronization_health_desc
from sys.dm_hadr_database_replica_states dr  join sys.availability_databases_cluster dc
on dr.group_database_id=dc.group_database_id 
where is_local=1
go
