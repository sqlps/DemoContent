USE master
GO

USE ContosoOLTP
GO

SELECT * FROM dbo.SalesOrders_disk WHERE order_id=1
GO

SELECT * FROM dbo.SalesOrders WHERE order_id=1
GO

UPDATE dbo.SalesOrders SET order_status=3 WHERE order_id=1
GO

-- T2
-- step 2
BEGIN TRAN
  SELECT * FROM dbo.SalesOrders_disk WITH (REPEATABLEREAD)
    WHERE order_id=1

-- step 4
  UPDATE dbo.SalesOrders_disk WITH (REPEATABLEREAD)
    SET order_status=3
	WHERE order_id=2
COMMIT
GO

-- T2 
-- step 2
BEGIN TRAN
  SELECT * FROM dbo.SalesOrders WITH (REPEATABLEREAD)
    WHERE order_id=1

-- step 4
  UPDATE dbo.SalesOrders WITH (REPEATABLEREAD)
    SET order_status=3
	WHERE order_id=2
-- step 6
COMMIT




-- T2
-- step 2
BEGIN TRAN
  UPDATE dbo.SalesOrders_disk WITH (READCOMMITTED)
    SET order_status=4
	WHERE order_id=2

-- step 4
  SELECT * FROM dbo.SalesOrders_disk WITH (READCOMMITTED)
    WHERE order_id=1
COMMIT



-- T2
-- step 2
BEGIN TRAN
  UPDATE dbo.SalesOrders WITH (SNAPSHOT)
    SET order_status=4
	WHERE order_id=2

-- step 4
  SELECT * FROM dbo.SalesOrders WITH (SNAPSHOT)
    WHERE order_id=1
COMMIT
