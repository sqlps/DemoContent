Use IMOLTP_DEMO
go

--Memory used
Select SUM(Memory_allocated_for_indexes_kb + memory_allocated_for_table_kb)/1024 as memoryallocated_objects_in_mb,
		Sum (memory_used_by_indexes_kb + memory_used_by_table_kb)/1024 as memoryused_objects_in_mb
		From sys.dm_db_xtp_table_memory_stats

--GC Monitor
Select queue_id, total_enqueues, total_dequeues, current_queue_depth, maximum_queue_depth
from sys.dm_xtp_gc_queue_stats