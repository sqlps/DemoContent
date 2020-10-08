USE [AdventureWorks2014]
GO

--1.0 Determine if Query Store is currently active, and whether it is currently collects runtime stats or not.
SELECT actual_state, actual_state_desc, readonly_reason,   
    current_storage_size_mb, max_storage_size_mb  
FROM sys.database_query_store_options;  

--1.1 Get Query Store options, To find out detailed information about Query Store status, execute following in a user database.
SELECT * FROM sys.database_query_store_options;  

SELECT actual_state, actual_state_desc, readonly_reason, 
current_storage_size_mb, max_storage_size_mb
FROM sys.database_query_store_options;

-- 2.0 The following query returns information about queries and plans in the query store.
SELECT Txt.query_text_id, Txt.query_sql_text, Pl.plan_id, Qry.*
FROM sys.query_store_plan AS Pl
JOIN sys.query_store_query AS Qry
    ON Pl.query_id = Qry.query_id
JOIN sys.query_store_query_text AS Txt
    ON Qry.query_text_id = Txt.query_text_id ;

-- 2.1 Last N queries that were executed on the database
SELECT TOP 20 qt.query_sql_text, q.query_id, qt.query_text_id, p.plan_id, rs.last_execution_time
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

--2.5 Queries with multiple plans? These queries are especially interesting because they are candidates for regressions due to plan choice change. The following query identifies these queries along with all plans:

WITH Query_MultPlans  
AS  
(  
SELECT COUNT(*) AS cnt, q.query_id   
FROM sys.query_store_query_text AS qt  
JOIN sys.query_store_query AS q  
    ON qt.query_text_id = q.query_text_id  
JOIN sys.query_store_plan AS p  
    ON p.query_id = q.query_id  
GROUP BY q.query_id  
HAVING COUNT(distinct plan_id) > 1  
)  
  
SELECT q.query_id, object_name(object_id) AS ContainingObject,   
    query_sql_text, plan_id, p.query_plan AS plan_xml,  
    p.last_compile_start_time, p.last_execution_time  
FROM Query_MultPlans AS qm  
JOIN sys.query_store_query AS q  
    ON qm.query_id = q.query_id  
JOIN sys.query_store_plan AS p  
    ON q.query_id = p.query_id  
JOIN sys.query_store_query_text qt   
    ON qt.query_text_id = q.query_text_id  
ORDER BY query_id, plan_id;

-- 2.6 Queries that recently regressed in performance
--  The following query example returns all queries which execution time was 
--   doubled in last 48 hours.
SELECT 
	qt.query_sql_text, p1.is_forced_plan, p1.is_parallel_plan,
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

-- 2.7 Any plans failing to be forced?

SELECT * FROM sys.query_store_plan WHERE is_forced_plan = 1 AND force_failure_count > 0


-- 2.8 Forcing a plan via T-SQL, Force or a plan for a query (apply forcing policy). 
--When a plan is forced for a certain query, every time a query comes to execution it will be executed with the plan that is forced.

EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 50;  

--When using sp_query_store_force_plan you can only force plans that were recorded by Query Store as a plan for that query. In other words, the only plans available for a query are those that were already used to execute that query while Query Store was active.
--Remove plan forcing for a query. To rely again on the SQL Server query optimizer to calculate the optimal query plan, use sp_query_store_unforce_plan to unforce the plan that was selected for the query.

EXEC sp_query_store_unforce_plan @query_id = 48, @plan_id = 49;  
