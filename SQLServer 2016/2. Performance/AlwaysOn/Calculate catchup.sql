use master
go

declare @rate float
declare @logSizeStart bigint
select @rate = case when log_bytes_send_rate > redo_rate 
OR 0 = log_bytes_send_rate then redo_rate
else log_bytes_send_rate
end
from sys.dm_hadr_database_replica_states
where is_local = 0


if(@rate <= 0)
  set @rate = 1

 
--select @rate
 
select log_send_queue_size * 1024.0,
log_bytes_send_rate,
redo_rate,
redo_queue_size * 1024.0,
(log_send_queue_size*1024.0) + (redo_queue_size*1024) as 
[TotalSendAndRedoSize],
@rate as SlowestRate,
(((log_send_queue_size*1024.0) + (redo_queue_size*1024)) / @rate) 
as CatchUpEstimatedSeconds, 
synchronization_state_desc, *
from sys.dm_hadr_database_replica_states
where is_local = 0　

select @logSizeStart = (log_send_queue_size * 1024)
from sys.dm_hadr_database_replica_states
where is_local = 0
waitfor delay '00:00:01'
select @rate = (@logSizeStart - (log_send_queue_size * 1024))/1
from sys.dm_hadr_database_replica_states
where is_local = 0

--select @rate
if(@rate <= 0)
set @rate = 1

select log_send_queue_size * 1024.0,
log_bytes_send_rate,
redo_rate,
redo_queue_size * 1024.0,
(log_send_queue_size*1024.0) + (redo_queue_size*1024) as [TotalSendAndRedoSize],
@rate as SlowestRate,
(((log_send_queue_size*1024.0) + (redo_queue_size*1024)) / @rate) 
as CatchUpEstimatedSeconds, 
synchronization_state_desc, *
from sys.dm_hadr_database_replica_states
where is_local = 0
select * from sys.availability_groups

 
