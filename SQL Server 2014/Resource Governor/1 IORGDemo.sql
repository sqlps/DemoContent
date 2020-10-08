--Reference: http://blogs.technet.com/b/dataplatforminsider/archive/2013/11/07/io-resource-governance-in-sql-server-2014.aspx

-- Setting up a database service for 2 paying customers

--------------------------------------------------
-- 0 - CLEANUP
--------------------------------------------------
/*
ALTER RESOURCE GOVERNOR with (CLASSIFIER_FUNCTION = NULL)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

DROP FUNCTION fnUserClassifier
GO

DROP WORKLOAD GROUP ContosoSales_dotcom
DROP WORKLOAD GROUP FabrikamInc_dotcom
DROP WORKLOAD GROUP Customer1Group
DROP WORKLOAD GROUP Customer2Group
GO

DROP RESOURCE POOL GlobalSalesPool
DROP RESOURCE POOL USSalesPool
DROP RESOURCE POOL Customer1Pool
DROP RESOURCE POOL Customer2Pool
GO
*/

--------------------------------------------------
-- 1 - CREATE 2 RESOURCE POOLS & 2 WORKLOAD GROUPS
--------------------------------------------------
CREATE RESOURCE POOL USSalesPool
CREATE RESOURCE POOL GlobalSalesPool
GO

CREATE WORKLOAD GROUP ContosoSales_dotcom using USSalesPool
CREATE WORKLOAD GROUP FabrikamInc_dotcom using GlobalSalesPool
GO

--------------------------------------------------
-- 2 - CREATE CLASSIFIER FUNCTION
--------------------------------------------------
CREATE FUNCTION fnUserClassifier()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
     IF ORIGINAL_DB_NAME() = 'Customer1DB'
     BEGIN
          RETURN 'ContosoSales_dotcom'
     END

	IF ORIGINAL_DB_NAME() = 'Customer2DB'
     BEGIN
          RETURN 'FabrikamInc_dotcom'
     END

     RETURN 'default'
END
GO

--------------------------------------------------
-- 3 - VIEW METADATA INFORMATION
--------------------------------------------------
  -- Reset the pool and workload statistics
ALTER RESOURCE GOVERNOR RESET STATISTICS;

-- View Metadata Information
SELECT * FROM sys.resource_governor_workload_groups
SELECT * FROM sys.resource_governor_resource_pools
SELECT * FROM sys.resource_governor_configuration

-- View In-memory Information
SELECT * FROM sys.dm_resource_governor_workload_groups
SELECT * FROM sys.dm_resource_governor_resource_pools
SELECT * FROM sys.dm_resource_governor_configuration

--------------------------------------------------
-- 4a - SET THE CLASSIFIER FUNCTION AND ENABLE RG
--------------------------------------------------
ALTER RESOURCE GOVERNOR 
  WITH (CLASSIFIER_FUNCTION = dbo.fnUserClassifier)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

--------------------------------------------------
-- 4b - RECHECK THE RG CONFIGURATION
--------------------------------------------------
SELECT * FROM sys.dm_resource_governor_configuration
SELECT * FROM sys.resource_governor_configuration

--------------------------------------------------
-- 5 - SET THE MIN and MAX_IOPS_PER_VOLUME
--------------------------------------------------
ALTER RESOURCE POOL USSalesPool 
 WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=2147483647)
ALTER RESOURCE POOL GlobalSalesPool  
 WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=2147483647)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

--------------------------------------------------
-- 6 - SET A MINIMUM IOPS VALUE FOR THE 2ND POOL
--------------------------------------------------
ALTER RESOURCE POOL GlobalSalesPool 
  WITH (MIN_IOPS_PER_VOLUME=750, MAX_IOPS_PER_VOLUME=2147483647)
  ALTER RESOURCE GOVERNOR RECONFIGURE
GO

--------------------------------------------------
-- 7a - RUN A WORKLOAD WITH MANY RANDOM READS AGAINST EACH DB
--------------------------------------------------
-- A. Start workload 1, observe transactions per sec
-- B. Start workload 2, the workloads will even out

--------------------------------------------------
-- 7b - OBSERVE OVERHEAD IN PERFMON AND THE NEW _resource_pool_volumes DMV
--------------------------------------------------
SELECT p.name, b.* FROM sys.dm_resource_governor_resource_pool_volumes  b
INNER JOIN sys.resource_governor_resource_pools p ON p.pool_id = b.pool_id

-- C. Increase workload 1 to 32 threads, observe noisy neighbor problem on workload 2

/*
Workload 2 increases now it has a guaranteed minimum 
If we stop workload 2, workload 1 will use the available
IOPS again. 

Now we want to provide a consistent service regardless
of the level of activity from other users so cap the
maximum IO for workload 1
*/

--------------------------------------------------
-- 7C - EXAMINE THE WAITS FOR TASKS AND THE OUTPUT OF THE RG RELATED PERFMON COUNTERS
--------------------------------------------------

--WAITS OUTPUT
SELECT * FROM sys.dm_os_waiting_tasks
WHERE session_id > 50

--RG COUNTERS FROM DMV
SELECT * FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Workload Group Stats' AND
counter_name IN ('Active parallel threads', 'Queued requests', 'Active requests', 'Blocked tasks')

SELECT * FROM sys.dm_os_performance_counters 
WHERE object_name = 'SQLServer:Resource Pool Stats' AND
counter_name LIKE'%Disk%'
order by cntr_value desc


--------------------------------------------------
-- 8a - NOW SET A MAXIMUM IOPS VALUE FOR THE 1ST POOL
--------------------------------------------------
ALTER RESOURCE POOL USSalesPool 
  WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=600)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-- Note: stopping and starting workload 2 has much less effect

--------------------------------------------------
-- 8b - NOW SET A MAXIMUM IOPS VALUE FOR THE 1ST POOL
--------------------------------------------------
ALTER RESOURCE POOL GlobalSalesPool 
  WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=300)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

--------------------------------------------------
-- 9a - **OPTIONAL** PLAY WITH DECREASING THE MAX IOPS AND CHECKING THE DMVs AND
--     PERFMON BEHAVIOR
--------------------------------------------------

--IF WE ARE WAITING... WHAT'S THE WAIT TYPE?
/*
SELECT * FROM sys.dm_os_waiting_tasks
WHERE session_id > 50
*/
