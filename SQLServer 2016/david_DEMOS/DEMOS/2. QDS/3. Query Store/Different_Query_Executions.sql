SELECT h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear
FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
AND CountryRegionCode = 'US'
GO

/*STORED PROCEDURE EXECUTION*/
/*CREATE PROCEDURE Sales.GetSalesOrderByCountry
@Country NVARCHAR (60)
AS
BEGIN
          SELECT *
          FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
          WHERE  h.CustomerID = c.CustomerID
                 AND c.TerritoryID = t.TerritoryID
                 AND CountryRegionCode = @Country;
END
*/
-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'UK';

-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'US';

-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'GB';

-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'DE';

-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'CA';

-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'FR';

-- Run the stored proc and examine the query plan
EXECUTE Sales.GetSalesOrderByCountry 'AU';
GO
/*Writing a query with parameters*/

DECLARE @Country nvarchar(3)
SET @Country = 'UK'
SELECT *
FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
AND CountryRegionCode = @Country;
GO

DECLARE @Country nvarchar(3)
SET @Country = 'US'
SELECT *
FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
AND CountryRegionCode = @Country;
GO

DECLARE @Country nvarchar(3)
SET @Country = 'GB'
SELECT *
FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
AND CountryRegionCode = @Country;
GO

DECLARE @Country nvarchar(3)
SET @Country = 'DE'
SELECT *
FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
AND CountryRegionCode = @Country;
GO

DECLARE @Country nvarchar(3)
SET @Country = 'CA'
SELECT *
FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
AND CountryRegionCode = @Country;
GO

DECLARE @Country nvarchar(3)
SET @Country = 'FR'
SELECT *
FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
AND CountryRegionCode = @Country;
GO

DECLARE @Country nvarchar(3)
SET @Country = 'AU'
SELECT *
FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
WHERE  h.CustomerID = c.CustomerID
AND c.TerritoryID = t.TerritoryID
AND CountryRegionCode = @Country;
GO

/*Using Exec*/

DECLARE @sqlCommand varchar(1000)
DECLARE @columnList varchar(200)
DECLARE @Country nvarchar(3)
DECLARE @Tick char(1)
SET @Tick = ''''
SET @columnList = 'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @Country = '''US'''
SET @sqlCommand = 'SELECT ' + @columnList + ' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = ' + @Country + @Tick
PRINT @sqlCommand
EXEC (@sqlCommand)
GO

DECLARE @sqlCommand varchar(1000)
DECLARE @columnList varchar(200)
DECLARE @Country nvarchar(3)
DECLARE @Tick char(1)
SET @Tick = ''''
SET @columnList = 'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @Country = '''AU'''
SET @sqlCommand = 'SELECT ' + @columnList + ' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = ' + @Country + @Tick
PRINT @sqlCommand
EXEC (@sqlCommand)
GO

DECLARE @sqlCommand varchar(1000)
DECLARE @columnList varchar(200)
DECLARE @Country nvarchar(3)
DECLARE @Tick char(1)
SET @Tick = ''''
SET @columnList = 'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @Country = '''FR'''
SET @sqlCommand = 'SELECT ' + @columnList + ' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = ' + @Country + @Tick
PRINT @sqlCommand
EXEC (@sqlCommand)
GO

DECLARE @sqlCommand varchar(1000)
DECLARE @columnList varchar(200)
DECLARE @Country nvarchar(3)
DECLARE @Tick char(1)
SET @Tick = ''''
SET @columnList = 'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @Country = '''CA'''
SET @sqlCommand = 'SELECT ' + @columnList + ' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = ' + @Country + @Tick
PRINT @sqlCommand
EXEC (@sqlCommand)
GO

DECLARE @sqlCommand varchar(1000)
DECLARE @columnList varchar(200)
DECLARE @Country nvarchar(3)
DECLARE @Tick char(1)
SET @Tick = ''''
SET @columnList = 'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @Country = '''DE'''
SET @sqlCommand = 'SELECT ' + @columnList + ' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = ' + @Country + @Tick
PRINT @sqlCommand
EXEC (@sqlCommand)
GO

DECLARE @sqlCommand varchar(1000)
DECLARE @columnList varchar(200)
DECLARE @Country nvarchar(3)
DECLARE @Tick char(1)
SET @Tick = ''''
SET @columnList = 'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @Country = '''GB'''
SET @sqlCommand = 'SELECT ' + @columnList + ' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = ' + @Country + @Tick
PRINT @sqlCommand
EXEC (@sqlCommand)
GO

/*sp_executesql*/

DECLARE @sqlCommand nvarchar(1000)
DECLARE @columnList nvarchar(200)
DECLARE @Country nvarchar(3)
SET @columnList = N'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @sqlCommand = N'SELECT ' + @columnList + N' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = @Country' 
SET @Country = N'GB'
EXECUTE sp_executesql @sqlCommand, N'@Country nvarchar(3)', @Country = @Country
GO

DECLARE @sqlCommand nvarchar(1000)
DECLARE @columnList nvarchar(200)
DECLARE @Country nvarchar(3)
SET @columnList = N'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @sqlCommand = N'SELECT ' + @columnList + N' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = @Country' 
SET @Country = N'DE'
EXECUTE sp_executesql @sqlCommand, N'@Country nvarchar(3)', @Country = @Country
GO

DECLARE @sqlCommand nvarchar(1000)
DECLARE @columnList nvarchar(200)
DECLARE @Country nvarchar(3)
SET @columnList = N'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @sqlCommand = N'SELECT ' + @columnList + N' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = @Country' 
SET @Country = N'AU'
EXECUTE sp_executesql @sqlCommand, N'@Country nvarchar(3)', @Country = @Country
GO

DECLARE @sqlCommand nvarchar(1000)
DECLARE @columnList nvarchar(200)
DECLARE @Country nvarchar(3)
SET @columnList = N'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @sqlCommand = N'SELECT ' + @columnList + N' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = @Country' 
SET @Country = N'US'
EXECUTE sp_executesql @sqlCommand, N'@Country nvarchar(3)', @Country = @Country
GO

DECLARE @sqlCommand nvarchar(1000)
DECLARE @columnList nvarchar(200)
DECLARE @Country nvarchar(3)
SET @columnList = N'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @sqlCommand = N'SELECT ' + @columnList + N' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = @Country' 
SET @Country = N'UK'
EXECUTE sp_executesql @sqlCommand, N'@Country nvarchar(3)', @Country = @Country
GO

DECLARE @sqlCommand nvarchar(1000)
DECLARE @columnList nvarchar(200)
DECLARE @Country nvarchar(3)
SET @columnList = N'h.SalesOrderID, h.SalesOrderNumber, h.AccountNumber, c.AccountNumber, t.Name, t.CountryRegionCode, t.[Group], t.SalesLastYear '
SET @sqlCommand = N'SELECT ' + @columnList + N' FROM Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t WHERE h.CustomerID = c.CustomerID AND c.TerritoryID = t.TerritoryID AND CountryRegionCode = @Country' 
SET @Country = N'GB'
EXECUTE sp_executesql @sqlCommand, N'@Country nvarchar(3)', @Country = @Country
GO

