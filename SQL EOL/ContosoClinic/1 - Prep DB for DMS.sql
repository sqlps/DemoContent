-- ====================================================================
-- Step 1) DMS leverages replication. Need to ensure all tables have PK
-- ====================================================================

USE clinic;
Go
SELECT is_tracked_by_cdc, name AS TableName
  FROM sys.tables WHERE type = 'U' and is_ms_shipped = 0 AND
  OBJECTPROPERTY(OBJECT_ID, 'TableHasPrimaryKey') = 0;

-- ====================================================================
-- Step 2) Bulk create PKs
-- ====================================================================


SELECT 'ALTER TABLE '+t.name+' ADD PRIMARY KEY(ID)'
from sys.tables t
inner join sys.columns c
on t.object_id = c.object_id
WHERE type = 'U' and is_ms_shipped = 0 AND
  OBJECTPROPERTY(t.OBJECT_ID, 'TableHasPrimaryKey') = 0 and c.name = 'id' 


-- ====================================================================
-- Step 2) Bulk add id columns
-- ====================================================================

SELECT 'ALTER TABLE '+t.name+' ADD ID int IDENTITY'
from sys.tables t
WHERE type = 'U' and is_ms_shipped = 0 AND
  OBJECTPROPERTY(t.OBJECT_ID, 'TableHasPrimaryKey') = 0


-- ====================================================================
-- Step 2) Enable CDC (SQL EE Feature)
-- ====================================================================
-- Source: https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/enable-and-disable-change-data-capture-sql-server?view=sql-server-2017
EXEC sys.sp_cdc_enable_db  
GO  