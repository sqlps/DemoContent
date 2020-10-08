/* This Sample Code is provided for the purpose of illustration only and is not intended 
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE 
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR 
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You 
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or 
result from the use or distribution of the Sample Code.
*/

-- Online Ops Demo - Lock Priority


-- Step 1 - View existing partition
USE AdventureWorks
go
--List all partitions
select * from sys.partitions where object_id=object_id('Production.Transactionhistory')
go
-- Select from first partition of main table which will be switched out
select * from Production.Transactionhistory where TransactionDate <= '2012-02-01 00:00:00.000'
go

-- Step 2 - Start a blocking transaction in partition 1 before switching partition
-- IMPORTANT!!! Run the script in Online Ops - Lock Priority Demo Helper Script file

-- Step 3 - Truncate staging table first before switching (needs to be empty to switch into)
truncate table Production.Transactionhistory_staging
GO

-- Make sure it is empty
select * from Production.Transactionhistory_staging
GO

-- SQL Server 2012, this query will be blocked till the lock is released
-- After running for a while, cancel this query manually
ALTER TABLE Production.Transactionhistory SWITCH PARTITION 1 TO Production.Transactionhistory_staging PARTITION 1 
go

--Run a Select and notice how it's blocked
select Top 10 * from Production.Transactionhistory where TransactionDate <= '2012-02-01 00:00:00.000'
go

--Switch the partition (kill blockers and let this go thru)
ALTER TABLE Production.Transactionhistory SWITCH PARTITION 1 TO Production.Transactionhistory_staging PARTITION 1 
WITH (WAIT_AT_LOW_PRIORITY (MAX_DURATION= 1, ABORT_AFTER_WAIT=BLOCKERS)) 
--WITH (WAIT_AT_LOW_PRIORITY (MAX_DURATION= 1, ABORT_AFTER_WAIT=SELF))  

GO

--How's the blocking going?
select top 10 * from Production.Transactionhistory where TransactionDate <= '2012-02-01 00:00:00.000'
go

-- Check that the data in the first partition is no longer there to make sure the partition switching did happen
select * from Production.Transactionhistory where TransactionDate <= '2012-02-01 00:00:00.000'
go

-- Check that the data is in staging partition already
select * from Production.Transactionhistory_staging
GO

-- Clean up - drop ADWorks database
USE [master]
GO
DROP DATABASE [AdventureWorks]
GO