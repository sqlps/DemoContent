Use [AdventureWorksDW2012]
Go

sp_spaceused 'FactResellerSalesPartCopy' --Get the size of the base table.
go

SELECT SUM(s.used_page_count) / 128.0 as 'CSI on_disk_size_MB'
FROM sys.indexes AS i 
JOIN sys.dm_db_partition_stats AS S 
ON i.object_id = S.object_id 
and I.index_id = S.index_id 
WHERE i.object_id = object_id('FactResellerSalesPartCopy') 
AND i.type_desc = 'NONCLUSTERED COLUMNSTORE' 
go

-- size per column 
with segment_size_by_column as ( 
SELECT 
p.object_id as table_id, 
css.column_id, 
SUM (css.on_disk_size)/1024/1024.0 AS segment_size_mb 
FROM sys.partitions AS p 
JOIN sys.column_store_segments AS css 
ON p.hobt_id = css.hobt_id 
GROUP BY p.object_id, css.column_id 
), 
dictionary_size_by_column as ( 
SELECT 
p.object_id as table_id, 
csd.column_id, 
SUM (csd.on_disk_size)/1024/1024.0 AS dictionary_size_mb 
FROM sys.partitions AS p 
JOIN sys.column_store_dictionaries AS csd 
ON p.hobt_id = csd.hobt_id 
GROUP BY p.object_id, csd.column_id 
) 
-- It may be that not all the columns in a table will be or can be included 
-- in a nonclustered columnstore index, 
-- so we need to join to the sys.index_columns to get the correct column id. 
Select Object_Name(s.table_id) as table_name, C.column_id, 
col_name(S.table_id, C.column_id) as column_name, s.segment_size_mb, 
d.dictionary_size_mb, s.segment_size_mb + isnull(d.dictionary_size_mb, 0) total_size_mb 
from segment_size_by_column s 
join 
sys.indexes I -- Join to Indexes system table 
ON I.object_id = s.table_id 
join 
sys.index_columns c --Join to Index columns 
ON c.object_id = s.table_id 
And I.index_id = C.index_id 
and c.index_column_Id = s.column_id --Need to join to the index_column_id with the column_id 
left outer join 
dictionary_size_by_column d 
on s.table_id = d.table_id 
and s.column_id = d.column_id 
Where I.type_desc = 'NONCLUSTERED COLUMNSTORE' 
order by total_size_mb desc 
go 
