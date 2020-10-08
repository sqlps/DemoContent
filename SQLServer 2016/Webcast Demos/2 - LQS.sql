-- Live Query Stats
-- Turn on LQS in SSMS before running this query
USE AdventureWorks2014
GO

DBCC FREEPROCCACHE
SET STATISTICS PROFILE OFF --OR SET STATISTICS XML ON

SELECT e.[BusinessEntityID], 
       p.[Title], 
       p.[FirstName], 
       p.[MiddleName], 
       p.[LastName], 
       p.[Suffix], 
       e.[JobTitle], 
       p.[EmailPromotion], 
       p.[AdditionalContactInfo] 
FROM   [HumanResources].[Employee] AS e, [Person].[Person] AS p 
--Where RTRIM(LTRIM(p.[BusinessEntityID])) = RTRIM(LTRIM(e.[BusinessEntityID])) -- Should Avoid, easy to cause a cartesian product

 
GO 
