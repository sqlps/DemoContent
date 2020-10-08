-- ======================================================================
-- Step 1) Collect waits now between a 5 sec time slice
-- ======================================================================

--First what is SQL Server waiting on right now
SELECT wait_type , waiting_tasks_count 
     , wait_time_ms , max_wait_time_ms  
     , signal_wait_time_ms
    INTO #OriginalWaitStatsSnapshot
    FROM sys.dm_os_wait_stats;
GO
--wait for x amount of time
WAITFOR DELAY '00:00:05';
GO
--collect again
SELECT wait_type , waiting_tasks_count 
     , wait_time_ms , max_wait_time_ms  
     , signal_wait_time_ms
    INTO #LatestWaitStatsSnapshot
    FROM sys.dm_os_wait_stats;
GO
--compare the results
SELECT l.wait_type , (l.wait_time_ms - o.wait_time_ms) as accum_wait_ms
  FROM #OriginalWaitStatsSnapshot as o
      INNER JOIN #LatestWaitStatsSnapshot as l
          ON o.wait_type = l.wait_type
  WHERE l.wait_time_ms > o.wait_time_ms
  ORDER BY 2 DESC;
GO

Drop Table #LatestWaitStatsSnapshot
Drop Table #OriginalWaitStatsSnapshot

-- ======================================================================
-- Step 2) What has SQL Server been waiting on since the server started
-- ======================================================================
WITH Waits AS 
 ( 
 SELECT  
   wait_type,  
   wait_time_ms / 1000. AS wait_time_s, 
   100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct, 
   ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn 
 FROM sys.dm_os_wait_stats 
 WHERE wait_type  
   NOT IN 
     ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 
   'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 
   'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT') 
   ) -- filter out additional irrelevant waits 
    
SELECT W1.wait_type, 
 CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s, 
 CAST(W1.pct AS DECIMAL(12, 2)) AS pct, 
 CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct 
FROM Waits AS W1 
 INNER JOIN Waits AS W2 ON W2.rn <= W1.rn 
GROUP BY W1.rn,  
 W1.wait_type,  
W1.wait_time_s,  
 W1.pct 
order by 3 desc--HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold;

--What's currently waiting
SELECT w.session_id
     , w.wait_duration_ms
     , w.wait_type
     , w.blocking_session_id
     , w.resource_description
     , s.program_name
     , t.text
     , t.dbid
     , s.cpu_time
     , s.memory_usage
 FROM sys.dm_os_waiting_tasks as w
      INNER JOIN sys.dm_exec_sessions as s
         ON w.session_id = s.session_id
      INNER JOIN sys.dm_exec_requests as r 
         ON s.session_id = r.session_id
      OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) as t
  WHERE s.is_user_process = 1;
