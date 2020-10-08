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

--Find Routing Priority
select ag.name, ar.replica_server_name as primary_server_role,
(select replica_server_name from sys.availability_replicas as b 
where b.replica_id = a.read_only_replica_id) as secondary_route_reader_server, 
a.routing_priority,ar.availability_mode_desc,ar.failover_mode_desc,ar.secondary_role_allow_connections_desc
from sys.availability_read_only_routing_lists as a
right join
sys.availability_replicas as ar
on a.replica_id = ar.replica_id
join sys.availability_groups as ag
on ar.group_id = ag.group_id
order by 2,4