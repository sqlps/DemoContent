--From http://msdn.microsoft.com/en-us/library/dn135319.aspx

--Check WSFC Cluster node config
use master
go
select * from sys.dm_hadr_cluster_members
go

--Explore the availability groups
select primary_replica, primary_recovery_health_desc, synchronization_health_desc from sys.dm_hadr_availability_group_states
go
select * from sys.availability_groups
go
select * from sys.availability_groups_cluster
go

--Explore Replicas
select replica_id, role_desc, connected_state_desc, synchronization_health_desc from sys.dm_hadr_availability_replica_states
go
select replica_server_name, replica_id, availability_mode_desc, endpoint_url from sys.availability_replicas
go
select replica_server_name, join_state_desc from sys.dm_hadr_availability_replica_cluster_states
go

--Explore Replica Health
select replica_id, role_desc, recovery_health_desc, synchronization_health_desc from sys.dm_hadr_availability_replica_states
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

--Looking at the HADR Ring Buffers
SELECT * FROM sys.dm_os_ring_buffers WHERE ring_buffer_type LIKE '%HADR%'

DECLARE @runtime datetime
SET @runtime = GETDATE()
SELECT CONVERT (varchar(30), @runtime, 121) as data_collection_runtime, 
DATEADD (ms, -1 * (inf.ms_ticks - ring.[timestamp]), GETDATE()) AS ring_buffer_record_time, 
ring.[timestamp] AS record_timestamp, inf.ms_ticks AS cur_timestamp, ring.* 
FROM sys.dm_os_ring_buffers ring  --http://msdn.microsoft.com/en-us/library/dn135320.aspx
CROSS JOIN sys.dm_os_sys_info inf where ring_buffer_type='RING_BUFFER_HADRDBMGR_STATE' --Change the buffer_type depending on what you're looking for. 1st query shows the buffer types or see http://msdn.microsoft.com/en-us/library/dn135320.aspx

WITH hadr(ts, type, record) AS
(
  SELECT timestamp AS ts, ring_buffer_type AS type, CAST(record AS XML) AS record 
  FROM sys.dm_os_ring_buffers WHERE ring_buffer_type = 'RING_BUFFER_HADRDBMGR_STATE' --Change the buffer_type depending on what you're looking for. 1st query shows the buffer types or see http://msdn.microsoft.com/en-us/library/dn135320.aspx
)
SELECT 
  ts,
  type,
  record.value('(./Record/@id)[1]','bigint') AS [Record ID],
  record.value('(./Record/@time)[1]','bigint') AS [Time],
  record.value('(./Record/HadrDbMgrAPI/dbId)[1]', 'bigint') AS [DBID],
  record.value('(/Record/HadrDbMgrAPI/API)[1]', 'varchar(50)') AS [API],
  record.value('(/Record/HadrDbMgrAPI/Action)[1]', 'varchar(50)') AS [Action],
  record.value('(/Record/HadrDbMgrAPI/role)[1]', 'int') AS [Role],
  record.value('(/Record/Stack)[1]', 'varchar(100)') AS [Call Stack]
FROM hadr
ORDER BY record.value('(./Record/@time)[1]','bigint') DESC
GO
