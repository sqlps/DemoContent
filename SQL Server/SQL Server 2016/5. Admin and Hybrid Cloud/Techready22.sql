use AdventureWorks2016CTP3

-- cleanup
ALTER TABLE dbo.ProductCatalog SET (SYSTEM_VERSIONING=OFF)
GO
DROP TABLE IF EXISTS dbo.ProductCatalog
DROP TABLE IF EXISTS History.ProductCatalog
DROP SCHEMA IF EXISTS History
GO
CREATE SCHEMA History
GO


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

/****************************************************************************************
*		JSON queries.
****************************************************************************************/

SELECT Name, JSON_VALUE(Data, '$.StandardCost') Cost, JSON_VALUE(Data, '$.Class') Class
FROM ProductCatalog
WHERE JSON_VALUE(Data, '$.ProductNumber') = 'SA-M198'

UPDATE ProductCatalog
SET Data = JSON_MODIFY(Data, '$.StandardCost',
								CAST(JSON_VALUE(Data, '$.StandardCost') as float) * 1.1)
WHERE JSON_VALUE(Data, '$.ProductNumber') = 'SA-M198'

-- Expose JSON property as computed column and create index.
ALTER TABLE ProductCatalog
	ADD Data$ProductNumber AS JSON_VALUE(Data, '$.ProductNumber')
GO
CREATE INDEX idx_Data$ProductNumber
	ON ProductCatalog(Data$ProductNumber)

SELECT Name, JSON_VALUE(Data, '$.StandardCost') Cost, JSON_VALUE(Data, '$.Class') Class
FROM ProductCatalog
WHERE JSON_VALUE(Data, '$.ProductNumber') = 'SA-M198'

UPDATE ProductCatalog
SET Data = JSON_MODIFY(Data, '$.StandardCost',
								CAST(JSON_VALUE(Data, '$.StandardCost') as float) * 1.1)
WHERE JSON_VALUE(Data, '$.ProductNumber') = 'SA-M198'

update ProductCatalog
set Price = Price * 1.8,
	ProductModelID = 113,
	Data = JSON_MODIFY(Data, '$.ProductLine', 'M')
where ProductID = 177

update ProductCatalog
set Data = JSON_MODIFY(JSON_MODIFY(Data, '$.Color', 'Silver'), 'strict $.DaysToManufacture', 2)
where ProductID = 177

update ProductCatalog
set Data = JSON_MODIFY(Data, 'append $.keywords', 'Sales')
where ProductID = 177

SELECT Data FROM ProductCatalog
where ProductID = 177

update ProductCatalog
set Data = JSON_MODIFY(Data, 'append $.keywords', 'Promotion')
where ProductID = 177


/****************************************************************************************
*		Extending with temporal...
****************************************************************************************/

ALTER TABLE dbo.ProductCatalog
ADD ValidTo datetime2(0) NOT NULL DEFAULT(CONVERT(datetime2(0), '9999-12-31 23:59:59.99'))

ALTER TABLE dbo.ProductCatalog
	ADD PERIOD FOR SYSTEM_TIME (ModifiedOn,ValidTo)

ALTER TABLE dbo.ProductCatalog
	SET (SYSTEM_VERSIONING = ON(HISTORY_TABLE = History.ProductCatalog))

-- Updating products
select * from dbo.ProductCatalog
where ProductID = 177

update ProductCatalog
set Price = Price * 1.15
where ProductID = 177

update ProductCatalog
set Price = Price * 0.8, ProductSubcategoryID = 16, ProductModelID = 110
where ProductID = 177

update ProductCatalog
set Price = Price * 1.8,  ProductModelID = 113
where ProductID = 177

select * from dbo.ProductCatalog for system_time all
where ProductID = 177
order by ModifiedOn desc

exec diff_ProductCatalog 177, '2016-02-05 01:25:34'

select * from dbo.ProductCatalog for system_time all
where ProductID = 177
order by ModifiedOn desc

exec diff_ProductCatalog 177, '2016-02-05 01:25:38', '2016-02-05 01:25:34'


/****************************************************************************************
*		Error correction...
****************************************************************************************/

exec diff_ProductCatalog 177, '2016-02-05 01:25:34'
go

declare @productid int = 177;
with correct (ProductSubcategoryID,Price) as
(
	select ProductSubcategoryID, Price
	from dbo.ProductCatalog for system_time as of '2016-02-05T01:25:34'
	where productid = @productid
)
update ProductCatalog
set ProductSubcategoryID = correct.ProductSubcategoryID, 
	Price = correct.Price
from correct
where productid = @productid


exec diff_ProductCatalog 177, '2016-02-04 22:17:17'
go

/****************************************************************************************
*		Anomaly detection...
****************************************************************************************/

update ProductCatalog
set Price = Price / 5
where ProductID = 177


update ProductCatalog
set Price = Price * 5
where ProductID = 177

select Price, ModifiedOn from dbo.ProductCatalog for system_time all
where ProductID = 177
order by ModifiedOn desc

declare @productid int = 177;

with history as(
	
	select ProductID, Name, Price, ModifiedOn,
			LAG (Price, 1, 1) over (partition by ProductID order by ModifiedOn) as PrevPrice,
			LEAD (Price, 1, 1) over (partition by ProductID order by ModifiedOn) as NextPrice
	 from dbo.ProductCatalog for system_time all
	where ProductID = 177
	
)
select ModifiedOn, ProductID, Name, Price, PrevPrice
from history
where PrevPrice = NextPrice
	AND ABS(Price - PrevPrice)/PrevPrice >=0.5

GO

/****************************************************************************************
*		Fraud detection...
****************************************************************************************/

declare @t as table (dt datetime2);
with a as(
select CAST('2016-02-04 17:55:11' as datetime2) as dt
union all
select CAST('2016-02-04 14:15:34' as datetime2) as dt
)
INSERT INTO @t
SELECT *
FROM a

--SELECT * FROM @t




--SELECT *
--FROM OPENROWSET(BULK N'c:\JSON\logANSI.txt',
--				FORMATFILE = 'c:\\JSON\ldjfmt.txt',
--				CODEPAGE = '65001') as log
		
SELECT Page, [User], Time, Origin
FROM OPENROWSET(BULK N'c:\JSON\logANSI.txt',
				FORMATFILE = 'c:\\JSON\ldjfmt.txt',
				CODEPAGE = '65001') as log
		CROSS APPLY OPENJSON (log.log_entry)
					WITH( Page varchar(30), [User] varchar(20),Time datetime2, Origin varchar(20))
			JOIN @t as t ON ABS(DATEDIFF(second, Time, t.dt)) < 30
order by Time
	
go


declare @dt1 datetime2 = '2016-02-04 17:55:11'
declare @dt2 datetime2 = '2016-02-04 14:15:34.0000000'


SELECT Page, [User], Time, Origin
FROM OPENROWSET(BULK N'c:\JSON\logANSI.txt',
				FORMATFILE = 'c:\\JSON\ldjfmt.txt',
				CODEPAGE = '65001') as log
		CROSS APPLY OPENJSON (log.log_entry)
					WITH( Page varchar(30), [User] varchar(20),Time datetime2, Origin varchar(20))
WHERE ABS(DATEDIFF(second, Time, @dt1)) < 30
OR ABS(DATEDIFF(second, Time, @dt2)) < 30
	order by Time
	
