
------ perf comparison
use AdventureWorksDW2012
select count(*) from dbo.CCITest;
--  ~ 9M rows

drop index dateKey_ix on CCITest;

set statistics time on
select count(*),dateKey from dbo.CCITest group by dateKey

-- Heap (no index)
--   CPU time = 2793 ms,  elapsed time = 449 ms. 488MB (page compression 316MB)

CREATE CLUSTERED INDEX dateKey_ix ON CCITest (DateKey);
select count(*),dateKey from dbo.CCITest group by dateKey

-- CPU time = 1546 ms,  elapsed time = 291 ms. 433MB + index (1.3MB)


drop index dateKey_ix on CCITest;
create CLUSTERED COLUMNSTORE index cci on CCITest;
drop index cci on CCITest;

select count(*),dateKey from dbo.CCITest group by dateKey

-- CPU time = 265 ms,  elapsed time = 110 ms. 40MB


-- update example
insert into ccitest select top 100 * from ccitest;
select count(*) as c,dateKey from dbo.CCITest group by dateKey order by c desc



select * from sys.column_store_row_groups;



---------CCI memory usage------
SELECT COUNT(*)AS cached_pages_count 
    ,name ,index_id 
FROM sys.dm_os_buffer_descriptors AS bd 
    INNER JOIN 
    (
        SELECT object_name(object_id) AS name 
            ,index_id ,allocation_unit_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND (au.type = 1 OR au.type = 3)
        UNION ALL
        SELECT object_name(object_id) AS name   
            ,index_id, allocation_unit_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.partition_id 
                    AND au.type = 2
    ) AS obj 
        ON bd.allocation_unit_id = obj.allocation_unit_id
WHERE database_id = db_id()
GROUP BY name, index_id 
ORDER BY cached_pages_count DESC;