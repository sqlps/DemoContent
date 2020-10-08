use AdventureWorks2016CTP3
go

-- cleanup
ALTER TABLE dbo.ProductCatalog SET (SYSTEM_VERSIONING=OFF)
GO
DROP TABLE IF EXISTS dbo.ProductCatalog
DROP TABLE IF EXISTS History.ProductCatalog
DROP SCHEMA IF EXISTS History
GO
CREATE SCHEMA History
GO

USE [AdventureWorks2016CTP3]
GO
DROP PROCEDURE IF EXISTS [dbo].[diff_ProductCatalog]
GO
CREATE PROCEDURE
[dbo].[diff_ProductCatalog] @id int, @date datetime2(0), @latest datetime2(0) = null as
begin

	declare @v1 nvarchar(max) = 
		(case when (@latest is null)
			then (select * from ProductCatalog where ProductID = @id for json path, without_array_wrapper)
			else (select * from ProductCatalog for system_time as of @latest where ProductID = @id for json path, without_array_wrapper)
		end)

	declare @v2 nvarchar(max) = 
		(select * from ProductCatalog for system_time as of @date where ProductID = @id for json path, without_array_wrapper)

	select v1.[key] as [Column], v1.value as v1, v2.value as v2
	from openjson(@v1) v1
		join openjson(@v2) v2 on v1.[key] = v2.[key]
	where v1.value <> v2.value

end
go


SELECT * FROM Production.Product

/****************************************************************************************
*		Creating product catalog
****************************************************************************************/

CREATE TABLE dbo.ProductCatalog(
 ProductID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ProductCatalog_ID PRIMARY KEY,
 Name nvarchar(50) NOT NULL,
 ProductSubcategoryID int NULL,
 ProductModelID int NULL,
 Price money,
 Data nvarchar(max)	CHECK (ISJSON(Data)>0),
 ModifiedOn datetime2(0) NOT NULL
)

SELECT * FROM ProductCatalog
 
go

 INSERT INTO ProductCatalog(Name, ProductSubcategoryID, ProductModelID, Price,		ModifiedOn,		Data)
					 SELECT Name, ProductSubcategoryID, ProductModelID, ListPrice,	ModifiedDate,

								(SELECT ProductNumber,MakeFlag,FinishedGoodsFlag,Color,SafetyStockLevel,
									ReorderPoint,StandardCost,Size,SizeUnitMeasureCode,WeightUnitMeasureCode,
									Weight,DaysToManufacture,ProductLine,Class,Style,SellStartDate,SellEndDate,DiscontinuedDate
									FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)						AS Data

					FROM Production.Product
					WHERE ListPrice > 0
 
SELECT * FROM ProductCatalog

