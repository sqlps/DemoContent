/*Interleaved only works with ReadOnly queries*/

WITH cte_rowsToUpdate AS
(
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
	AND o.[Quantity] > 50
)

UPDATE cte_rowsToUpdate
SET Description = Description + ' ' + CONVERT(NVARCHAR(20), GETDATE() ,121)