Use AdventureWorks2016CTP3
GO

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
