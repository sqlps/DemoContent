DECLARE @orderqty int
DECLARE @unitprice money
SET @orderqty = 12
SET @unitprice = 35.00
SELECT * FROM Sales.SalesOrderDetail s
INNER JOIN Production.Product p ON s.ProductID = p.ProductID
WHERE s.OrderQty > @orderqty AND s.UnitPrice > @unitprice

DECLARE @orderqty1 int
DECLARE @unitprice1 money
SET @orderqty1 = 1
SET @unitprice1 = 26.00
SELECT * FROM Sales.SalesOrderDetail s
INNER JOIN Production.Product p ON s.ProductID = p.ProductID
WHERE s.OrderQty > @orderqty1 AND s.UnitPrice > @unitprice1

DECLARE @orderqty2 int
DECLARE @unitprice2 money
SET @orderqty2 = 102
SET @unitprice2 = 102.00
SELECT * FROM Sales.SalesOrderDetail s
INNER JOIN Production.Product p ON s.ProductID = p.ProductID
WHERE s.OrderQty > @orderqty2 AND s.UnitPrice > @unitprice2

DECLARE @orderqty3 int
DECLARE @unitprice3 money
SET @orderqty3 = 120
SET @unitprice3 = 3500.00
SELECT * FROM Sales.SalesOrderDetail s
INNER JOIN Production.Product p ON s.ProductID = p.ProductID
WHERE s.OrderQty > @orderqty3 AND s.UnitPrice > @unitprice3

SELECT * FROM Production.TransactionHistory th
INNER JOIN Production.TransactionHistoryArchive tha ON th.Quantity = tha.Quantity

COMMIT;

WAITFOR DELAY '00:00:01';