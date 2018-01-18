USE master;
GO

ALTER DATABASE WideWorldImportersDW SET COMPATIBILITY_LEVEL = 140;
GO
USE WideWorldImportersDW;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO



-- Our "after" state (with Interleaved execution) 
-- Include Actual Execution Plan
-- Look for IsInterleaveExecuted and ContainsInterleave

SELECT  
	o.[Order Key], 
	o.[Description], 
	o.[Package],
	o.[Quantity], 
	oeq.[OutlierEventQuantity]
FROM Fact.[Order] AS o
/* Notice the INNER JOIN, why aren't we using CROSS APPLY? */
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
--		Notice the TVF estimated number of rows (did it change?)
--		Any spills?


SELECT  
	o.[Order Key], 
	o.[Description], 
	o.[Package],
	o.[Quantity], 
	oeq.[OutlierEventQuantity]
FROM Fact.[Order] AS o
CROSS APPLY 
(
	SELECT 
		x.[OutlierEventQuantity]
	FROM Fact.[WhatIfOutlierEventQuantity]('Mild Recession','1-01-2013','10-15-2014') AS x 
	WHERE
		o.[Order Key] = x.[Order Key]
		AND o.[City Key] = x.[City Key]
		AND o.[Customer Key] = x.[Customer Key]
		AND o.[Stock Item Key] = x.[Stock Item Key]
		AND o.[Order Date Key] = x.[Order Date Key]
		AND o.[Picked Date Key] = x.[Picked Date Key]
		AND o.[Salesperson Key] = x.[Salesperson Key]
		AND o.[Picker Key] = x.[Picker Key]
) AS oeq
INNER JOIN Dimension.[Stock Item] AS si ON 
	o.[Stock Item Key] = si.[Stock Item Key]
WHERE   
	si.[Lead Time Days] > 0
	AND o.[Quantity] > 50;