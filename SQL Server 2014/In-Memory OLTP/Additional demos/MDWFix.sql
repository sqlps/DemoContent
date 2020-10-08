
  
use mdw
go
alter table [custom_snapshots].[database_transaction_stats]
add database_id int
go

alter table custom_snapshots.metadata_table_blockers
add database_id int
go

alter table custom_snapshots.metadata_table_blockers 
add table_id int
go

update mb
set mb.table_id = t.table_id
from [custom_snapshots].[table_usage_stats] t
inner join custom_snapshots.metadata_table_blockers mb
on t.table_name = mb.table_name 
go

update b
set b.database_id = c.database_id
from custom_snapshots.table_usage_stats c
inner join  custom_snapshots.metadata_table_blockers b
on c.database_name = b.database_name
go

update s
set s.database_id = c.database_id
from custom_snapshots.table_usage_stats c
inner join  custom_snapshots.database_transaction_stats s
on c.database_name = s.database_name
go