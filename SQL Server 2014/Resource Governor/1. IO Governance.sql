-- Setting up a database service for 2 paying customers

-- Create 2 resource pools & 2 workload groups
CREATE RESOURCE POOL Customer1Pool
CREATE RESOURCE POOL Customer2Pool
GO

CREATE WORKLOAD GROUP Customer1Group using Customer1Pool
CREATE WORKLOAD GROUP Customer2Group using Customer2Pool
GO

-- Create classifier function
CREATE FUNCTION fnUserClassifier()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
     IF ORIGINAL_DB_NAME() = 'Customer1DB'
     BEGIN
          RETURN 'Customer1Group'
     END

	IF ORIGINAL_DB_NAME() = 'Customer2DB'
     BEGIN
          RETURN 'Customer2Group'
     END

     RETURN 'default'
END
GO

-- Set the classifier function and enable RG
ALTER RESOURCE GOVERNOR 
  WITH (CLASSIFIER_FUNCTION = dbo.fnUserClassifier)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-- Set default values for the resource pools
ALTER RESOURCE POOL Customer1Pool WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=2147483647)
ALTER RESOURCE POOL Customer2Pool WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=2147483647)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-- now run a workload with many random reads against each DB
-- Start workload 1, observe TPS
-- Start workload 2, the workloads will even out
-- Increase workload 1 to 32 threads, observe noisy neighbor 
--  problem on workload 2


-- Set a minimum IOPS value for the 2nd pool
ALTER RESOURCE POOL Customer2Pool 
  WITH (MIN_IOPS_PER_VOLUME=3000, MAX_IOPS_PER_VOLUME=2147483647)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-- Workload 2 increases now it has a guaranteed minimum 

-- If we stop workload 2, workload 1 will use the available
-- IOPS again. 

-- Now we want to provide a consistent service regardless
-- of the level of activity from other users so cap the
-- maximum IO for workload 1

-- Now set a maximum IOPS value for the 1st pool
ALTER RESOURCE POOL Customer1Pool 
  WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=500)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-- stopping and starting workload 2 has much less effect

ALTER RESOURCE POOL Customer1Pool 
  WITH (MIN_IOPS_PER_VOLUME=0, MAX_IOPS_PER_VOLUME=50)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

/************************************************
 * View the DMVs Also while workload is running *
 ************************************************/
--1) Check Pending IO
Select sum(Pending_disk_io_count) from sys.dm_os_schedulers

Select * from sys.dm_io_pending_io_requests

--2) Look at the new sys.dm_resource_governor_resource_pool_volumes
select * from sys.dm_resource_governor_resource_pool_volumes

--3) New columns added to sys.dm_resource_governor_resource_pools for IO
select * from sys.dm_resource_governor_resource_pools  
where name like 'Customer%'

--4) New column to support max_outstanding_io_per_volume
Select * from  sys.resource_governor_configuration 
