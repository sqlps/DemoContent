USE [AdventureWorksDW2008Big]
GO

CREATE NONCLUSTERED INDEX [NCI_FactResellerSalesPart_SalesTerritoryKey] ON [dbo].[FactResellerSalesPart]
(
	[SalesTerritoryKey] ASC
)
INCLUDE ([ExtendedAmount]) ON ByOrderDateMonthRange(OrderDateKey)
GO


CREATE NONCLUSTERED INDEX [NCI_FactResellerSalesPartNonAligned_SalesTerritoryKey] ON [dbo].[FactResellerSalesPartNonAligned]
(
	[SalesTerritoryKey] ASC
)
INCLUDE ([ExtendedAmount])  ON [PRIMARY]
GO



--Let's see partition elimination in action
--View Graphical Execution plan
Set Statistics IO On
Set Statistics Time On

Select OrderDateKey, Sum(ExtendedAmount) from FactResellerSalesPart
Where SalesTerritoryKey =5 and OrderDateKey < 20020801
Group by OrderDateKey
GO

Select OrderDateKey, Sum(ExtendedAmount) from FactResellerSalesPartNonAligned
Where  SalesTerritoryKey =5 and OrderDateKey < 20020801
Group by OrderDateKey

GO

select top 10 * from FactResellerSales

