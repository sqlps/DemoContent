-- ==================================================================
-- Step 1) Kickoff App and navigate via GUI
-- ==================================================================
-- The DMVs
Select * from sys.query_store_plan where is_forced_plan =1 and force_failure_count > 0

Select * from sys.query_store_query_text
Select * from sys.query_store_query order by query_id
Select * from sys.query_store_plan order by plan_id
Select * from sys.query_store_runtime_stats order by runtime_stats_id
Select * from sys.query_store_runtime_stats_interval order by runtime_stats_interval_id
Select * from sys.query_context_settings

Use QueryStoreDemo
GO
-- 2.1 Last N queries that were executed on the database
SELECT TOP 10 qt.query_sql_text, q.query_id, qt.query_text_id, p.plan_id, rs.last_execution_time
FROM
	sys.query_store_query_text qt JOIN 
	sys.query_store_query q ON qt.query_text_id = q.query_text_id JOIN
	sys.query_store_plan p ON q.query_id = p.query_id JOIN
	sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY rs.last_execution_time DESC
GO

-- 2.2 Count of executions for each query
SELECT q.query_id, qt.query_text_id, qt.query_sql_text, 
SUM(rs.count_executions) AS total_execution_count
FROM
	sys.query_store_query_text qt JOIN 
	sys.query_store_query q ON qt.query_text_id = q.query_text_id JOIN
	sys.query_store_plan p ON q.query_id = p.query_id JOIN
	sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
GROUP BY q.query_id, qt.query_text_id, qt.query_sql_text
ORDER BY total_execution_count DESC
GO

-- 2.3 N queries with longest average execution time within last hour
SELECT TOP 10 qt.query_sql_text, q.query_id, qt.query_text_id, p.plan_id, 
getutcdate() as CurrentUTCTime, rs.last_execution_time, rs.avg_duration
FROM
	sys.query_store_query_text qt JOIN 
	sys.query_store_query q ON qt.query_text_id = q.query_text_id JOIN
	sys.query_store_plan p ON q.query_id = p.query_id JOIN
	sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE rs.last_execution_time > dateadd(hour, -1, getutcdate())
ORDER BY rs.avg_duration DESC
GO

-- 2.4 N queries that had the biggest average physical IO reads in last 24 hours, 
--    with corresponding average row count and execution count
SELECT TOP 10 qt.query_sql_text, q.query_id, qt.query_text_id, p.plan_id, 
rs.runtime_stats_id, rsi.start_time, rsi.end_time, rs.avg_physical_io_reads, 
rs.avg_rowcount, rs.count_executions
FROM
	sys.query_store_query_text qt JOIN 
	sys.query_store_query q ON qt.query_text_id = q.query_text_id JOIN
	sys.query_store_plan p ON q.query_id = p.query_id JOIN
	sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id JOIN
	sys.query_store_runtime_stats_interval rsi ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
WHERE rsi.start_time >= dateadd(hour, -24, getutcdate()) 
ORDER BY rs.avg_physical_io_reads DESC
GO

-- 2.5 Queries that recently regressed in performance
--  The following query example returns all queries which execution time was 
--   doubled in last 48 hours.
SELECT 
	qt.query_sql_text, 
	q.query_id, 
	qt.query_text_id, 
	p1.plan_id AS plan1, 
	rsi1.start_time AS runtime_stats_interval_1, 
	rs1.runtime_stats_id AS runtime_stats_id_1,
	rs1.avg_duration AS avg_duration_1, 
	p2.plan_id AS plan2, 
	rsi2.start_time AS runtime_stats_interval_2, 
	rs2.runtime_stats_id AS runtime_stats_id_2,
	rs2.avg_duration AS plan2
FROM
	sys.query_store_query_text qt JOIN 
	sys.query_store_query q ON qt.query_text_id = q.query_text_id JOIN
	sys.query_store_plan p1 ON q.query_id = p1.query_id JOIN
	sys.query_store_runtime_stats rs1 ON p1.plan_id = rs1.plan_id JOIN
	sys.query_store_runtime_stats_interval rsi1 ON rsi1.runtime_stats_interval_id = rs1.runtime_stats_interval_id JOIN
	sys.query_store_plan p2 ON q.query_id = p2.query_id JOIN
	sys.query_store_runtime_stats rs2 ON p2.plan_id = rs2.plan_id JOIN
	sys.query_store_runtime_stats_interval rsi2 ON rsi2.runtime_stats_interval_id = rs2.runtime_stats_interval_id
WHERE
	rsi1.start_time > dateadd(hour, -48, getutcdate()) AND
	rsi2.start_time > rsi1.start_time AND
	rs2.avg_duration > 2*rs1.avg_duration

	/* (6) Performance analysis using Query Store views*/
SELECT q.query_id, qt.query_text_id, qt.query_sql_text, SUM(rs.count_executions) AS total_execution_count
FROM
sys.query_store_query_text qt JOIN 
sys.query_store_query q ON qt.query_text_id = q.query_text_id JOIN
sys.query_store_plan p ON q.query_id = p.query_id JOIN
sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
GROUP BY q.query_id, qt.query_text_id, qt.query_sql_text
ORDER BY total_execution_count DESC


SELECT qt.query_text_id, q.query_id, qt.query_sql_text, qt.statement_sql_handle,

q.context_settings_id, qs.statement_context_id 

FROM sys.query_store_query_text qt

JOIN sys.query_store_query q ON qt.query_text_id = q.query_id

CROSS APPLY sys.fn_stmt_sql_handle_from_sql_stmt (qt.query_sql_text, null) fn_hanlde_from_stmt

JOIN sys.dm_exec_query_stats qs ON fn_hanlde_from_stmt.statement_sql_handle = qs.statement_sql_handle



