--------------------------------------------------
-- 0 - CLEANUP
--------------------------------------------------
 
/*
USE [master]
GO
ALTER RESOURCE GOVERNOR with (CLASSIFIER_FUNCTION = NULL)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

DROP FUNCTION fnUserClassifier
GO

DROP WORKLOAD GROUP User1
go
DROP RESOURCE POOL Customer1
GO
DROP LOGIN [GovernMe] 
GO


*/

--------------------------------------------------
-- 1 - CREATE RESOURCE POOLS, Login & WORKLOAD GROUPS
--------------------------------------------------
CREATE RESOURCE POOL Customer1
GO

CREATE WORKLOAD GROUP User1 using Customer1
GO
USE [master]
GO

CREATE LOGIN [GovernMe] WITH PASSWORD=N'P@ssw0rd', DEFAULT_DATABASE=[AdventureWorksDW2008], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [GovernMe]
GO


--------------------------------------------------
-- 2 - CREATE CLASSIFIER FUNCTION
--------------------------------------------------
Use Master
Go

CREATE FUNCTION fnUserClassifier()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
     IF SUSER_Name() = 'Governme'
     BEGIN
          RETURN 'User1'
     END
     RETURN 'default'
END
GO

--------------------------------------------------
-- 3 - Setup the run parameters
--------------------------------------------------
  -- Reset the pool and workload statistics
ALTER RESOURCE GOVERNOR RESET STATISTICS;
ALTER RESOURCE POOL [Customer1] WITH(max_memory_percent=1)
GO
sp_configure 'max server memory', 1500
go
Reconfigure
go

--------------------------------------------------
-- 4 - SET THE CLASSIFIER FUNCTION AND ENABLE RG
--------------------------------------------------
ALTER RESOURCE GOVERNOR 
  WITH (CLASSIFIER_FUNCTION = dbo.fnUserClassifier)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

