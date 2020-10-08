--Reference: http://blogs.technet.com/b/dataplatforminsider/archive/2013/11/07/io-resource-governance-in-sql-server-2014.aspx

-- Setting up a database service for 2 paying customers
USE MASTER 
GO
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
GO

DROP RESOURCE POOL GlobalSalesPool
DROP RESOURCE POOL USSalesPool
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
Select OBJECT_SCHEMA_NAME(classifier_function_id) AS [schema_name],
		OBJECT_NAME(Classifier_function_id) AS [Function_Name], * 
		FROM sys.dm_resource_governor_configuration
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
ALTER RESOURCE POOL GlobalSalesPool --Customer2
  WITH (MIN_IOPS_PER_VOLUME=1200, MAX_IOPS_PER_VOLUME=2147483647)
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

--------------------------------------------------
-- 8a - NOW SET A MAXIMUM IOPS VALUE FOR THE 1ST POOL
--------------------------------------------------

--RUN BELOW 2 TOGETHER
ALTER RESOURCE POOL USSalesPool --Customer1
  WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=100)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO
--Restart