USE WideWorldImportersDW;
GO

-------------------------------------------
-- *** Batch-Mode Adaptive Join Demo *** --
-------------------------------------------
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

-- Show actual execution plan
-- Is there an adaptive join, if merge join, check for column store index (only works if batch operators can be used)
-- notice the estimated join type and actual join type

SELECT  
	o.[Order Key], 
	si.[Lead Time Days], 
	o.[Quantity]
FROM Fact.[Order] AS o
INNER JOIN Dimension.[Stock Item] AS si ON 
	o.[Stock Item Key] = si.[Stock Item Key]
WHERE   
	o.[Quantity] = 360;

--returns 206 rows


-- Inserting quantity row that doesn't exist in the table yet

INSERT Fact.[Order] 
(
	[City Key], 
	[Customer Key], 
	[Stock Item Key], 
	[Order Date Key], 
	[Picked Date Key], 
	[Salesperson Key], 
	[Picker Key], 
	[WWI Order ID], 
	[WWI Backorder ID], 
	[Description], 
	[Package], 
	[Quantity], 
	[Unit Price], 
	[Tax Rate], 
	[Total Excluding Tax], 
	[Tax Amount], 
	[Total Including Tax], 
	[Lineage Key]
)
SELECT TOP 5 
	[City Key], 
	[Customer Key], 
	[Stock Item Key],
	[Order Date Key], 
	[Picked Date Key], 
	[Salesperson Key], 
	[Picker Key], 
	[WWI Order ID], 
	[WWI Backorder ID], 
	[Description], 
	[Package], 
	361, 
	[Unit Price], 
	[Tax Rate], 
	[Total Excluding Tax], 
	[Tax Amount], 
	[Total Including Tax], 
	[Lineage Key]
FROM Fact.[Order];



SELECT  
	o.[Order Key], 
	si.[Lead Time Days], 
	o.[Quantity]
FROM	Fact.[Order] AS o
INNER JOIN Dimension.[Stock Item] AS si ON
	o.[Stock Item Key] = si.[Stock Item Key]
WHERE   
	o.[Quantity] = 361;


-- Clean up 
DELETE Fact.[Order] 
WHERE Quantity = 361;
