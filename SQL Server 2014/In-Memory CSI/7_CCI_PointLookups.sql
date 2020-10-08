Set Statistics IO ON
Set Statistics Time On
GO

--First let's check our CCI
Select SalesOrderNumber,OrderDateKEy, ShipDateKey, SalesAmount 
from AdventureWorksDW2008Big_CCI..FactSales
where SalesOrderNumber = 'SO55323-20020707-28'

--Now our NCCI
Select SalesOrderNumber,OrderDateKEy, ShipDateKey, SalesAmount 
from AdventureWorksDW2008Big_NCCI..FactSales
where SalesOrderNumber = 'SO55323-20020707-28'

--How about an Indexed View on the CCI
Select SalesOrderNumber,OrderDateKEy, ShipDateKey, SalesAmount 
from AdventureWorksDW2008Big_CCI..vFactSales
where SalesOrderNumber = 'SO55323-20020707-28'