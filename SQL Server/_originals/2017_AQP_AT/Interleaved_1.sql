USE master
GO

ALTER DATABASE WideWorldImportersDW SET COMPATIBILITY_LEVEL = 130;
GO

USE WideWorldImportersDW;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

----------------------------------------
-- *** Interleaved Execution Demo *** --
----------------------------------------

SET STATISTICS TIME OFF
-- Our "before" state 
-- Include Actual Execution Plan
SELECT  
	o.[Order Key], 
	o.[Description], 
	o.[Package],
	o.[Quantity], 
	oeq.[OutlierEventQuantity]
FROM    Fact.[Order] AS o
INNER JOIN Fact.[WhatIfOutlierEventQuantity]('Mild Recession','1-01-2013','10-15-2014') AS oeq ON 
	o.[Order Key] = oeq.[Order Key]
    AND o.[City Key] = oeq.[City Key]
    AND o.[Customer Key] = oeq.[Customer Key]
    AND o.[Stock Item Key] = oeq.[Stock Item Key]
    AND o.[Order Date Key] = oeq.[Order Date Key]
    AND o.[Picked Date Key] = oeq.[Picked Date Key]
    AND o.[Salesperson Key] = oeq.[Salesperson Key]
    AND o.[Picker Key] = oeq.[Picker Key]
INNER JOIN Dimension.[Stock Item] AS si ON 
	o.[Stock Item Key] = si.[Stock Item Key]
WHERE   
	si.[Lead Time Days] > 0
	AND o.[Quantity] > 50;

-- Plan observations:
--		Notice the TVF estimated number of rows
--		Notice the spills 
----------------------------------
-- TODO (open separate window to compare plan shapes)