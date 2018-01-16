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

/*We will now examine monitoring AlwaysOn using SQL Server Dynamic Management Views.

Run the following queries and look these DMVs up in SQL Server Books Online to get an idea of the information that is captured for AlwaysOn

This DMV tells if online or Offline, What role the replica is running, and the recovery health and Sync Health*/

SELECT * FROM sys.dm_hadr_availability_replica_states

--This DMV gives us a quick high level health status of replicas

SELECT * FROM sys.dm_hadr_availability_group_states

--This DMV gives us specific database health and sync state, if it suspended and why, and the sync latency for the database

SELECT * FROM sys.dm_hadr_database_replica_states

--This DMV lists if AlwaysOn is failover ready

SELECT * FROM sys.dm_hadr_database_replica_cluster_states

--This DMV lists the quorum info for cluster

SELECT * FROM sys.dm_hadr_cluster

--This DMV lists the node names and quorum type, and quorum vote counts

SELECT * FROM sys.dm_hadr_cluster_members

--This DMV lists the Replica names and IP Subnet info

SELECT * FROM sys.dm_hadr_cluster_networks

This DMV lists every automatic page-repair attempt and the database ID and Page ID and Status of page

SELECT * FROM sys.dm_hadr_auto_page_repair

--This DMV lists the databases in AG on Replica

SELECT * FROM sys.availability_databases_cluster

--This DMV lists the Availability Groups on replica

SELECT * FROM sys.availability_groups

--This DMV lists the Availability Group configuration in Cluster, Failure condition, Automated Backup Config

SELECT * FROM sys.availability_groups_cluster

--This DMV lists the replica Configuration for the Availability Group, Backup role, Failover Mode, Session Timeout, and if it is synchronous or asynchronous.
SELECT * FROM sys.availability_replicas