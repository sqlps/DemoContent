-- ===================================
-- Step 1) Operational Analytics Query
-- ===================================
Use Adventureworks2016CTP3_AG
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO
Select PC.Name 'Category', PS.Name 'Sub-Category',  Sum(SOD.OrderQty) 'TotalOrders', SOD.ModifiedDate
from Sales.SalesOrderDetail_ondisk SOD
Inner join Sales.SalesOrderHeader_ondisk SOH
on SOD.SalesOrderID = SOH.SalesOrderID
inner join Production.Product_ondisk P
On P.ProductID = SOD.ProductID
inner join Production.ProductSubcategory PS
On p.ProductSubcategoryID = PS.ProductSubcategoryID
Inner Join Production.ProductCategory PC
ON PC.ProductCategoryID = PS.ProductCategoryID
Group BY PC.Name, PS.Name, P.Color, SOD.ModifiedDate
Order by 3 Desc
GO 15
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

-- ===================================
-- Step 2) Create Updateable NCCI
-- ===================================
USE [Adventureworks2016CTP3_AG]
GO

/****** Object:  Index [NCCI_SalesOrderDetail_ondisk]    Script Date: 3/30/2017 10:01:56 PM ******/
CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCI_SalesOrderDetail_ondisk] ON [Sales].[SalesOrderDetail_ondisk]
(
	[ModifiedDate],
	[SalesOrderID],
	[SalesOrderDetailID],
	[CarrierTrackingNumber],
	[OrderQty],
	[ProductID],
	[SpecialOfferID],
	[UnitPrice],
	[UnitPriceDiscount]
)
WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]
GO


-- ===================================
-- Step 3) Re-Run and compare query
-- ===================================
Use Adventureworks2016CTP3_AG
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO
Select PC.Name 'Category', PS.Name 'Sub-Category',  Sum(SOD.OrderQty) 'TotalOrders', SOD.ModifiedDate
from Sales.SalesOrderDetail_ondisk SOD
Inner join Sales.SalesOrderHeader_ondisk SOH
on SOD.SalesOrderID = SOH.SalesOrderID
inner join Production.Product_ondisk P
On P.ProductID = SOD.ProductID
inner join Production.ProductSubcategory PS
On p.ProductSubcategoryID = PS.ProductSubcategoryID
Inner Join Production.ProductCategory PC
ON PC.ProductCategoryID = PS.ProductCategoryID
Group BY PC.Name, PS.Name, P.Color, SOD.ModifiedDate
Order by 3 Desc
GO
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO
