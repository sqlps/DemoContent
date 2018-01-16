SELECT ag.name AS ag_name, ar.replica_server_name AS ag_replica_server, DB_NAME(dr_state.database_id) as database_name, 
is_ag_replica_local = CASE 
WHEN ar_state.is_local = 1 THEN N'LOCAL' 
ELSE 'REMOTE' 
END , 
ag_replica_role = CASE 
WHEN ar_state.role_desc IS NULL THEN N'DISCONNECTED' 
ELSE ar_state.role_desc 
END, 
dr_state.last_hardened_lsn, dr_state.last_hardened_time, datediff(s,last_hardened_time, 
getdate()) / 60 as 'seconds behind primary' 
FROM (( sys.availability_groups AS ag JOIN sys.availability_replicas AS ar ON ag.group_id = ar.group_id ) 
JOIN sys.dm_hadr_availability_replica_states AS ar_state ON ar.replica_id = ar_state.replica_id) 
JOIN sys.dm_hadr_database_replica_states dr_state on ag.group_id = dr_state.group_id and dr_state.replica_id = ar_state.replica_id
order by datediff(s,last_hardened_time, getdate()) DESC;
