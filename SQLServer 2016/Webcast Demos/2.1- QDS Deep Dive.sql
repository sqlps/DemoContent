-- Credit to Bob Ward on these scripts/demos

-- =============================================
-- Step 1) Clear Query Store and procedure cache
-- =============================================
-- Documentation: https://msdn.microsoft.com/en-us/library/mt604821.aspx
-- First show how to setup in the GUI 

ALTER DATABASE QueryStoreTest SET QUERY_STORE CLEAR;
--ALL:	Analyze your workload thoroughly in terms of all queries shapes and their execution frequencies and other statistics.
--		Identify new queries in your workload.
--		Detect if ad-hoc queries are used to identify opportunities for user or auto parameterization.
--Auto:	Will not get a ad-hoc queries. Focus your attention on relevant and actionable queries; those queries that execute regularly or that have significant resource consumption.
--None: None should be used with caution as you might miss the opportunity to track and optimize important new queries. Avoid using None unless you have a specific scenario that requires it.

ALTER DATABASE QueryStoreTest SET QUERY_STORE = ON (QUERY_CAPTURE_MODE = ALL); --Onprem default is ALL, Azure it's AUTO
DBCC FREEPROCCACHE

-- =============================================
-- Step 2) Run simple query - where it goes
-- =============================================
use QueryStoreTest;
GO

SELECT * FROM Part;

SELECT * FROM sys.query_store_query_text;
SELECT * FROM sys.query_store_query; --compile, optimize, mem
SELECT * FROM sys.query_store_plan; --Contains engine_verision and compat level
SELECT * FROM sys.query_store_runtime_stats; -- Resource utilization

/*
	Combine all info
	vw_QueryStoreCompileInfo is custom view (created for presentation)

*/
SELECT * FROM vw_QueryStoreCompileInfo
WHERE query_sql_text = 'SELECT * FROM Part'

-- =============================================
-- Step 3) The same query from proc or sp_executesql
-- =============================================
DROP PROCEDURE IF EXISTS sp_GetParts
GO

CREATE PROCEDURE sp_GetParts
as
SELECT * FROM Part;
GO

EXEC sp_GetParts;

-- Again the same query, from sp_executesql
exec sp_executesql N'SELECT * FROM Part'

-- What do we see
SELECT * FROM vw_QueryStoreCompileInfo
WHERE query_sql_text = 'SELECT * FROM Part'

-- =============================================
-- Step 4) What happens with parametrized query?
-- =============================================
SELECT * FROM Part WHERE PartId = 5;

SELECT * FROM vw_QueryStoreCompileInfo
WHERE query_sql_text = 'SELECT * FROM Part = 5'

-- Check sys.query_store_query_text 

SELECT * FROM sys.query_store_query_text;

-- Try sys.fn_stmt_sql_handle_from_sql_stmt this instead
SELECT * FROM sys.fn_stmt_sql_handle_from_sql_stmt 
('SELECT * FROM Part WHERE PartId = 5', NULL)

-- =============================================
-- Step 5) Current Config
-- =============================================

USE QueryStoreTest;
GO

SELECT actual_state_desc, desired_state_desc, current_storage_size_mb, 
    max_storage_size_mb, readonly_reason, interval_length_minutes, 
    stale_query_threshold_days, size_based_cleanup_mode_desc, 
    query_capture_mode_desc
FROM sys.database_query_store_options

