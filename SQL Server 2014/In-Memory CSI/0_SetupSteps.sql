--Create Indexed View
USE [AdventureWorksDW2008Big_CCI]
GO
CREATE VIEW dbo.vFactSales
WITH SCHEMABINDING
AS
    Select SalesOrderNumber,OrderDateKEy, ShipDateKey, SalesAmount 
	from dbo.FactSales 
GO
CREATE UNIQUE CLUSTERED INDEX IDX_V1 
    ON dbo.vFactSales (SalesOrderNumber, OrderDateKEy, ShipDateKey, SalesAmount );
Go

--Create NCI on NCCI 
USE [AdventureWorksDW2008Big_NCCI]
GO

CREATE NONCLUSTERED INDEX [NCI_SalesOrderNumber_FactSales] ON [dbo].[FactSales]
(
	[SalesOrderNumber] ASC
)
INCLUDE ( 	[OrderDateKey],
	[ShipDateKey],
	[SalesAmount]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

