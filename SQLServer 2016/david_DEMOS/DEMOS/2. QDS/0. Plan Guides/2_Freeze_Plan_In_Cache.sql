-- Query  Optimization
-- Freeze Plan Guide Demo

/*In this demo, we will create a plan guide from cache. This is also called "Plan Freezing."
To run this, 
	1.	Run the setup from the setup to the end of setup comments.
	2.	Step through the successive steps as the comments direct
*/

/* setup */

USE [AdventureWorks2014];
GO
IF EXISTS (SELECT 1
           FROM   sys.plan_guides
           WHERE  name = 'getAddresses')
          BEGIN
                    EXECUTE sp_control_plan_guide N'drop', 'getAddresses';
          END

IF EXISTS (SELECT 1
           FROM   sys.objects
           WHERE  type = 'P'
                  AND name = 'getRowsByStateProvinceID')
          BEGIN
                    DROP PROCEDURE getRowsByStateProvinceID;
          END
GO

CREATE PROCEDURE getRowsByStateProvinceID
@stateProvinceID INT
AS
SELECT *
FROM   Person.Address AS a
WHERE  a.StateProvinceID = @stateProvinceID;
GO

DBCC FREEPROCCACHE;

SET STATISTICS TIME ON;

 /* End of setup */
 
 /*
After the setup is run, ensure the option to show actual query plan is selected.
*/
-- execute each of the two following sproc calls one at a time

EXECUTE getRowsByStateProvinceID 119; 

EXECUTE getRowsByStateProvinceID 9; 

-- compare the SQL execution times of the two and notice that the plans are expensive
-- than 119

-- clear the cache:

DBCC FREEPROCCACHE;

-- and notice the difference if we execute with 9 first

EXECUTE getRowsByStateProvinceID 9; 

EXECUTE getRowsByStateProvinceID 119; 

/*
	so whether you get a clustered index scan, or a seek and lookup
	depends on which parameter gets executed first. This can be a bad situation
	sometimes. If most times 9 is executed, but 119 gets run first, if this is a
	larger table than we have, this can create a bad performance situation.
	
	In order to prevent this, let's create a plan guide from the one in cache now.
	
	step through these steps to create the plan guide:

*/

-- first, get the plan that is cached:

SELECT s.plan_handle,
       s.statement_start_offset,
       t.text
FROM   sys.dm_exec_query_stats AS s CROSS APPLY sys.dm_exec_sql_text (s.sql_handle) AS t;

-- now use the plan handle, and statement start offset from the line that
-- begins "create procedure getRowsByStateProvinceID" for the next step
-- this step freezes the plan in cache:

EXECUTE sp_create_plan_guide_from_handle @name = N'getAddresses'
,	@plan_handle = 0x05000700B6CF6F30C022989DB200000001000000000000000000000000000000000000000000000000000000 -- change this to the actual plan handle from cache
,	@statement_start_offset = 138 -- change this to the actual offset from cache

-- now clear the cache, and watch what happens if we execute with 119 first:

DBCC FREEPROCCACHE;

-- execute each of these one a time and look at the query plan:

EXECUTE getRowsByStateProvinceID 119;
GO 10000

EXECUTE getRowsByStateProvinceID 9;
10000

-- so now, we always get the plan optimized for the large number of rows.\

-- look at the plan guides we have registered:

SELECT *
FROM   sys.plan_guides;

-- cleanup:
SET STATISTICS TIME OFF;

IF EXISTS (SELECT 1
           FROM   sys.plan_guides
           WHERE  name = 'getAddresses')
          BEGIN
                    EXECUTE sp_control_plan_guide N'drop', 'getAddresses';
          END

