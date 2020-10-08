use mdw
go
alter table [custom_snapshots].[storedprocedure_table_references]
add referencing_object_id int
go
alter table [custom_snapshots].[storedprocedure_table_references]
add referenced_entity_id int
go
update refs
set refs.referencing_object_id =  stats.object_id
from [custom_snapshots].[storedprocedure_usage_stats] stats
inner join [custom_snapshots].[storedprocedure_table_references] refs
	on stats.sp_name = refs.referencing_object_name
go
update refs
set refs.referenced_entity_id = stats.table_id
from [custom_snapshots].[storedprocedure_table_references] refs
inner join [custom_snapshots].[table_usage_stats] stats
	on refs.referenced_entity_name = stats.table_name
go
