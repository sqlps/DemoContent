USE AdventureWorksDW2012
GO

DROP TABLE FactResellerSalesPartCopy
GO

CREATE TABLE [dbo].[FactResellerSalesPartCopy](
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[ResellerKey] [int] NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[SalesTerritoryKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[ExtendedAmount] [money] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [money] NULL,
	[TotalProductCost] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[Freight] [money] NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[CustomerPONumber] [nvarchar](25) NULL
) 
GO

--Loop until you have about 6million records in the table. 
Declare @Counter int = 0
While @Counter < 100 -- You may need to increase this if you've got a SSDs or high perfoming Demo environment
Begin
	INSERT INTO FactResellerSalesPartCopy 
	SELECT [ProductKey]
		  ,[OrderDateKey]
		  ,[DueDateKey]
		  ,[ShipDateKey]
		  ,[ResellerKey]
		  ,[EmployeeKey]
		  ,[PromotionKey]
		  ,[CurrencyKey]
		  ,[SalesTerritoryKey]
		  ,[SalesOrderNumber]
		  ,[SalesOrderLineNumber]
		  ,[RevisionNumber]
		  ,[OrderQuantity]
		  ,[UnitPrice]
		  ,[ExtendedAmount]
		  ,[UnitPriceDiscountPct]
		  ,[DiscountAmount]
		  ,[ProductStandardCost]
		  ,[TotalProductCost]
		  ,[SalesAmount]
		  ,[TaxAmt]
		  ,[Freight]
		  ,[CarrierTrackingNumber]
		  ,[CustomerPONumber]
	  FROM [AdventureWorksDW2012].[dbo].[FactResellerSales]
	  SET @Counter += 1
  End
  GO

--Create Regular Clustered Index
CREATE CLUSTERED INDEX [CI_FactReseller] ON [dbo].[FactResellerSalesPartCopy]
(
	[OrderDateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

-- Now create a columnstore index on the table
-- Takes about 30 sec on my laptop w/ 8GB memory with other programs running
create nonclustered columnstore index ncci on dbo.FactResellerSalesPartCopy
           ([ProductKey]
           ,[OrderDateKey]
           ,[DueDateKey]
           ,[ShipDateKey]
           ,[ResellerKey]
           ,[EmployeeKey]
           ,[PromotionKey]
           ,[CurrencyKey]
           ,[SalesTerritoryKey]
           ,[SalesOrderNumber]
           ,[SalesOrderLineNumber]
           ,[RevisionNumber]
           ,[OrderQuantity]
           ,[UnitPrice]
           ,[ExtendedAmount]
           ,[UnitPriceDiscountPct]
           ,[DiscountAmount]
           ,[ProductStandardCost]
           ,[TotalProductCost]
           ,[SalesAmount]
           ,[TaxAmt]
           ,[Freight]
           ,[CarrierTrackingNumber]
           ,[CustomerPONumber]
		   );
GO

--Test the ability to update a table with a NC Columnstore Index in place
--SHOW EXECUTION PLAN
UPDATE FactResellerSalesPartCopy
SET DiscountAmount = 10
WHERE ProductKey = 561 AND ShipDateKey = 20080608 AND CurrencyKey = 100
AND SalesTerritoryKey = 1 AND SalesOrderLineNumber = 15