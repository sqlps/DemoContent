-- ===================================
-- Step 1) What's waiting right now
-- ===================================

select s.session_id, 
s.host_name, 
s.program_name,
r.status,
r.wait_type,
r.wait_time,
r.last_wait_type,
r.total_elapsed_time,
r.logical_reads,
r.reads,
r.writes,
SUBSTRING(st.text, (r.statement_start_offset/2)+1, 
  ((CASE r.statement_end_offset
    WHEN -1 THEN DATALENGTH(st.text)
    ELSE r.statement_end_offset
    END - r.statement_start_offset)/2) + 1) AS statement_text,
qp.query_plan
from sys.dm_exec_requests r
join sys.dm_exec_sessions s
  on r.session_id = s.session_id 
cross apply sys.dm_exec_query_plan(r.plan_handle) qp
outer apply sys.dm_exec_sql_text(r.sql_handle) st
where r.plan_handle is not null 
and r.session_id <> @@spid
order by logical_reads desc

