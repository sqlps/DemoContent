USE AdventureWorks2016
GO

-- Lab 1 Create Temporal Tables
-- 1.1 Create a new Temporal table
CREATE TABLE dbo.Customer(
CustomerID int NOT NULL PRIMARY KEY CLUSTERED,
PersonID int NULL,
StoreID int NULL,
TerritoryID int NULL,
AccountNumber nvarchar(25),
SysStartTime datetime2 GENERATED ALWAYS AS ROW START NOT NULL,
SysEndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL,  
PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)  
) 
WITH (SYSTEM_VERSIONING = ON)
GO

-- 1.2 Create a history table for an existing table and add SysStartTime and SysEndTime
CREATE TABLE Person.BusinessEntityContactHistory(
BusinessEntityID int NOT NULL,
PersonID int NOT NULL,
ContactTypeID int NOT NULL,
rowguid uniqueidentifier ROWGUIDCOL  NOT NULL,
ModifiedDate datetime NOT NULL,
--Add new columns
SysStartTime datetime2 NOT NULL,
SysEndTime datetime2 NOT NULL
)
GO

-- 1.3 Add new columns for the period boundaries
ALTER TABLE Person.BusinessEntityContact
ADD SysStartTime datetime2 GENERATED ALWAYS AS ROW START NOT NULL DEFAULT GETUTCDATE(),
	SysEndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL DEFAULT CAST('9999-12-31 23:59:59.9999999' AS datetime2),
	PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
GO

-- 1.4 Make the table temporal and link it to the history table
ALTER TABLE Person.BusinessEntityContact
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Person.BusinessEntityContactHistory))
GO

-- Lab 2 Temporal Data and Metadata
-- 2.1 Select rows from the history table
SELECT * FROM Person.BusinessEntityContactHistory 
GO

-- 2.2 Update some rows in the temporal table
UPDATE Person.BusinessEntityContact
SET ContactTypeID = 19
WHERE ContactTypeID = 17
GO

-- Now look at the history table again
SELECT * FROM Person.BusinessEntityContactHistory 
GO

 -- 2.3 Get full information about temporal tables, including referenced history tables 
SELECT T1.name as TemporalTableName, SCHEMA_NAME(T1.schema_id) AS TemporalTableSchema,
T2.name as HistoryTableName, SCHEMA_NAME(T2.schema_id) AS HistoryTableSchema,
T1.temporal_type_desc
FROM sys.tables T1
LEFT JOIN sys.tables T2 
ON T1.history_table_id = T2.object_id
WHERE T1.temporal_type <> 0
ORDER BY T1.history_table_id DESC
GO

 -- 2.4 Period and period columns
SELECT P.name as PeriodName, T.name as TemporalTableName,
c1.name as StartPeriodColumnName, c2.name as EndPeriodColumnName
FROM sys.periods P
INNER JOIN sys.tables T ON P.object_id = T.object_id
INNER JOIN sys.columns c1 ON T.object_id = c1.object_id 
	AND p.start_column_id = c1.column_id
INNER JOIN sys.columns c2 ON T.object_id = c2.object_id 
	AND p.end_column_id = c2.column_id
GO

-- Lab 3 Querying Temporal Data
-- 3.1 Select current rows (should return 0 rows)
SELECT * FROM Person.BusinessEntityContact
WHERE ContactTypeID = 17
GO

-- 3.2 Select rows AS OF a point in time past
SELECT * FROM Person.BusinessEntityContact
--get the system start time from the history table that was updated in 2.2
FOR SYSTEM_TIME AS OF '2015-05-29 15:23:04.7570000'
WHERE ContactTypeID = 17
GO

-- 3.3 Select rows that are current and fully contained in a range of time
-- (the records won't be current before or after the time period)
-- Get these 2 values from the SysStartTime and SysEndTime from the history table in 2.2 above
DECLARE @Start datetime2 = '2015-05-29 15:23:04.7570000'
DECLARE @End datetime2 = '2015-05-29 15:23:10.1165968'
SELECT * FROM Person.BusinessEntityContact
FOR SYSTEM_TIME CONTAINED IN(@Start, @End)
WHERE ContactTypeID = 17

-- Now add some time to the start time, but make it still before the end time.
-- Rerun the query and you should see no rows.


-- 3.4 Select rows that were current between 2 points in time
-- (includes overlaps both before and after)
-- Get these 2 values from the SysStartTime and SysEndTime from the history table in 2.2 above
DECLARE @Start datetime2 = '2015-05-29 15:23:05.7570000'
DECLARE @End datetime2 = '2015-05-29 15:23:10.1165968'
SELECT * FROM Person.BusinessEntityContact
FOR SYSTEM_TIME BETWEEN @Start AND @End
WHERE ContactTypeID = 17;
GO

-- Now add some time to the start time, but make it still before the end time.
-- Rerun the query and you should still see the same rows because BETWEEN includes overlaps.

-- Exercise - Query a veiw containing temporal tables
CREATE VIEW Person.vw_BEContactSummary
AS
SELECT P.BusinessEntityID AS PersonID, P.FirstName, P.LastName,
BEC.BusinessEntityID, CT.ContactTypeID, Name, A.AddressLine1, A.City, A.PostalCode
FROM [Person].[BusinessEntityContact] BEC
INNER JOIN [Person].[BusinessEntityAddress] BEA ON BEC.BusinessEntityID = BEA.BusinessEntityID
INNER JOIN [Person].[Address] A ON BEA.AddressID = A.AddressID
INNER JOIN [Person].[Person] P ON BEC.PersonID = P.BusinessEntityID
INNER JOIN [Person].[ContactType] CT ON BEC.ContactTypeID = CT.ContactTypeID
GO

SELECT * FROM Person.vw_BEContactSummary
FOR SYSTEM_TIME AS OF '2015-05-29 15:23:15.7570000'
WHERE ContactTypeID = 17
GO

-- Exercise 4 - Maintaining Temporal Indexes
-- These actions can be conducted as they would be on standard tables
-- 4.1 Rebuild all indexes on current and history table 
ALTER INDEX ALL ON Person.BusinessEntityContact REBUILD
GO
ALTER INDEX ALL ON Person.BusinessEntityContactHistory REBUILD
GO

-- 4.2 Create stats specifically on the history table
CREATE STATISTICS [BusEntContact_BusEnt] 
ON Person.BusinessEntityContact([BusinessEntityID])
GO

-- 4.3 Apply different compression on history table 
ALTER TABLE Person.BusinessEntityContact
REBUILD WITH (DATA_COMPRESSION = PAGE)
GO

-- Operations that change data in the history table require system-versioning to be disabled beforehand
-- 4.4 Archive older rows into an archive table and remove them from the history table
-- First, create the History Archive table
SELECT TOP 0 * INTO Person.BusinessEntityContactHistoryArchive
FROM Person.BusinessEntityContactHistory
GO

--Disable system versioning
ALTER TABLE Person.BusinessEntityContact
	SET (SYSTEM_VERSIONING = OFF)
GO

--Move rows to archive and remove them from history
--(A partition switch would be more likely in a production system)
INSERT INTO Person.BusinessEntityContactHistoryArchive
SELECT * FROM Person.BusinessEntityContactHistory
GO
DELETE FROM Person.BusinessEntityContactHistory
GO

    --Re-establish versioning again
ALTER TABLE Person.BusinessEntityContact
	SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE=Person.BusinessEntityContactHistory, 
	DATA_CONSISTENCY_CHECK = OFF))
GO






