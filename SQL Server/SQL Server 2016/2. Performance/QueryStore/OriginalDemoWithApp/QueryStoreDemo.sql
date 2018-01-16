-- 1. Enable the Query Store on the AdventureWorks2014 database either via SSMS or the following query

ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON;

-- 2. To make the demo more interesting, changes the settings of the query store to aggregate query
--    data every minute and flush every 5 minutes.  Do this via SSMS or the following query

ALTER DATABASE AdventureWorks2014
SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 1, DATA_FLUSH_INTERVAL_SECONDS = 300);

-- 3. Once the query store is configured, start the query workload before continuing with the demo so there is time to collect data
--    Start the workload by executing QueryStoreDemo.cmd
--    NOTE: you will need to alter this file to point to your server

-- 4. View Query Store Settings - Start with SSMS GUI, then execute the following query

SELECT * 
FROM sys.database_query_store_options

-- 5. After a minute or two, you should have some data in the query store.  Start exploring the Query Store through the GUI by launching the Top Resource Consuming Queries view
--    Browse around as desired showing the different features, show how to force and unforce a plan
--    If you like, use the queries below to show how to get this information programmatically
--    Run some of the standard query reports to show that sys.dm_exec_query_stats doesn't have much data in it (the command file is flushing the proc cache every 10 seconds)

--The number of queries with the longest average execution time within last hour.
SELECT TOP 10 rs.avg_duration, qt.query_sql_text, q.query_id,
    qt.query_text_id, p.plan_id, GETUTCDATE() AS CurrentUTCTime, 
    rs.last_execution_time 
FROM sys.query_store_query_text AS qt 
JOIN sys.query_store_query AS q 
    ON qt.query_text_id = q.query_text_id 
JOIN sys.query_store_plan AS p 
    ON q.query_id = p.query_id 
JOIN sys.query_store_runtime_stats AS rs 
    ON p.plan_id = rs.plan_id
WHERE rs.last_execution_time > DATEADD(hour, -1, GETUTCDATE())
ORDER BY rs.avg_duration DESC;

-- Queries with multiple plans.
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

SELECT q.query_id, object_name(object_id) AS ContainingObject, query_sql_text,
plan_id, p.query_plan AS plan_xml,
p.last_compile_start_time, p.last_execution_time
FROM Query_MultPlans AS qm
JOIN sys.query_store_query AS q
    ON qm.query_id = q.query_id
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_query_text qt 
    ON qt.query_text_id = q.query_text_id
ORDER BY query_id, plan_id;

-- Queries that recently regressed in performance (comparing different point in time). The following query example returns all queries for which execution 
-- time doubled in last 48 hours due to a plan choice change. Query compares all runtime stat intervals side by side. 

SELECT 
    qt.query_sql_text, 
    q.query_id, 
    qt.query_text_id, 
    rs1.runtime_stats_id AS runtime_stats_id_1,
    rsi1.start_time AS interval_1, 
    p1.plan_id AS plan_1, 
    rs1.avg_duration AS avg_duration_1, 
    rs2.avg_duration AS avg_duration_2,
    p2.plan_id AS plan_2, 
    rsi2.start_time AS interval_2, 
    rs2.runtime_stats_id AS runtime_stats_id_2
FROM sys.query_store_query_text AS qt 
JOIN sys.query_store_query AS q 
    ON qt.query_text_id = q.query_text_id 
JOIN sys.query_store_plan AS p1 
    ON q.query_id = p1.query_id 
JOIN sys.query_store_runtime_stats AS rs1 
    ON p1.plan_id = rs1.plan_id 
JOIN sys.query_store_runtime_stats_interval AS rsi1 
    ON rsi1.runtime_stats_interval_id = rs1.runtime_stats_interval_id 
JOIN sys.query_store_plan AS p2 
    ON q.query_id = p2.query_id 
JOIN sys.query_store_runtime_stats AS rs2 
    ON p2.plan_id = rs2.plan_id 
JOIN sys.query_store_runtime_stats_interval AS rsi2 
    ON rsi2.runtime_stats_interval_id = rs2.runtime_stats_interval_id
WHERE rsi1.start_time > DATEADD(hour, -48, GETUTCDATE()) 
    AND rsi2.start_time > rsi1.start_time 
    AND p1.plan_id <> p2.plan_id
    AND rs2.avg_duration > 2*rs1.avg_duration
ORDER BY q.query_id, rsi1.start_time, rsi2.start_time;

-- 6. Clean Up - once you're done, go back to the original command prompt and hit any key, this will kill the sqlcmd tasks

