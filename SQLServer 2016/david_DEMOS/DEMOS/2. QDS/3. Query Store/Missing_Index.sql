IF NOT EXISTS (SELECT * from sys.schemas where name = 'Missing')
EXEC ('CREATE SCHEMA Missing')

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Missing].[Address]') AND type in (N'U'))
DROP TABLE [Missing].[Address]
GO
SELECT * 
INTO Missing.Address
FROM Person.Address

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Missing].[BusinessEntity]') AND type in (N'U'))
DROP TABLE [Missing].[BusinessEntity]
GO

SELECT * 
INTO Missing.BusinessEntity
FROM Person.BusinessEntity

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Missing].[BusinessEntityAddress]') AND type in (N'U'))
DROP TABLE [Missing].[BusinessEntityAddress]
GO

SELECT * 
INTO Missing.BusinessEntityAddress
FROM Person.BusinessEntityAddress


/*When running this query select actual execution plan. Once the query excecutes, open the execution plan and note 
the missing index in green. Right click the missing index and view the missing index details. Note that there is 
only one index mentioned. Return to the execution plan and right click anywhere in the plan and click on 
"Show Execution Plan XML" In the XML search for missingindexes. You will find the MissingIndexes tag and can 
see that there are actually two missing indexes for this query. The graphical plan will only show one.
*/

select * 
from Missing.BusinessEntity BE
join Missing.BusinessEntityAddress BEA on BE.[BusinessEntityID] = BEA.[BusinessEntityID]
join Missing.Address A on BEA.[AddressID] = a.[AddressID]
GO 25

select * from Person.Person where FirstName = 'John'
GO 20

SELECT * FROM Person.Person 
WHERE MiddleName is not null AND FirstName = 'David'
GO 15

SELECT * FROM Person.Address
WHERE City = 'Bothel' and AddressLine2 is not null
GO 25

SELECT * FROM [Sales].[SalesOrderDetail]
WHERE [CarrierTrackingNumber] = '4911-403C-98'
GO 20

SELECT * FROM [Sales].[SalesOrderDetail]
WHERE SalesOrderDetailID Between 1000 and 1200 
GO 15

SELECT * FROM Person.Address
WHERE PostalCode = '98011'
GO 100
