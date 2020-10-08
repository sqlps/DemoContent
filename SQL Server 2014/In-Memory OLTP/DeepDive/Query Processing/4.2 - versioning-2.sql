-- ================================ Start of versioning demo - Session 2

-- sample database: [http://msdn.microsoft.com/en-us/library/dn511655.aspx]

USE AdventureWorks2014
GO
SET NOCOUNT ON
GO

-- update disk-based table
--step 2
SELECT SalesOrderID, Status
FROM Sales.SalesOrderHeader_ondisk
WHERE SalesOrderID=67333
GO

-- update memory-optimized table
--step 2
SELECT SalesOrderID, Status
FROM Sales.SalesOrderHeader_inmem
WHERE SalesOrderID=67333
GO
--step 4
SELECT SalesOrderID, Status
FROM Sales.SalesOrderHeader_inmem
WHERE SalesOrderID=67333
GO

-- disk-based READCOMMITTED deadlock
-- TxB
-- step 2
BEGIN TRAN
	UPDATE Sales.SalesOrderHeader_ondisk WITH (READCOMMITTED)
    SET Status=8
	WHERE SalesOrderID=67334

-- step 4
	SELECT SalesOrderID, Status 
	FROM Sales.SalesOrderHeader_ondisk WITH (READCOMMITTED)
    WHERE SalesOrderID=67333
COMMIT


-- memory-optimized SNAPSHOT no failure
-- TxB
-- step 2
BEGIN TRAN
	UPDATE Sales.SalesOrderHeader_inmem WITH (SNAPSHOT)
    SET Status=8
	WHERE SalesOrderID=67334

-- step 4
	SELECT SalesOrderID, Status 
	FROM Sales.SalesOrderHeader_inmem WITH (SNAPSHOT)
    WHERE SalesOrderID=67333
COMMIT
