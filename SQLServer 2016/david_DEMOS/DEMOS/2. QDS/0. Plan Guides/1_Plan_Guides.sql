-- Query  Optimization
-- Plan Guide Demo

/*Extended Events:
-Configure an XEvents session 
-Add the plan_guide_successful and plan_guide_unsuccessful event types with sql_text global fields
Find the Plan Guide Successful event for the affected query.*/

USE [AdventureWorks2014]
GO

IF object_id('Sales.GetSalesOrderByCountry') IS NOT NULL
          DROP PROCEDURE Sales.GetSalesOrderByCountry;
GO

CREATE PROCEDURE Sales.GetSalesOrderByCountry
@Country NVARCHAR (60)
AS
BEGIN
          SELECT *
          FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
          WHERE  h.CustomerID = c.CustomerID
                 AND c.TerritoryID = t.TerritoryID
                 AND CountryRegionCode = @Country;
END

-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'UK';

-- take note of the actual vs. estimated rows
-- why is there such a large discrepency?
EXECUTE Sales.GetSalesOrderByCountry 'US';

-- Next, create the plan guide and then rerun the test
EXECUTE sp_create_plan_guide @name = N'PlanGuide_OptimizeForUS', @stmt = N'          SELECT *
          FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
          WHERE  h.CustomerID = c.CustomerID
                 AND c.TerritoryID = t.TerritoryID
                 AND CountryRegionCode = @Country;'
			, @type = N'OBJECT'
			, @module_or_batch = N'Sales.GetSalesOrderByCountry'
			, @params = NULL
			, @hints = N'OPTION (OPTIMIZE FOR (@Country = N''US''))';

-- Run the stored proc and examine the query plan
-- Did the plan change? Did it use the plan guide?
EXECUTE Sales.GetSalesOrderByCountry 'UK';

--What does the U.S. one look like?
EXECUTE Sales.GetSalesOrderByCountry 'US';

--Restart SQL Server and run the following statements. Did the plan guide work? 
EXECUTE Sales.GetSalesOrderByCountry 'GB';
EXECUTE Sales.GetSalesOrderByCountry 'ES';
EXECUTE Sales.GetSalesOrderByCountry 'FR';

--Let's take a look at the distribution of the data
SELECT CountryRegionCode, COUNT(*) AS CountryCount
FROM   Sales.SalesOrderHeader AS h, 
Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
GROUP BY CountryRegionCode

--Clean Up
EXECUTE sp_control_plan_guide N'DROP', N'PlanGuide_OptimizeForUS';

GO
DROP PROCEDURE Sales.GetSalesOrderByCountry;



