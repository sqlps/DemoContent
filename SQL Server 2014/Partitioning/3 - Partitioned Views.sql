Drop View vw_SalesByTerritory
go
CREATE View vw_SalesByTerritory with Schemabinding
as

Select SalesTerritoryKey, Sum(ExtendedAmount) As Sales, OrderDateKey, Count_Big(*) as 'Totals'
From dbo.FactResellerSalesPart
Group By SalesTerritoryKey, OrderDateKey
Go

Create unique Clustered Index CI_vw_SalesByTerritory On dbo.vw_SalesByTerritory(OrderDateKey, SalesTerritoryKey)
On  ByOrderDateMonthRange(OrderDateKey);

Select SalesTerritoryKey, Sales from vw_SalesByTerritory 
Where OrderDateKey = 20030101 