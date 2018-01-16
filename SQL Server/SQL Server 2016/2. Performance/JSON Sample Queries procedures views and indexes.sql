/*******************************************************************************************************
*
*				AdventureWorks SQL Server 2016 CTP3 JSON Sample
*	Prerequisites:
*	1. AdventureWorks2016CTP3 database must be installed.
*	2. JSON Setup script must be executed.
*	Optional:
*	Full text search - arrays of scalars might be indexed using FTS.
*			One example (S3.2) in JSON indexing section requires FTS to be installed.
*
*	Structure of examples:
*	1. Denormalization
*	2. Creating procedures and views that query JSON data.
*	3. Indexing JSON data 
*	4. JSON import/export
*	5. Query examples.
*	6. Clenup script.
*******************************************************************************************************/

USE AdventureWorks2016CTP3
GO
/*******************************************************************************************************
*	SCENARIO 1 - Denormalization.
*******************************************************************************************************/

DROP FUNCTION IF EXISTS dbo.ufnToRawJsonArray
GO
-- Utility function that removes keys from JSON
-- Used when we need to remove keys from FOR JSON output,
-- e.g. to generate [1,2,"cell"] format instead of [{"val":1,{"val":2},{"val":"cell"}]
CREATE FUNCTION
dbo.ufnToRawJsonArray(@json nvarchar(max), @key nvarchar(400)) returns nvarchar(max)
as begin
	return replace(replace(@json, FORMATMESSAGE('{"%s":', @key),''), '}','')
end
go

/*******************************************************************************************************
*	STEP S1-1 - Simplify database structure.
*	Create additional columns that will contain JSON data
*   and populate them with JSON from related tables.
*******************************************************************************************************/
-- Drop JSON columns and constraints if they exist
GO
ALTER TABLE Sales.SalesOrder_json
DROP
	COLUMN IF EXISTS vCustomerName,
	CONSTRAINT IF EXISTS [SalesOrder reasons must be formatted as JSON array],
	COLUMN IF EXISTS SalesReasons,
	CONSTRAINT IF EXISTS [SalesOrder items must be formatted as JSON array],
	COLUMN IF EXISTS OrderItems,
	CONSTRAINT IF EXISTS [SalesOrder additional information must be formatted as JSON],
	COLUMN IF EXISTS Info
	
GO
ALTER TABLE Person.Person_json
DROP
	CONSTRAINT IF EXISTS [Phone numbers must be formatted as JSON array],
	COLUMN IF EXISTS PhoneNumbers,
	CONSTRAINT IF EXISTS [Email addresses must be formatted as JSON array],
	COLUMN IF EXISTS EmailAddresses
GO
-- Create SalesReasons column that will contain an array of sales reason strings.
ALTER TABLE Sales.SalesOrder_json
ADD	SalesReasons NVARCHAR(MAX)
		CONSTRAINT [SalesOrder reasons must be formatted as JSON array]
			CHECK (ISJSON(SalesReasons)>0)
GO
-- Populate SalesReasons from SalesOrderHeaderSalesReason/SalesReason using FOR JSON
UPDATE Sales.SalesOrder_json
SET SalesReasons = 
	dbo.ufnToRawJsonArray(
			(SELECT SalesReason.Name
				FROM Sales.SalesOrderHeaderSalesReason
					JOIN Sales.SalesReason
						ON Sales.SalesOrderHeaderSalesReason.SalesReasonID = Sales.SalesReason.SalesReasonID
				WHERE Sales.SalesOrder_json.SalesOrderID = Sales.SalesOrderHeaderSalesReason.SalesOrderID
			FOR JSON PATH)
			, 'Name')

-- Note: We don't have FOR JSON clause that returns simple arrays (i.e. only values without keys)
-- Therefore, we need to use a custom UDF (dbo.ufnToRawJsonArray) to remove keys from the array.
GO
-- Create JSON column that will contain an array of sales order items
ALTER TABLE Sales.SalesOrder_json
ADD OrderItems NVARCHAR(MAX)
	CONSTRAINT [SalesOrder items must be formatted as JSON array]
		CHECK (ISJSON(OrderItems)>0)
GO
-- Move all sales order items from the SalesOrderDetails table into OrderItems column
-- Populate OrderItems column using SalesOrderDetails table and FOR JSON.
-- Note: We will group properties in Item and Product JSON objects using dot notation in column aliases.
UPDATE Sales.SalesOrder_json
SET OrderItems = (SELECT CarrierTrackingNumber,
						OrderQty as [Item.Qty], UnitPrice as [Item.Price],
						UnitPriceDiscount as [Item.Discount], LineTotal as [Item.Total],
						ProductNumber as [Product.Number], Name as [Product.Name]
					FROM  Sales.SalesOrderDetail 
						JOIN Production.Product
						 ON Sales.SalesOrderDetail.ProductID = Production.Product.ProductID
					WHERE Sales.SalesOrderDetail.SalesOrderID = Sales.SalesOrder_json.SalesOrderID
					FOR JSON PATH)
GO
-- Create Info column that will contain various information about sales order.
ALTER TABLE Sales.SalesOrder_json
ADD Info NVARCHAR(MAX)
	CONSTRAINT [SalesOrder additional information must be formatted as JSON]
		CHECK (ISJSON(Info)>0)
GO
-- Populate info column.
UPDATE Sales.SalesOrder_json
SET Info = (
		SELECT
			shipaddr.AddressLine1 + COALESCE ( ', ' + shipaddr.AddressLine2, '') as [ShippingInfo.Address], shipaddr.City as [ShippingInfo.City], shipaddr.PostalCode as [ShippingInfo.PostalCode],
			shipprovince.Name as [ShippingInfo.Province], shipprovince.TerritoryID as [ShippingInfo.TerritoryID],
				shipmethod.Name as [ShippingInfo.Method], shipmethod.ShipBase as [ShippingInfo.ShipBase], shipmethod.ShipRate as [ShippingInfo.ShipRate],
			billaddr.AddressLine1 + COALESCE ( ', ' + shipaddr.AddressLine2, '') as [BillingInfo.Address], billaddr.City as [BillingInfo.City], billaddr.PostalCode as [BillingInfo.PostalCode],
			sp.FirstName + ' ' +  sp.LastName as [SalesPerson.Name], sp.BusinessEntityID AS [SalesPerson.ID],
			cust.FirstName + ' ' + cust.LastName as [Customer.Name], cust.BusinessEntityID AS [Customer.ID]					
			FOR JSON PATH)
FROM Sales.SalesOrder_json
	JOIN Person.Address shipaddr
		ON Sales.SalesOrder_json.ShipToAddressID = shipaddr.AddressID
			LEFT JOIN Person.StateProvince shipprovince
				ON shipaddr.StateProvinceID = shipprovince.StateProvinceID
	JOIN Purchasing.ShipMethod shipmethod
		ON Sales.SalesOrder_json.ShipMethodID = shipmethod.ShipMethodID
	JOIN Person.Address billaddr
		ON Sales.SalesOrder_json.BillToAddressID = billaddr.AddressID
	LEFT JOIN Sales.SalesPerson
		ON Sales.SalesPerson.BusinessEntityID = Sales.SalesOrder_json.SalesPersonID
		LEFT JOIN Person.Person AS sp
			ON Sales.SalesPerson.BusinessEntityID = sp.BusinessEntityID
	LEFT JOIN Sales.Customer
		ON Sales.Customer.CustomerID = Sales.SalesOrder_json.CustomerID
		LEFT JOIN Person.Person AS cust
			ON Sales.Customer.CustomerID = cust.BusinessEntityID
GO

-- Create additional JSON column that will contain an array of phone numbers and types.
ALTER TABLE Person.Person_json
ADD PhoneNumbers NVARCHAR(MAX)
	CONSTRAINT [Phone numbers must be formatted as JSON array]
		CHECK (ISJSON(PhoneNumbers)>0)
GO

-- Populate PersonInfo from PersonPhone/PhoneNumberType tables using FOR JSON
UPDATE Person.Person_json
SET PhoneNumbers = (SELECT Person.PersonPhone.PhoneNumber, Person.PhoneNumberType.Name AS PhoneNumberType
					FROM  Person.PersonPhone
						INNER JOIN Person.PhoneNumberType ON Person.PersonPhone.PhoneNumberTypeID = Person.PhoneNumberType.PhoneNumberTypeID
					WHERE Person.Person_json.PersonID = Person.PersonPhone.BusinessEntityID
					FOR JSON PATH) 
GO

-- Create additional JSON column that will contain an array of phone numbers.
ALTER TABLE Person.Person_json
ADD EmailAddresses NVARCHAR(MAX)
	CONSTRAINT [Email addresses must be formatted as JSON array]
		CHECK (ISJSON(EmailAddresses)>0)
GO

-- Populate PersonInfo from EmailAddress using FOR JSON
UPDATE Person.Person_json
SET EmailAddresses = 
			dbo.ufnToRawJsonArray(
					(SELECT Person.EmailAddress.EmailAddress
						FROM Person.EmailAddress
						WHERE Person.Person_json.PersonID = Person.EmailAddress.BusinessEntityID
						FOR JSON PATH)
					, 'EmailAddress')

/*******************************************************************************************************
*	STEP S1-2. - Views.
*	Create views on top of denormalized JSON data in the tables.
*******************************************************************************************************/

GO
-- View that "joins" SalesOrder with related OrderItems stored as an array in JSON column.
CREATE VIEW Sales.vwSalesOrderItems_json
AS
SELECT SalesOrderID, SalesOrderNumber, OrderDate,
	CarrierTrackingNumber, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal, ProductNumber, Name
FROM Sales.SalesOrder_json
	CROSS APPLY
		OPENJSON (OrderItems)
			WITH (	CarrierTrackingNumber NVARCHAR(20),
				OrderQty int '$.Item.Qty',
				UnitPrice float '$.Item.Price',
				UnitPriceDiscount float '$.Item.Discount',
				LineTotal float '$.Item.Total',
				ProductNumber NVARCHAR(20) '$.Product.Number',
				Name NVARCHAR(50) '$.Product.Name'
				)

GO
-- View that encapsulates JSON_VALUE and JSON_QUERY functions.
CREATE VIEW Sales.vwSalesOrderInfo_json AS
SELECT SalesOrderNumber,
	OrderDate, ShipDate, Status, AccountNumber, TotalDue,
	JSON_VALUE(Info, '$.ShippingInfo.Province') as [Shipping Province], 
	JSON_VALUE(Info, '$.ShippingInfo.Method') as [Shipping Method], 
	JSON_VALUE(Info, '$.ShippingInfo.ShipRate') as ShipRate,
	JSON_VALUE(Info, '$.BillingInfo.Address') as [Billing Address],
	JSON_VALUE(Info, '$.SalesPerson.Name') as [Sales Person],
	JSON_VALUE(Info, '$.Customer.Name')	as Customer
FROM Sales.SalesOrder_json

GO
-- Equivalent view that uses OPENJSON with strong types.
CREATE VIEW Sales.vwSalesOrderInfo2_json AS
SELECT SalesOrderNumber, OrderDate, ShipDate, Status, AccountNumber, TotalDue,
	[Shipping Province], [Shipping Method], ShipRate, [Sales Person], Customer
FROM Sales.SalesOrder_json
	CROSS APPLY OPENJSON(Info)
		WITH (	[Shipping Province] nvarchar(100) '$.ShippingInfo.Province',
				[Shipping Method] nvarchar(20) '$.ShippingInfo.Method',
				ShipRate float '$.ShippingInfo.ShipRate',
				[Billing Address] nvarchar(100) '$.BillingInfo.Address',
				[Sales Person] nvarchar(100) '$.SalesPerson.Name',
				Customer nvarchar(4000) '$.Customer.Name') AS SlaesOrderInfo
GO

-- Equivalent view created on the fully normalized structure:
CREATE VIEW Sales.vwSalesOrderInfoRel_json AS
SELECT SalesOrderNumber, OrderDate, ShipDate, Status, Sales.SalesOrderHeader.AccountNumber, TotalDue,
	shipprovince.Name as [Shipping Province], 
	shipmethod.Name as [Shipping Method], 
	shipmethod.ShipRate as ShipRate,
	billaddr.AddressLine1 + COALESCE ( ', ' + shipaddr.AddressLine2, '') as [Billing Address],
	sp.FirstName + ' ' +  sp.LastName as [Sales Person],
	cust.FirstName + ' ' + cust.LastName as Customer	
FROM Sales.SalesOrderHeader
	JOIN Person.Address shipaddr
		ON Sales.SalesOrderHeader.ShipToAddressID = shipaddr.AddressID
			LEFT JOIN Person.StateProvince shipprovince
				ON shipaddr.StateProvinceID = shipprovince.StateProvinceID
	JOIN Purchasing.ShipMethod shipmethod
		ON Sales.SalesOrderHeader.ShipMethodID = shipmethod.ShipMethodID
	JOIN Person.Address billaddr
		ON Sales.SalesOrderHeader.BillToAddressID = billaddr.AddressID
	LEFT JOIN Sales.SalesPerson
		ON Sales.SalesPerson.BusinessEntityID = Sales.SalesOrderHeader.SalesPersonID
		LEFT JOIN Person.Person AS sp
			ON Sales.SalesPerson.BusinessEntityID = sp.BusinessEntityID
	LEFT JOIN Sales.Customer
		ON Sales.Customer.CustomerID = Sales.SalesOrderHeader.CustomerID
		LEFT JOIN Person.Person AS cust
			ON Sales.Customer.CustomerID = cust.BusinessEntityID
GO

/*******************************************************************************************************
*	SCENARIO 2 - Data querying and analysis.
*	Create procedures that encapsulate and query JSON data.
*******************************************************************************************************/

-- Get SalesOrder and related information by ID.
CREATE PROCEDURE
Sales.SalesOrderInfo_json(@SalesOrderID int)
AS BEGIN
	SELECT SalesOrderNumber, OrderDate, Status, ShipDate, Status, AccountNumber, TotalDue,
		JSON_QUERY(Info, '$.ShippingInfo') ShippingInfo,
		JSON_QUERY(Info, '$.BillingInfo') BillingInfo,
		JSON_VALUE(Info, '$.SalesPerson.Name') SalesPerson,
		JSON_VALUE(Info, '$.ShippingInfo.City') City,
		JSON_VALUE(Info, '$.Customer.Name') Customer,
		JSON_QUERY(OrderItems, '$') OrderItems
	FROM Sales.SalesOrder_json
	WHERE SalesOrderID = @SalesOrderID
END
GO

---------------------------------------------------------------------------------------------------------
--	Equivalent stored procedure in normalized schema.
---------------------------------------------------------------------------------------------------------
CREATE PROCEDURE
Sales.SalesOrderInfoRel_json(@SalesOrderID int)
as begin
	SELECT SalesOrderNumber, OrderDate, ShipDate, Status, Sales.SalesOrder_json.AccountNumber, TotalDue,
		shipprovince.Name as [Shipping Province], 
		shipmethod.Name as [Shipping Method], 
		shipmethod.ShipRate as ShipRate,
		billaddr.AddressLine1 + COALESCE ( ', ' + shipaddr.AddressLine2, '') as [Billing Address],
		sp.FirstName + ' ' +  sp.LastName as [Sales Person],
		cust.FirstName + ' ' + cust.LastName as Customer	
	FROM Sales.SalesOrder_json
		JOIN Person.Address shipaddr
			ON Sales.SalesOrder_json.ShipToAddressID = shipaddr.AddressID
				LEFT JOIN Person.StateProvince shipprovince
					ON shipaddr.StateProvinceID = shipprovince.StateProvinceID
		JOIN Purchasing.ShipMethod shipmethod
			ON Sales.SalesOrder_json.ShipMethodID = shipmethod.ShipMethodID
		JOIN Person.Address billaddr
			ON Sales.SalesOrder_json.BillToAddressID = billaddr.AddressID
		LEFT JOIN Sales.SalesPerson
			ON Sales.SalesPerson.BusinessEntityID = Sales.SalesOrder_json.SalesPersonID
			LEFT JOIN Person.Person AS sp
				ON Sales.SalesPerson.BusinessEntityID = sp.BusinessEntityID
		LEFT JOIN Sales.Customer
			ON Sales.Customer.CustomerID = Sales.SalesOrder_json.CustomerID
			LEFT JOIN Person.Person AS cust
				ON Sales.Customer.CustomerID = cust.BusinessEntityID
	WHERE Sales.SalesOrder_json.SalesOrderID = @SalesOrderID
end
GO

-- Find person rows using a list of identifiers
CREATE PROCEDURE
Person.PersonList_json(@PersonIds nvarchar(100))
as begin
	SELECT PersonID,PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,
			EmailAddresses, PhoneNumbers
	FROM Person.Person_json
		JOIN OPENJSON(@PersonIds)
			ON PersonID = value
end
GO

-- Find SalesOrder rows using a list of identifiers
CREATE PROCEDURE
Sales.SalesOrderList_json(@SalesOrderIds nvarchar(100))
as begin
	SELECT SalesOrderID,RevisionNumber,OrderDate,DueDate,ShipDate,Status,
			OnlineOrderFlag,PurchaseOrderNumber,AccountNumber,CustomerID,
			CreditCardApprovalCode,CurrencyRateID,SubTotal,TaxAmt,Freight,Comment
	FROM Sales.SalesOrder_json
		JOIN OPENJSON(@SalesOrderIds)
			ON SalesOrderID = value
end

GO
-- Filter sales orders by customer name.
CREATE PROCEDURE
Sales.SalesOrderSearchByCustomer_json (@customer nvarchar(50))
as begin
	SELECT SalesOrderNumber, OrderDate, Status, AccountNumber,
		JSON_QUERY(Info, '$.ShippingInfo') ShippingInfo,
		JSON_QUERY(Info, '$.BillingInfo') BillingInfo,
		JSON_VALUE(Info, '$.SalesPerson.Name') SalesPerson,
		JSON_VALUE(Info, '$.ShippingInfo.City') City,
		JSON_VALUE(Info, '$.Customer.Name') Customer,
		OrderItems
	FROM Sales.SalesOrder_json
	WHERE JSON_VALUE(Info, '$.Customer.Name') = @customer
END
GO

-- Filter person rows by phone number.
CREATE PROCEDURE
Person.PersonSearchByPhone_json(@PhoneNumber nvarchar(100))
as begin
	SELECT PersonID,PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,
			EmailAddresses, PhoneNumbers
	FROM Person.Person_json
		CROSS APPLY OPENJSON(PhoneNumbers)
			WITH (PhoneNumber nvarchar(100))
	WHERE @PhoneNumber = PhoneNumber
end
GO

-- Filter person rows by phone number and type.
CREATE PROCEDURE
Person.PersonSearchByPhoneNumberAndType_json(@PhoneNumber nvarchar(100), @PhoneNumberType nvarchar(20))
as begin
	SELECT PersonID,PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,
			EmailAddresses, PhoneNumbers
	FROM Person.Person_json
		CROSS APPLY OPENJSON(PhoneNumbers)
			WITH (PhoneNumber nvarchar(100), PhoneNumberType nvarchar(20))
	WHERE PhoneNumber = @PhoneNumber
	AND PhoneNumberType = @PhoneNumberType
end
GO

-- Filter sales orders by sales reason.
CREATE PROCEDURE
Sales.SalesOrderSearchByReason_json (@reason nvarchar(50))
as begin
	SELECT SalesOrderNumber, OrderDate, SalesReasons
	FROM Sales.SalesOrder_json
		CROSS APPLY OPENJSON (SalesReasons)
	WHERE value = @reason
end
GO

-- Filter person rows by email.
CREATE PROCEDURE
Person.PersonSearchByEmail_json(@Email nvarchar(100))
as begin
	SELECT PersonID,PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,
			EmailAddresses, PhoneNumbers
	FROM Person.Person_json
		CROSS APPLY OPENJSON(EmailAddresses)
	WHERE @Email = value
end
GO
---------------------------------------------------------------------------------------------------------
--	Reporting.
---------------------------------------------------------------------------------------------------------

-- List of customers, their statuses, and sales order totals
-- Filtered by city and territory
CREATE PROCEDURE
Sales.SalesOrdersPerCustomerAndStatusReport_json(@city nvarchar(50), @territoryid int)
AS BEGIN
	SELECT JSON_VALUE(Info, '$.Customer.Name') AS Customer, Status, SUM(SubTotal) AS Total
	FROM Sales.SalesOrder_json
	WHERE TerritoryID = @territoryid
	AND JSON_VALUE(Info, '$.ShippingInfo.City') = @city
	AND OrderDate > '1/1/2015'
	GROUP BY JSON_VALUE(Info, '$.Customer.Name'), Status
	HAVING SUM(SubTotal) > 1000
END
GO

-- Number of sales orders grouped by sales reasons filtered by city
CREATE PROCEDURE
Sales.SalesOrdersBySalesReasonReport_json(@city nvarchar(50))
AS BEGIN
	SELECT value, COUNT(SalesOrderNumber) AS NumberOfOrders
	FROM Sales.SalesOrder_json 
		CROSS APPLY
			OPENJSON (SalesReasons)
	WHERE JSON_VALUE(Info, '$.ShippingInfo.City') = @city 
	GROUP BY value
END
GO

/*******************************************************************************************************
*	SCENARIO 3 - Indexing JSON data.
*	Create indexes on JSON columns.
*******************************************************************************************************/


/*******************************************************************************************************
*	Problem - following queries use full table scan since there is no additional filter:
EXEC Sales.SalesOrderSearchByCustomer_json 'Joe Rana'
EXEC Person.PersonSearchByEmail_json 'ken0@adventure-works.com'
EXEC Sales.SalesOrderSearchByReason_json 'Price'
*	
*******************************************************************************************************/

/*******************************************************************************************************
*	STEP S3.1 - Indexing JSON path using B-tree index.
*	Note: 
*	Warning! The maximum key length for a nonclustered index is 1700 bytes. The index 'idx_SalesOrder_json_CustomerName' has maximum length of 8000 bytes. For some combination of large values, the insert/update operation will fail.
*	This is expected warning because JSON_VALUE returns up to 8000 bytes. If indexed values are less than 1700 bytes there will be no error.
*	DO NOT CREATE INDEX ON A PROPERTY THAT MIGHT RETURN MORE THAN 1700 BYTES.  
*******************************************************************************************************/

-- Create nonclustered JSON index on property $.Customer.Name in Info JSON column.
ALTER TABLE Sales.SalesOrder_json
	ADD vCustomerName AS JSON_VALUE(Info, '$.Customer.Name')
CREATE INDEX idx_SalesOrder_json_CustomerName
	ON Sales.SalesOrder_json(vCustomerName)
go

/*******************************************************************************************************
*	Following query uses index:
EXEC Sales.SalesOrderSearchByCustomer_json 'Joe Rana'
*	
*******************************************************************************************************/

/*******************************************************************************************************
*	STEP S3.2 - Indexing JSON array element using full-text search index.
*	NOTE - Full-Text search component must be installed! Skip this example if you don't have FTS. 
*******************************************************************************************************/

-- Create full text catalog for JSON data
CREATE FULLTEXT CATALOG jsonFullTextCatalog;
GO

-- Create full text index on SalesReason column.
CREATE FULLTEXT INDEX ON Sales.SalesOrder_json(SalesReasons)
	KEY INDEX PK_SalesOrder__json_SalesOrderID
	ON jsonFullTextCatalog;
GO

-- Create full text index on EmaillAdresses column.
CREATE FULLTEXT INDEX ON Person.Person_json(EmailAddresses)
	KEY INDEX PK_Person_json_PersonID
	ON jsonFullTextCatalog;
GO

-- Create procedure that search person rows by email using FTS
CREATE PROCEDURE
Person.PersonSearchByEmailAddressQuery_json (@EmailAddressQuery nvarchar(250))
as begin
	SELECT PersonID,PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,
			EmailAddresses, PhoneNumbers
	FROM Person.Person_json
	WHERE CONTAINS(EmailAddresses, @EmailAddressQuery)
end
GO

-- Create procedure that search sales orders by sales reasons using FTS
CREATE PROCEDURE
Sales.SalesOrderSearchByReasonQuery_json (@reason nvarchar(50))
as begin
	SELECT SalesOrderNumber, OrderDate, SalesReasons
	FROM Sales.SalesOrder_json
	WHERE CONTAINS(SalesReasons, @reason)
end
GO

/*******************************************************************************************************
*	Following queries use full-text indexes:
EXEC Person.PersonSearchByEmailAddressQuery_json 'ken0@adventure-works.com'
EXEC Sales.SalesOrderSearchByReasonQuery_json 'Price'
EXEC Sales.SalesOrderSearchByReasonQuery_json 'Price OR Quality'
*	
*******************************************************************************************************/


/*******************************************************************************************************
*	SCENARIO 4 - Data import/export.
*	Create procedures that import JSON into tables or export relational data as JSON text.
*******************************************************************************************************/

/*******************************************************************************************************
*	STEP S4.1 - Create procedures for formatting table data as JSON text.
*******************************************************************************************************/
GO
CREATE PROCEDURE
Person.PersonInfo_json(@PersonID int)
as begin
	SELECT PersonID,PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,
			JSON_QUERY(EmailAddresses, '$') AS EmailAddresses, JSON_QUERY(PhoneNumbers, '$') AS PhoneNumbers
	FROM Person.Person_json
	WHERE PersonID = @PersonID
	FOR JSON PATH
end
GO

CREATE PROCEDURE
Sales.SalesOrderExport_json(@SalesOrderID int)
as begin
	SELECT SalesOrderNumber, OrderDate, Status, ShipDate, AccountNumber, TotalDue,
		JSON_QUERY(Info, '$.ShippingInfo') ShippingInfo,
		JSON_QUERY(Info, '$.BillingInfo') BillingInfo,
		JSON_VALUE(Info, '$.SalesPerson.Name') SalesPerson,
		JSON_VALUE(Info, '$.ShippingInfo.City') City,
		JSON_VALUE(Info, '$.Customer.Name') Customer,
		JSON_QUERY(OrderItems, '$') OrderItems
	FROM Sales.SalesOrder_json
	WHERE SalesOrderID = @SalesOrderID
	FOR JSON PATH
END
GO

/*******************************************************************************************************
*	STEP S4.2 - Create procedures for loading JSON data into the tables.
*******************************************************************************************************/

GO
CREATE PROCEDURE 
Person.PersonInsert_json(@Person nvarchar(max))
as begin
	INSERT INTO Person.Person_json (
			PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,
			EmailPromotion,ModifiedDate)
	SELECT PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,
			EmailPromotion,ModifiedDate
	FROM OPENJSON(@Person)
			WITH(
				PersonType nchar(2),
				NameStyle dbo.NameStyle,
				Title nvarchar(8),
				FirstName dbo.Name,
				MiddleName dbo.Name,
				LastName dbo.Name,
				Suffix nvarchar(10),
				EmailPromotion int,
				AdditionalContactInfo NVARCHAR(MAX),
				Demographics NVARCHAR(MAX),
				ModifiedDate datetime
			)	
END
GO

CREATE PROCEDURE 
Person.PersonUpdate_json(@Person nvarchar(max))
as begin
	UPDATE Person.Person_json
	SET PersonType = json.PersonType,
		NameStyle = json.NameStyle,
		Title = json.Title,
		FirstName = json.FirstName,
		MiddleName = json.MiddleName,
		LastName = json.LastName,
		Suffix = json.Suffix,
		EmailPromotion = json.EmailPromotion,
		AdditionalContactInfo = json.AdditionalContactInfo,
		Demographics = json.Demographics
	FROM OPENJSON(@Person)
			WITH(
				PersonID int,
				PersonType nchar(2),
				NameStyle dbo.NameStyle,
				Title nvarchar(8),
				FirstName dbo.Name,
				MiddleName dbo.Name,
				LastName dbo.Name,
				Suffix nvarchar(10),
				EmailPromotion int,
				AdditionalContactInfo NVARCHAR(MAX),
				Demographics NVARCHAR(MAX)
			) AS json
		WHERE Person_json.PersonID = json.PersonID
END
GO

CREATE PROCEDURE 
Sales.SalesOrderInsert_json(@SalesOrder nvarchar(max))
as begin
	INSERT INTO Sales.SalesOrder_json (SalesOrderID,RevisionNumber,OrderDate,DueDate,ShipDate,Status,
								OnlineOrderFlag,PurchaseOrderNumber,AccountNumber,CustomerID,
								CreditCardApprovalCode,CurrencyRateID,SubTotal,TaxAmt,Freight,Comment)
	SELECT SalesOrderID,RevisionNumber,OrderDate,DueDate,ShipDate,Status,
			OnlineOrderFlag,PurchaseOrderNumber,AccountNumber,CustomerID,
			CreditCardApprovalCode,CurrencyRateID,SubTotal,TaxAmt,Freight,Comment
	FROM OPENJSON(@SalesOrder)
			WITH(
					SalesOrderID int,
					RevisionNumber tinyint,
					OrderDate datetime,
					DueDate datetime,
					ShipDate datetime,
					Status tinyint,
					OnlineOrderFlag dbo.Flag,
					PurchaseOrderNumber dbo.OrderNumber ,
					AccountNumber dbo.AccountNumber,
					CustomerID int,
					CreditCardApprovalCode varchar(15),
					CurrencyRateID int,
					SubTotal money,
					TaxAmt money,
					Freight money,
					Comment nvarchar(128)
			)	
END
GO

CREATE PROCEDURE 
Sales.SalesOrderUpdate_json(@SalesOrder nvarchar(max))
as begin
	UPDATE Sales.SalesOrder_json
	SET RevisionNumber = json.RevisionNumber,
		OrderDate = json.OrderDate,
		DueDate = json.DueDate,
		ShipDate = json.ShipDate,
		Status = json.Status,
		OnlineOrderFlag = json.OnlineOrderFlag,
		PurchaseOrderNumber = json.PurchaseOrderNumber,
		AccountNumber = json.AccountNumber,
		CustomerID = json.CustomerID,
		CreditCardApprovalCode = json.CreditCardApprovalCode,
		SubTotal = json.SubTotal,
		TaxAmt = json.TaxAmt,
		Freight = json.Freight,
		Comment = json.Comment
	FROM OPENJSON(@SalesOrder)
			WITH(
					SalesOrderID int,
					RevisionNumber tinyint,
					OrderDate datetime,
					DueDate datetime,
					ShipDate datetime,
					Status tinyint,
					OnlineOrderFlag dbo.Flag,
					PurchaseOrderNumber dbo.OrderNumber ,
					AccountNumber dbo.AccountNumber,
					CustomerID int,
					CreditCardApprovalCode varchar(15),
					CurrencyRateID int,
					SubTotal money,
					TaxAmt money,
					Freight money,
					Comment nvarchar(128)
			) AS json
		WHERE Sales.SalesOrder_json.SalesOrderID = json.SalesOrderID
END
GO

/*******************************************************************************************************
*	Query examples
*******************************************************************************************************/

-- Basic example with:
--	1. one standard table column,
--	2. one scalar value extracted from JSON column (sales person name) using JSON_VALUE, and
--	3. one JSON fragment (all customer information) using JSON_QUERY function.
SELECT SalesOrderNumber,
	JSON_VALUE(Info, '$.SalesPerson.Name') as [Sales Person],
	JSON_QUERY(Info, '$.Customer')	as Customer
FROM Sales.SalesOrder_json

-- Query that returns several values from different properties in JSON column.
SELECT SalesOrderNumber, OrderDate, ShipDate, Status, AccountNumber, TotalDue,
	JSON_VALUE(Info, '$.ShippingInfo.Province') as [Shipping Province], 
	JSON_VALUE(Info, '$.ShippingInfo.Method') as [Shipping Method], 
	JSON_VALUE(Info, '$.ShippingInfo.ShipRate') as ShipRate,
	JSON_VALUE(Info, '$.BillingInfo.Address') as [Billing Address],
	JSON_VALUE(Info, '$.SalesPerson.Name') as [Sales Person],
	JSON_VALUE(Info, '$.Customer.Name')	as Customer
FROM Sales.SalesOrder_json
WHERE JSON_VALUE(Info, '$.Customer.Name') = 'Edwin Shen'

-- Equivalent query that uses OPENJSON instead of several JSON_VALUE functions:
SELECT SalesOrderNumber, OrderDate, ShipDate, Status, AccountNumber, TotalDue,
	[Shipping Province], [Shipping Method], ShipRate, [Sales Person], Customer
FROM Sales.SalesOrder_json
	CROSS APPLY OPENJSON(Info)
		WITH ([Shipping Province] nvarchar(100) '$.ShippingInfo.Province',
				[Shipping Method] nvarchar(20) '$.ShippingInfo.Method',
				ShipRate float '$.ShippingInfo.ShipRate',
				[Billing Address] nvarchar(100) '$.BillingInfo.Address',
				[Sales Person] nvarchar(100) '$.SalesPerson.Name',
				Customer nvarchar(4000) '$.Customer.Name') AS SalesOrderInfo
WHERE Customer = 'Edwin Shen'
GO

-- Executing stored procedures

-- Find person rows by ids 1,4,7, and 12.
EXEC Person.PersonList_json '[1,4,7,12]'

-- Return informaiton about person with id 4
EXEC Person.PersonInfo_json 4

-- Find all person rows with specified email
EXEC Person.PersonSearchByEmail_json 'ken0@adventure-works.com'

-- Find all person rows with specified phone number
EXEC Person.PersonSearchByPhone_json '330-555-2568'

-- Get information about sales order with id 43659
EXEC Sales.SalesOrderInfo_json 43659

-- Export information about sales order with id 43659 as JSON text
EXEC Sales.SalesOrderExport_json 43659

-- Find sales orders with ids 43659,43660,43661,43662, and 43663.
EXEC Sales.SalesOrderList_json '[43659,43660,43661,43662,43663]'

-- Find all sales orders with specified sales price.
EXEC Sales.SalesOrderSearchByReason_json 'Price'

/*
Note: These procedures require Full-Text Search indexes.
Uncomment these lines only if you have FTS installed!

-- Find all sales orders with specified sales price using Full-Text Search
-- Note: skip this query if you don't have FTS.
EXEC Sales.SalesOrderSearchByReasonQuery_json 'Price'

-- Find all sales orders with specified sales prices using Full-Text Search
-- Note: skip this query if you don't have FTS.
EXEC Sales.SalesOrderSearchByReasonQuery_json 'Price OR Quality'

*/

-- Find all sales orders with specified customer.
EXEC Sales.SalesOrderSearchByCustomer_json 'Joe Rana'
-- Note: this query uses index on JSON property.

GO

-- Querying views
-- Returns number of orders for specified customer.
-- Note: This view uses JSON_VALUE to fetch data from JSON
SELECT count(*) FROM Sales.vwSalesOrderInfo_json
WHERE Customer = 'Edwin Shen'

-- Returns number of orders for specified customer.
-- Note: This view uses OPENJSON to fetch data from JSON
SELECT count(*) FROM Sales.vwSalesOrderInfo2_json
WHERE Customer = 'Edwin Shen'

GO

-- Import/export data
-- Example 1.1: Format SalesOrder as JSON result
SELECT SalesOrderID,RevisionNumber,OrderDate,DueDate,ShipDate,Status,
		OnlineOrderFlag,PurchaseOrderNumber,AccountNumber,CustomerID,
		CreditCardApprovalCode,CurrencyRateID,SubTotal,TaxAmt,Freight,Comment
FROM Sales.SalesOrder_json
WHERE SalesOrderID = 43659
FOR JSON PATH

-- Example 1.2: Format SalesOrder as JSON result using stored procedure.
EXEC Sales.SalesOrderExport_json 43659

GO

-- Example 2: Insert SalesOrder with id 1 formatted as JSON string
-- Note:  We are using fields from a sales order 43659 exported in previous step.
-- Only SalesOrderID key is changed from 43659 to 1 in order to have unique primary key.
declare @json nvarchar(max) = '{"SalesOrderID":1,"RevisionNumber":27,"OrderDate":"2005-07-01T00:00:00","DueDate":"2005-07-13T00:00:00","ShipDate":"2005-07-08T00:00:00","Status":5,"OnlineOrderFlag":false,"PurchaseOrderNumber":"PO522145787","AccountNumber":"10-4020-000676","CreditCardApprovalCode":"105041Vi84182","SubTotal":20565.6206,"TaxAmt":1971.5149,"Freight":616.0984,"CustomerID":29825}'
EXEC Sales.SalesOrderInsert_json @json

-- Verify that it is inserted and compare results with original sales order (43659):
EXEC Sales.SalesOrderList_json '[1,43659]'

GO

-- Example 3: Update SalesOrder with id 1 formatted as JSON string
-- Note: All fields are same except RevisionNumber that is increased to 28:
declare @json nvarchar(max) = '{"SalesOrderID":1,"RevisionNumber":28,"OrderDate":"2005-07-01T00:00:00","DueDate":"2005-07-13T00:00:00","ShipDate":"2005-07-08T00:00:00","Status":5,"OnlineOrderFlag":false,"PurchaseOrderNumber":"PO522145787","AccountNumber":"10-4020-000676","CreditCardApprovalCode":"105041Vi84182","SubTotal":20565.6206,"TaxAmt":1971.5149,"Freight":616.0984,"CustomerID":29825}'
EXEC Sales.SalesOrderUpdate_json @json

-- Verify that revision number is updated (compare it with original row (43659)):
EXEC Sales.SalesOrderList_json '[1,43659]'

/*******************************************************************************************************
*	Workload cleanup
*******************************************************************************************************/

-- Delete sales order that is inserted in query examples section.
DELETE Sales.SalesOrder_json
WHERE SalesOrderID = 1

--	Cleanup indexes, views, and procedures
if( (select count(*) from sys.fulltext_indexes where object_id = object_id('Person.Person_json')) = 1)
begin
	print 'Dropping FT index on Person.Person_json'
	DROP FULLTEXT INDEX ON Person.Person_json
end
if( (select count(*) from sys.fulltext_indexes where object_id = object_id('Sales.SalesOrder_json')) = 1)
begin
	print 'Dropping FT index on Sales.SalesOrder_json'
	DROP FULLTEXT INDEX ON Sales.SalesOrder_json
end
if( (select count(*) from sys.fulltext_catalogs where name = 'jsonFullTextCatalog') = 1)
begin
	print 'Dropping FT catalog jsonFullTextCatalog'
	DROP FULLTEXT CATALOG jsonFullTextCatalog
end
go
-- Using new DROP IF EXISTS syntax for tables, views, indexes, procedures, and functions 
DROP INDEX IF EXISTS idx_SalesOrder_json_CustomerName ON Sales.SalesOrder_json
go
DROP PROCEDURE IF EXISTS Person.PersonList_json
go
DROP PROCEDURE IF EXISTS Person.PersonInfo_json
go
DROP PROCEDURE IF EXISTS Person.PersonInsert_json
go
DROP PROCEDURE IF EXISTS Person.PersonUpdate_json
go
DROP PROCEDURE IF EXISTS Person.PersonSearchByPhone_json
go
DROP PROCEDURE IF EXISTS Person.PersonSearchByPhoneNumberAndType_json
go
DROP PROCEDURE IF EXISTS Person.PersonSearchByEmail_json
go
DROP PROCEDURE IF EXISTS Person.PersonSearchByEmailAddressQuery_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderSearchByReason_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderSearchByReasonQuery_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderSearchByCustomer_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderList_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderInfo_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderInfoRel_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrdersBySalesReasonReport_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrdersPerCustomerAndStatusReport_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderExport_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderInsert_json
go
DROP PROCEDURE IF EXISTS Sales.SalesOrderUpdate_json
go
DROP VIEW IF EXISTS Sales.vwSalesOrderInfo_json
go
DROP VIEW IF EXISTS Sales.vwSalesOrderItems_json
go
DROP VIEW IF EXISTS Sales.vwSalesOrderInfo_json
go
DROP VIEW IF EXISTS Sales.vwSalesOrderInfo2_json
go
DROP VIEW IF EXISTS Sales.vwSalesOrderInfoRel_json
go
DROP FUNCTION IF EXISTS dbo.ufnToRawJsonArray
go
-- Drop JSON columns and constraints
GO
ALTER TABLE Sales.SalesOrder_json
DROP
	COLUMN IF EXISTS vCustomerName,
	CONSTRAINT IF EXISTS [SalesOrder reasons must be formatted as JSON array],
	COLUMN IF EXISTS SalesReasons,
	CONSTRAINT IF EXISTS [SalesOrder items must be formatted as JSON array],
	COLUMN IF EXISTS OrderItems,
	CONSTRAINT IF EXISTS [SalesOrder additional information must be formatted as JSON],
	COLUMN IF EXISTS Info
	
GO
ALTER TABLE Person.Person_json
DROP
	CONSTRAINT IF EXISTS [Phone numbers must be formatted as JSON array],
	COLUMN IF EXISTS PhoneNumbers,
	CONSTRAINT IF EXISTS [Email addresses must be formatted as JSON array],
	COLUMN IF EXISTS EmailAddresses
GO

