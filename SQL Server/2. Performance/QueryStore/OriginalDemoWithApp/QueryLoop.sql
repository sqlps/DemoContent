-- Setup

IF object_id('dbo.getRowsByStateProvinceID') IS NOT NULL
BEGIN
	DROP PROCEDURE getRowsByStateProvinceID;
END
GO

CREATE PROCEDURE [dbo].[getRowsByStateProvinceID] @stateProvinceID INT
AS

	SELECT *
	FROM   Person.Address AS a
	WHERE  a.StateProvinceID = @stateProvinceID;

GO


IF object_id('Sales.GetSalesOrderByCountry') IS NOT NULL
BEGIN
	DROP PROCEDURE Sales.GetSalesOrderByCountry;
END
GO

CREATE PROCEDURE Sales.GetSalesOrderByCountry @Country NVARCHAR (60)
AS

	SELECT *
	FROM   Sales.SalesOrderHeader AS h, Sales.Customer AS c, Sales.SalesTerritory AS t
	WHERE  h.CustomerID = c.CustomerID
			AND c.TerritoryID = t.TerritoryID
			AND CountryRegionCode = @Country;
GO

-- END SETUP --

-- LOOP --

WHILE 1=1
BEGIN

	EXECUTE getRowsByStateProvinceID 119;
	EXECUTE getRowsByStateProvinceID 9;	
	EXECUTE getRowsByStateProvinceID 9;	
	EXECUTE getRowsByStateProvinceID 9;	
	EXECUTE getRowsByStateProvinceID 9;	
	EXECUTE getRowsByStateProvinceID 9;	
	EXECUTE Sales.GetSalesOrderByCountry 'UK';
	EXECUTE Sales.GetSalesOrderByCountry 'US';
	EXECUTE Sales.GetSalesOrderByCountry 'US';
	EXECUTE Sales.GetSalesOrderByCountry 'US';
	EXECUTE Sales.GetSalesOrderByCountry 'US';
	EXECUTE Sales.GetSalesOrderByCountry 'US';
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'New York'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'Seattle'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'Seattle'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'Seattle'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'Seattle'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'Seattle'
	WAITFOR DELAY '00:00:05'

	EXECUTE getRowsByStateProvinceID 9;
	EXECUTE getRowsByStateProvinceID 119;	
	EXECUTE getRowsByStateProvinceID 119;	
	EXECUTE getRowsByStateProvinceID 119;	
	EXECUTE getRowsByStateProvinceID 119;	
	EXECUTE getRowsByStateProvinceID 119;	
	EXECUTE Sales.GetSalesOrderByCountry 'US';
	EXECUTE Sales.GetSalesOrderByCountry 'UK';
	EXECUTE Sales.GetSalesOrderByCountry 'UK';
	EXECUTE Sales.GetSalesOrderByCountry 'UK';
	EXECUTE Sales.GetSalesOrderByCountry 'UK';
	EXECUTE Sales.GetSalesOrderByCountry 'UK';
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'Seattle'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'New York'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'New York'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'New York'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'New York'
	EXEC sp_executesql N'SELECT * FROM Person.Address WHERE City = @city', N'@city nvarchar(30)', N'New York'
	WAITFOR DELAY '00:00:05'

END


