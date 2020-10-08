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

Set Statistics IO, Time ON

/***********************************************************************
 NEVER RUN THE BELOW TWO COMMANDS IN PRODUCTION
 UNLESS YOU HAVE A REASON TO. THIS WILL ESSENTIALLY
 ELIMINATE THE BUFFER CACHE AND PLAN CACHE THAT SQL SERVER HAS BUILT UP
 ***********************************************************************/
DBCC DROPCLEANBUFFERS 
DBCC FREEPROCCACHE
GO

USE [AdventureWorksDW2008BigOrig]
GO

--(Almost) fully parallel plan

select f.SalesTerritoryKey, t.SalesTerritoryCountry, COUNT(*) SalesCount, SUM(f.SalesAmount) SalesAmount
from dbo.FactResellerSalesPart f  , dbo.DimSalesTerritory t
where f.SalesTerritoryKey = t.SalesTerritoryKey
and t.SalesTerritoryCountry <> 'United States'
group by f.SalesTerritoryKey, t.SalesTerritoryCountry
Option (MAXDOP  1)
--Search for NonParallelPlanReason in XML


-- Look at Plan Cache find issues

GO


