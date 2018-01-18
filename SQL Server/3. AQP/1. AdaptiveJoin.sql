-------------------------------------------
-- *** Batch-Mode Adaptive Join Demo *** --
-------------------------------------------

-- ============================================================================================================
-- Step 1) Change to native compat
-- ============================================================================================================
USE [master]
GO
ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 140
GO

USE WideWorldImportersDW;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
-- ============================================================================================================
-- Step 2) Run query with SQL 2017 compatibility
-- ============================================================================================================
-- Is there an adaptive join, if merge join, check for column store index (only works if batch operators can be used)
-- notice the estimated join type and actual join type. Estimated and actual should match
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


-- ============================================================================================================
-- Step 3) Inserting quantity row that doesn't exist in the table yet
-- ============================================================================================================
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


-- ============================================================================================================
-- Step 4) Let's see how Adaptive join helps now
-- ============================================================================================================
-- Notice the Actual vs Estimated
-- Hash match assumes both tables are equal in size
-- Nested Loop join is effective if the outer loop is small and the inner input is large and indexed.
-- Outer table is top, inner table is bottom

SELECT  
	o.[Order Key], 
	si.[Lead Time Days], 
	o.[Quantity]
FROM	Fact.[Order] AS o
INNER JOIN Dimension.[Stock Item] AS si ON
	o.[Stock Item Key] = si.[Stock Item Key]
WHERE   
	o.[Quantity] = 361;

-- ============================================================================================================
-- Step 5) Let's set compatibility to 130 , clear cache and re-run
-- ============================================================================================================
USE [master]
GO
ALTER DATABASE [WideWorldImportersDW] SET COMPATIBILITY_LEVEL = 130
GO

USE WideWorldImportersDW;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

SELECT  
	o.[Order Key], 
	si.[Lead Time Days], 
	o.[Quantity]
FROM	Fact.[Order] AS o
INNER JOIN Dimension.[Stock Item] AS si ON
	o.[Stock Item Key] = si.[Stock Item Key]
WHERE   
	o.[Quantity] = 361;


-- ============================================================================================================
-- Step 6) Clean up
-- ============================================================================================================
DELETE Fact.[Order] 
WHERE Quantity = 361;
