USE WideWorldImportersDW;
GO
---------------------------------------------------
-- *** Batch-Mode Memory Grant Feedback Demo *** --
---------------------------------------------------
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

-- Intentionally forcing a row underestimate
DROP PROCEDURE IF EXISTS FactOrderByLineageKey;
GO
CREATE PROCEDURE FactOrderByLineageKey
	@LineageKey INT 
AS
SELECT   
	o.[Order Key], 
	o.[Description] 
FROM    Fact.[Order] AS o
INNER HASH JOIN Dimension.[Stock Item] AS si ON 
	o.[Stock Item Key] = si.[Stock Item Key]
WHERE   
	o.[Lineage Key] = @LineageKey
	AND si.[Lead Time Days] > 0
ORDER BY 
	o.[Stock Item Key], 
	o.[Order Date Key] DESC
OPTION (MAXDOP 1);
GO

-- Compiled and executed using a lineage key that doesn't have rows
EXEC FactOrderByLineageKey 8;

-- Execute this query a few times - each time looking at 
-- the plan to see impact on spills, memory grant size, and run time
EXEC FactOrderByLineageKey 9;
