--Make sure to show the actual execution plans

Select Sum(OrderQUantity)
From AdventureWorksDW2008Big_NCCI..FactSales
where SalesOrderNumber = 'SO69532-20020701-22'
GO

Select sum(orderquantity)
From AdventureWorksDW2008Big_CCI..FactSales
where SalesOrderNumber = 'SO69532-20020701-22'
GO

Select Sum(OrderQUantity)
From AdventureWorksDW2008Big_NCCI..FactSales
--where SalesOrderNumber = 'SO69532-20020701-22'
GO

Select sum(orderquantity)
From AdventureWorksDW2008Big_CCI..FactSales
--where SalesOrderNumber = 'SO69532-20020701-22'
GO
