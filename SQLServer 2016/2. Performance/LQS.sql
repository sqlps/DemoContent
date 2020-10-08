-- Live Query Stats
-- Turn on LQS in SSMS before running this query
USE AdventureWorks2014
GO

DBCC FREEPROCCACHE
DBCC TRACEON (9481)

/*Use when running SQL Server 2014 with the default database compatibility level 120. 
Trace flag 9481 forces the query optimizer to use version 70 (the SQL Server 2012 version) 
of the cardinality estimator when creating the query plan.*/

SELECT e.[BusinessEntityID], 
       p.[Title], 
       p.[FirstName], 
       p.[MiddleName], 
       p.[LastName], 
       p.[Suffix], 
       e.[JobTitle], 
       pp.[PhoneNumber], 
       pnt.[Name] AS [PhoneNumberType], 
       ea.[EmailAddress], 
       p.[EmailPromotion], 
       a.[AddressLine1], 
       a.[AddressLine2], 
       a.[City], 
       sp.[Name] AS [StateProvinceName], 
       a.[PostalCode], 
       cr.[Name] AS [CountryRegionName], 
       p.[AdditionalContactInfo] 
FROM   [HumanResources].[Employee] AS e 
       INNER JOIN [Person].[Person] AS p 
       ON RTRIM(LTRIM(p.[BusinessEntityID])) = RTRIM(LTRIM(e.[BusinessEntityID])) 
       INNER JOIN [Person].[BusinessEntityAddress] AS bea 
       ON RTRIM(LTRIM(bea.[BusinessEntityID])) = RTRIM(LTRIM(e.[BusinessEntityID])) 
       INNER JOIN [Person].[Address] AS a 
       ON RTRIM(LTRIM(a.[AddressID])) = RTRIM(LTRIM(bea.[AddressID])) 
       INNER JOIN [Person].[StateProvince] AS sp 
       ON RTRIM(LTRIM(sp.[StateProvinceID])) = RTRIM(LTRIM(a.[StateProvinceID])) 
       INNER JOIN [Person].[CountryRegion] AS cr 
       ON RTRIM(LTRIM(cr.[CountryRegionCode])) = RTRIM(LTRIM(sp.[CountryRegionCode])) 
       LEFT OUTER JOIN [Person].[PersonPhone] AS pp 
       ON RTRIM(LTRIM(pp.BusinessEntityID)) = RTRIM(LTRIM(p.[BusinessEntityID])) 
       LEFT OUTER JOIN [Person].[PhoneNumberType] AS pnt 
       ON RTRIM(LTRIM(pp.[PhoneNumberTypeID])) = RTRIM(LTRIM(pnt.[PhoneNumberTypeID])) 
       LEFT OUTER JOIN [Person].[EmailAddress] AS ea 
       ON RTRIM(LTRIM(p.[BusinessEntityID])) = RTRIM(LTRIM(ea.[BusinessEntityID]))
GO 

--DMV Examples
/*
The following statement summarizes the progress made by the query currently running in session 54. 
To do this, it calculates the total number of output rows from all threads for each node, and compares it to the estimated number of output rows for that node.

--1 SHOW ALL COLUMNS
SELECT * 
FROM sys.dm_exec_query_profiles 
WHERE session_id=51

--2 Run this in a different session than the session in which your query is running. */

--Serialize the requests and return the final results to SHOWPLAN XML 
SELECT node_id,physical_operator_name, SUM(row_count) row_count, 
SUM(estimate_row_count) AS estimate_row_count
--, CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count) 
FROM sys.dm_exec_query_profiles 
WHERE session_id=51 
GROUP BY node_id,physical_operator_name 
ORDER BY node_id;

--3 User db context is not required, 
-- but setting db context to user db to correctly populate object_name function 
USE [AdventureWorks2014]
GO
while (1=1) 
begin 
    if exists (select * from sys.dm_exec_query_profiles p where p.session_id = 51) 
    select top 5 p.plan_handle,  p.physical_operator_name, object_name(p.object_id) objName 
            , p.node_id,  p.index_id, p.cpu_time_ms, p.estimate_row_count 
            , p.row_count, p.logical_read_count, p.elapsed_time_ms, 
            p.read_ahead_count, p.scan_count  
            from sys.dm_exec_query_profiles p 
        where p.session_id = 51 
        order by (p.row_count-p.estimate_row_count) + p.logical_read_count desc 
    waitfor delay '0:0:10' 
End