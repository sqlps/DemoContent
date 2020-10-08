--Look at the sessions in SQL Server
select * from sys.dm_exec_sessions
where is_user_process = 1 and login_name <> 'sqladmin11\sqlsvc'

--Look at the connections
select * from sys.dm_exec_connections

--Check if Kerberos is working
Select auth_scheme, count(*) 'Total Connections'
from sys.dm_exec_connections
group by auth_scheme


--Where are my connections coming from?
Select client_net_address, s.host_name, count(*) 'Total Connections'
from sys.dm_exec_connections c
inner join sys.dm_exec_sessions s
on s.session_id = c.most_recent_session_id
Where database_id > 4 
and host_name = 'LOADRUNNER'
group by client_net_address, host_name


--Connections per DB
Select db_name(s.database_id), s.host_name, count(*) 'Total Connections'
from sys.dm_exec_connections c
inner join sys.dm_exec_sessions s
on s.session_id = c.most_recent_session_id
Where database_id > 4 
and host_name = 'LOADRUNNER'
group by db_name(s.database_id), client_net_address, host_name
