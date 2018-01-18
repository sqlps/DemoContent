USE WideWorldImporters;
GO

/********************************************************
*	SETUP - clear everything
********************************************************/

/* 
--old syntax 
DECLARE @db AS INT = DB_ID('WideWorldImporters')
DBCC FLUSHPROCINDB(@db);
*/

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

/* 
--old syntax  
ALTER DATABASE WideWorldImporters SET QUERY_STORE CLEAR ALL;
*/

ALTER DATABASE current SET QUERY_STORE CLEAR ALL;
ALTER DATABASE current SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF);
GO


SET NOCOUNT ON 
GO

/********************************************************
*	PART I
*	Plan regression identification.
********************************************************/

-- 1. Start workload - execute procedure 30 - 300 times:

DECLARE @packagetypeid int = 7;
EXEC dbo.report @packagetypeid;

GO 300


-- Queries should be fast
-- Run query one more time with  "Include Actual Execution Plan" enabled in SSMS 
--    and look at the plan (it should have Hash Aggregate) (Batch Operator)

DECLARE @packagetypeid int = 7;
EXEC dbo.report @packagetypeid;

-- 2. Execute procedure that causes plan regression
--  Look at the actual plan again; it should have Stream Aggregate (RBAR)

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

DECLARE @packagetypeid int = 1;
EXEC dbo.report @packagetypeid;


-- 3. Start workload again - verify that is slower.
-- DO NOT RUN the big batch with "Include Actual Execution Plan" enabled

DECLARE @packagetypeid int = 7;
EXEC dbo.report @packagetypeid;
GO 300
 
-- Note: User can apply script and force the recommended plan to correct the error.
<<Insert T-SQL from the script column here and execute the script>>
-- e.g.: exec sp_query_store_force_plan @query_id = 1, @plan_id = 1

-- 5. Start workload again - verify that is faster.

DECLARE @packagetypeid int = 7;
EXEC dbo.report @packagetypeid;
GO 300


