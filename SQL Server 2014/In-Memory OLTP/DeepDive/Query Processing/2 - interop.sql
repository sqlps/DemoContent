-- ================================ Start of interop query demo

-- sample database: [http://msdn.microsoft.com/en-us/library/dn511655.aspx]

--query traditional tables
Use Adventureworks2014
GO

SELECT p.ProductID, sop.SpecialOfferID 
FROM Production.Product_ondisk p JOIN Sales.SpecialOfferProduct sop ON p.ProductID=sop.ProductID
GO

--query memory-optimized tables

SELECT p.ProductID, sop.SpecialOfferID 
FROM Production.Product_inmem p JOIN Sales.SpecialOfferProduct_inmem sop ON p.ProductID=sop.ProductID
GO

-- guess: why are the plans different?


SELECT object_name(object_id), * FROM sys.indexes WHERE object_name(object_id) = 'SpecialOfferProduct'
SELECT object_name(object_id), * FROM sys.indexes WHERE object_name(object_id) = 'SpecialOfferProduct_inmem'
SELECT object_name(object_id), * FROM sys.indexes WHERE object_name(object_id) = 'Product_ondisk'
SELECT object_name(object_id), * FROM sys.indexes WHERE object_name(object_id) = 'Product_inmem'
GO


-- access both types of tables


SELECT p.ProductID, sop.SpecialOfferID 
FROM Production.Product_ondisk p JOIN Sales.SpecialOfferProduct_inmem sop ON p.ProductID=sop.ProductID
GO


-- ============ end of interpreted T-SQL demo
