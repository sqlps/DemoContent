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

-- Live Query Stats
-- Turn on LQS in SSMS before running this query
USE AdventureWorks2014
GO

DBCC FREEPROCCACHE
DBCC TRACEON (9481)
SET STATISTICS PROFILE ON --OR SET STATISTICS XML ON

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
       CROSS JOIN [Person].[Person] AS p 
      -- ON RTRIM(LTRIM(p.[BusinessEntityID])) = RTRIM(LTRIM(e.[BusinessEntityID])) 
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
