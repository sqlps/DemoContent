-- ===================================
-- Step 1) Look at scheduler Health
-- ===================================

--Max Worker Config
sp_configure 'max worker threads'

--Validate the number
Select max_workers_count, cpu_count, hyperthread_ratio, *
from sys.dm_os_sys_info

--Current Scheduler health
SELECT scheduler_id, status, is_idle, active_workers_count, current_tasks_count, runnable_tasks_count, current_workers_count, work_queue_count, pending_disk_io_count, failed_to_create_worker
FROM SYS.dm_os_schedulers
Where status = 'VISIBLE ONLINE' 

--What's waiting on CPU time
Select * from sys.dm_exec_requests
where status='runnable'