USE WideWorldImporters;
GO

/********************************************************
*	PART II
*	Automatic tuning
********************************************************/

/********************************************************
*	RESET - clear everything
********************************************************/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

ALTER DATABASE current SET QUERY_STORE CLEAR ALL;
ALTER DATABASE current SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON);
GO

SET NOCOUNT ON 
GO



-- 1. Start workload - execute procedure same number of times as in Part I (at least)

DECLARE @packagetypeid int = 7;
EXEC dbo.report @packagetypeid;
GO 300

-- 2. Execute the procedure that causes plan regression
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

DECLARE @packagetypeid int = 1;
EXEC dbo.report @packagetypeid;
GO 300

-- 3. Start workload again - verify that it is slower.
SET NOCOUNT ON 
DECLARE @packagetypeid int = 7;
EXEC dbo.report @packagetypeid;
GO 300

		  
-- 5. Wait until recommendation is applied and start workload again - verify that it is faster.

DECLARE @packagetypeid int = 7;
EXEC dbo.report @packagetypeid;
GO 30

-- Open Query Store/"Top Resource Consuming Queries" dialog in SSMS,
--    in the WideWorldImporters database, and show that better plan is forced.

EXEC dbo.initialize;
GO