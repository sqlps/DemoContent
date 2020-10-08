--
-- RESET Script
--
USE AdventureWorksDW2008Big_CCI
GO

--
-- Delete all rows for Demo
--
DELETE FROM FactSales WHERE OrderDateKey = 20040708
GO

