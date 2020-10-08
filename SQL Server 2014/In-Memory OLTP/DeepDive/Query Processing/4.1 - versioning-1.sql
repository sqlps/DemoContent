-- ================================ Start of versioning demo - Session 1

-- sample database: [http://msdn.microsoft.com/en-us/library/dn511655.aspx]

-- reset workload
USE AdventureWorks2014
GO
SET NOCOUNT ON
GO
EXEC Demo.usp_DemoReset
GO

ALTER DATABASE AdventureWorks2014 SET OFFLINE WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE AdventureWorks2014 SET ONLINE
GO
USE AdventureWorks2014
GO
-- check row count and memory consumption for SalesOrderDetail table
SELECT COUNT(*) FROM Sales.SalesOrderDetail_inmem

SELECT object_name(t.object_id) AS [Table Name]
     , memory_allocated_for_table_kb
	 , memory_used_by_table_kb
FROM sys.dm_db_xtp_table_memory_stats dms JOIN sys.tables t 
ON dms.object_id=t.object_id
WHERE dms.object_id=object_id('Sales.SalesOrderDetail_inmem')
GO

-- update all rows in table
UPDATE Sales.SalesOrderDetail_inmem
SET ModifiedDate=SYSDATETIME()
GO

-- verify memory usage - note that old row versions are still in the table
SELECT object_name(t.object_id) AS [Table Name]
     , memory_allocated_for_table_kb
	 , memory_used_by_table_kb
FROM sys.dm_db_xtp_table_memory_stats dms JOIN sys.tables t 
ON dms.object_id=t.object_id
WHERE dms.object_id=object_id('Sales.SalesOrderDetail_inmem')

-- verify row count 
SELECT COUNT(*) FROM Sales.SalesOrderDetail_inmem
GO


-- verify current status for sales order 67333
SELECT SalesOrderID, Status
FROM Sales.SalesOrderHeader_ondisk
WHERE SalesOrderID=67333

SELECT SalesOrderID, Status
FROM Sales.SalesOrderHeader_inmem
WHERE SalesOrderID=67333
GO

-- update disk-based table
--step 1
BEGIN TRAN
  UPDATE Sales.SalesOrderHeader_ondisk
    SET Status=6 
    WHERE SalesOrderID=67333
--step 3
COMMIT
GO

-- update memory-optimized table
--step 1
BEGIN TRAN
  UPDATE Sales.SalesOrderHeader_inmem
    SET Status=6 
    WHERE SalesOrderID=67333
--step 3
COMMIT
GO


-- disk-based READCOMMITTED deadlock
-- TxA
-- step 1
BEGIN TRAN
	UPDATE Sales.SalesOrderHeader_ondisk WITH (READCOMMITTED)
    SET Status=8
	WHERE SalesOrderID=67333

-- step 3
	SELECT SalesOrderID, Status 
	FROM Sales.SalesOrderHeader_ondisk WITH (READCOMMITTED)
    WHERE SalesOrderID=67334
COMMIT


-- memory-optimized SNAPSHOT no failure
-- TxA
-- step 1
BEGIN TRAN
	UPDATE Sales.SalesOrderHeader_inmem WITH (SNAPSHOT)
    SET Status=8
	WHERE SalesOrderID=67333

-- step 3
	SELECT SalesOrderID, Status 
	FROM Sales.SalesOrderHeader_inmem WITH (SNAPSHOT)
    WHERE SalesOrderID=67334
COMMIT
