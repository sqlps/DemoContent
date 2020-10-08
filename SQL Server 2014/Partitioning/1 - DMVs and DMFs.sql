Use AdventureWorksDW2008Big
GO

--Rows per partition
SELECT 
	OBJECT_NAME(SI.object_id) AS PartitionedTable
	, DS.name AS PartitionScheme
	, PF.name AS PartitionFunction
	, P.partition_number
	, P.rows
FROM sys.partitions AS P
JOIN sys.indexes AS SI
	ON P.object_id = SI.object_id AND P.index_id = SI.index_id 
JOIN sys.data_spaces AS DS
	ON DS.data_space_id = SI.data_space_id
JOIN sys.partition_schemes AS PS
	ON PS.data_space_id = SI.data_space_id
JOIN sys.partition_functions AS PF
	ON PF.function_id = PS.function_id 
WHERE DS.type = 'PS'
AND OBJECTPROPERTYEX(SI.object_id, 'BaseType') = 'U'
AND SI.type IN(0,1); 

--Next used Info
SELECT 
	  SPS.name AS PartitionSchemeName
	, CASE WHEN SDD.destination_id <= SPF.fanout THEN SDD.destination_id
		ELSE NULL END AS PartitionID
	, SPF.name AS PartitionFunctionName
	, SPRV.value AS BoundaryValue
	, CASE WHEN SDD.destination_id > SPF.fanout THEN 1 
		ELSE 0 END AS NextUsed
	, SF.name AS FileGroup
FROM sys.partition_schemes AS SPS
JOIN sys.partition_functions AS SPF 
	ON SPS.function_id = SPF.function_id
JOIN sys.destination_data_spaces AS SDD 
	ON SDD.partition_scheme_id = SPS.data_space_id
JOIN sys.filegroups AS SF 
	ON SF.data_space_id = SDD.data_space_id
LEFT JOIN sys.partition_range_values AS SPRV 
	ON SPRV.function_id = SPF.function_id
	AND SDD.destination_id = 
CASE WHEN SPF.boundary_value_on_right = 0 THEN SPRV.boundary_id
	ELSE SPRV.boundary_id + 1 END 

--Layout of Data in various Partitions
SELECT
tbl.name AS [TableName],
scm.name AS [SchemaName],
ds.name AS [PartitinSchemeName],
pf.name AS [PartitionFunctionName],
c.name AS [PartitionColumnName],
p.partition_number AS [PartitionNumber],
prv.value AS [RightBoundaryValue],
CAST(p.rows AS float) AS [RowCount],
fg.name AS [FileGroupName],
CAST(pf.boundary_value_on_right AS int) AS [RangeType],
p.data_compression AS [DataCompression],
p.data_compression_desc AS [DataCompressionDesc]
FROM
sys.tables AS tbl
INNER JOIN sys.schemas as scm  ON tbl.schema_id=scm.schema_id
INNER JOIN sys.indexes AS idx ON idx.object_id = tbl.object_id and idx.index_id < 2
INNER JOIN sys.partitions AS p ON p.object_id=CAST(tbl.object_id AS int) AND p.index_id=idx.index_id
INNER JOIN sys.indexes AS indx ON p.object_id = indx.object_id and p.index_id = indx.index_id
INNER JOIN sys.index_columns ic ON (ic.partition_ordinal > 0) AND (ic.index_id=idx.index_id AND ic.object_id=CAST(tbl.object_id AS int))
INNER JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
LEFT OUTER JOIN sys.destination_data_spaces AS dds ON dds.partition_scheme_id = indx.data_space_id and dds.destination_id = p.partition_number
LEFT OUTER JOIN sys.data_spaces AS ds ON ds.data_space_id=dds.partition_scheme_id
LEFT OUTER JOIN sys.partition_schemes AS ps ON ps.data_space_id = indx.data_space_id
LEFT OUTER JOIN sys.partition_range_values AS prv ON prv.boundary_id = p.partition_number and prv.function_id = ps.function_id
LEFT OUTER JOIN sys.filegroups AS fg ON  fg.data_space_id = dds.data_space_id or fg.data_space_id = indx.data_space_id
LEFT OUTER JOIN sys.partition_functions AS pf ON  pf.function_id = prv.function_id
WHERE EXISTS
      (SELECT DISTINCT OBJECT_NAME([object_id])
      FROM sys.partitions AS ps
      WHERE tbl.name=OBJECT_NAME([object_id])
      AND   partition_number > 1
      AND     OBJECTPROPERTY([object_id],'IsTable') = 1
      )
ORDER BY TableName,PartitionNumber

--What Partition do I belong to?
select $PARTITION.ByOrderDateMonthPF(20020701) 

