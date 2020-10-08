USE msdb;

DECLARE @collection_set_id int;
DECLARE @collection_set_uid uniqueidentifier

EXEC dbo.sp_syscollector_create_collection_set
    @name = N'RGMonCollecter',
    @collection_mode = 0,
    @description = N'This collector will track resource usage over the various resource pools at 5 second intervals',
    @logging_level=1,
    @days_until_expiration = 14,
    @schedule_name=N'CollectorSchedule_Every_15min',
    @collection_set_id = @collection_set_id OUTPUT,
    @collection_set_uid = @collection_set_uid OUTPUT;
SELECT @collection_set_id,@collection_set_uid;

DECLARE @collector_type_uid uniqueidentifier;
SELECT @collector_type_uid = collector_type_uid FROM syscollector_collector_types 
WHERE name = N'Generic T-SQL Query Collector Type';

DECLARE @collection_item_id int;
EXEC sp_syscollector_create_collection_item
@name= N'RGMonCollecter',
@parameters=N'
<ns:TSQLQueryCollector xmlns:ns="DataCollectorType">
<Query>
  <Value>Exec Demos..proc_resourceGovTracker</Value>
  <OutputTable>RGMonCollecter</OutputTable>
</Query>
 </ns:TSQLQueryCollector>',
    @collection_item_id = @collection_item_id OUTPUT,
    @frequency = 5, -- This parameter is ignored in cached mode
    @collection_set_id = @collection_set_id,
    @collector_type_uid = @collector_type_uid;
SELECT @collection_item_id;
   
