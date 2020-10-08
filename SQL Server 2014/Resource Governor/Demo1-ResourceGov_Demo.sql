--Ensure Affinity is to 2CPU
-- use only 1 CPU on demo machine
sp_configure 'show advanced', 1
GO
RECONFIGURE
GO
sp_configure 'affinity mask', 1
GO
RECONFIGURE
GO
-- Validate
Select * from sys.dm_os_schedulers --How many are visible online
GO

-- Is Resource Governor Enabled ?
SELECT * FROM sys.resource_governor_configuration;


-- create logins to separate users into different groups
-- note that we disabled strong password checking for demo purposes, but this is against any best practice
CREATE LOGIN UserA WITH PASSWORD = 'UserAPwd', CHECK_POLICY = OFF
CREATE LOGIN UserB WITH PASSWORD = 'UserBPwd', CHECK_POLICY = OFF
CREATE LOGIN UserC WITH PASSWORD = 'UserCPwd', CHECK_POLICY = OFF
GO

-- create user pools - note that we are using all default parameters
CREATE RESOURCE POOL PoolA
CREATE RESOURCE POOL PoolB

-- create user groups - also note that all groups created with default parameters
-- only pointing to the corresponding pools (and not 'default')
CREATE WORKLOAD GROUP GroupA
USING PoolA

CREATE WORKLOAD GROUP GroupB
USING PoolB

CREATE WORKLOAD GROUP GroupC --vp queries
USING PoolB
GO

-- Check to see the workload groups exist yet
Select distinct instance_name from sys.dm_os_performance_counters
where object_name = 'MSSQL$SQL2008R2:Workload Group Stats'

-- classifier function should be created in master database, switch to master unless you are there already
-- make function known to the Resource Governor 
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-- And what about now?
Select distinct instance_name from sys.dm_os_performance_counters
where object_name = 'MSSQL$SQL2008R2:Workload Group Stats'


-- now create the classifier function
IF OBJECT_ID('DBO.CLASSIFIER_V1','FN') IS NOT NULL
       DROP FUNCTION DBO.CLASSIFIER_V1
GO

-- note that this is just a regular function 
CREATE FUNCTION CLASSIFIER_V1 ()
RETURNS SYSNAME WITH SCHEMABINDING
BEGIN
       DECLARE @val varchar(32)
       SET @val = 'default';
       if  'UserA' = SUSER_SNAME() 
              SET @val = 'GroupA';
       else if 'UserB' = SUSER_SNAME()
              SET @val = 'GroupB';
       else if 'UserC' = SUSER_SNAME()
              SET @val = 'GroupC';
       return @val;
END
GO

-- make function known to the Resource Governor 
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.CLASSIFIER_V1)
GO

-- metadata information
SELECT * FROM sys.resource_governor_workload_groups
SELECT * FROM sys.resource_governor_resource_pools
SELECT OBJECT_NAME(classifier_function_id) as
'name of classifier function',* FROM sys.resource_governor_configuration

-- in-memory information
SELECT * FROM sys.dm_resource_governor_workload_groups
SELECT * FROM sys.dm_resource_governor_resource_pools
SELECT * FROM sys.dm_resource_governor_configuration

SELECT group_id, W.name, P.name
 FROM sys.dm_resource_governor_workload_groups W
 Inner Join sys.dm_resource_governor_resource_pools P
 On W.pool_id = P.pool_id

-- make the changes effective
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

--******* Show PerfMon *******
--******* Start batch jobs x 3 *******


--What Scheduler am I running on?

Select session_id, scheduler_id, WG.Name 
from sys.dm_exec_requests ER
Inner Join sys.dm_resource_governor_workload_groups WG
on ER.group_id = WG.group_id
where WG.group_id > 2


-- Stop Batches
-- adjust PoolB to not consume more than 50% of CPU
ALTER RESOURCE POOL PoolB WITH (MAX_CPU_PERCENT = 50)

-- make the changes effective
ALTER RESOURCE GOVERNOR RECONFIGURE

-- alter importance of B group
ALTER WORKLOAD GROUP GroupB WITH (IMPORTANCE = Low) --1/10

-- alter importance of C group
ALTER WORKLOAD GROUP GroupC WITH (IMPORTANCE = High)-- 9/10

-- make the changes effective
ALTER RESOURCE GOVERNOR RECONFIGURE

-- Restart batches

-- Stop Batches

--Use all Proces
sp_configure 'show advanced', 1
GO
RECONFIGURE
GO
sp_configure 'affinity mask', 0
GO
RECONFIGURE
GO

-- Validate
Select * from sys.dm_os_schedulers --How many are visible online
GO


-- Restart batches
Select session_id, scheduler_id, WG.Name 
from sys.dm_exec_requests ER
Inner Join sys.dm_resource_governor_workload_groups WG
on ER.group_id = WG.group_id
where WG.group_id > 2


---- DROP ALL THE FUNCTIONALITY 
DROP WORKLOAD GROUP GroupA
DROP WORKLOAD GROUP GroupB
DROP WORKLOAD GROUP GroupC

DROP RESOURCE POOL PoolA
DROP RESOURCE POOL PoolB

-- Disabling the Classifier 
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL)
GO
-- make the changes effective
ALTER RESOURCE GOVERNOR RECONFIGURE

DROP FUNCTION CLASSIFIER_V1

DROP LOGIN UserA
DROP LOGIN UserB
DROP LOGIN UserC

ALTER RESOURCE GOVERNOR DISABLE;