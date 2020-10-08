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

-- Online Ops Demo - Online Index Rebuild on Partition


-- Step 1 - Before doing index rebuild, check fragmentation on each partition
USE AdventureWorks
GO
-- check fragmentation to show it is very fragmented
DECLARE @db_id SMALLINT = DB_ID(N'AdventureWorks');
DECLARE @object_id INT = OBJECT_ID(N'Production.Transactionhistory');

--PAY ATTENTION TO FRAGMENTATION OF PARTITION 1
SELECT database_id, index_id, index_depth, partition_number, avg_fragmentation_in_percent, record_count 
from sys.dm_db_index_physical_stats(@db_id, @object_id, NULL, NULL , 'DETAILED') 
where avg_fragmentation_in_percent <>0
and index_level=0;
GO

-- Step 2 - Start a blocking transaction in partition 1 before index rebuild
-- IMPORTANT!!! Run the 1st portion of the script "6b. - Online Ops - Blocker.sql"

-- Step 2a - SQL Server 2012 : OFFLINE partition rebuild. This statement will wait forever as there is a blocking transaction. (CTRL + 3)
-- Cancel this manually after a while
ALTER INDEX PK_TransactionHistory_fragment_TransactionID ON Production.Transactionhistory 
REBUILD PARTITION=1
WITH (ONLINE=ON)

-- Step 3 - SQL Server 2014: Rebuild the first partition online with lock priority
-- Step 3a - RUn the Rebuild the first partition online with lock priority
ALTER INDEX PK_TransactionHistory_fragment_TransactionID ON Production.Transactionhistory 
REBUILD PARTITION=1
WITH (ONLINE = ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION= 1, ABORT_AFTER_WAIT=BLOCKERS)));
--WITH (ONLINE = ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION= 1, ABORT_AFTER_WAIT=SELF)));
GO

-- Step 3b - Check Fragmentation again (after reindex) - should be lower number now
SELECT database_id, index_id, index_depth, partition_number, avg_fragmentation_in_percent, record_count, * 
from sys.dm_db_index_physical_stats(DB_ID(N'AdventureWorks'), OBJECT_ID(N'Production.Transactionhistory'), NULL, NULL , 'DETAILED') 
where 
index_level = 0
and index_id=1
and partition_number=1
GO
