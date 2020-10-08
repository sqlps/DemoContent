SELECT p.Title + ' ' + p.FirstName + ' ' + p.LastName AS FullName,
       c.AccountNumber,
       s.Name
FROM   Person.Person AS p
       INNER JOIN
       Sales.Customer AS c
       ON c.PersonID = p.BusinessEntityID
       INNER JOIN
       Sales.Store AS s
       ON s.BusinessEntityID = c.StoreID
WHERE  p.LastName = 'Koski';

-- loop joins
SELECT FirstName,
       LastName,
       a.ModifiedDate
FROM   Person.Person AS p
       INNER JOIN
       HumanResources.Employee AS e
       ON p.BusinessEntityID = e.BusinessEntityID
       INNER JOIN
       Person.BusinessEntityAddress AS a
       ON e.BusinessEntityID = a.BusinessEntityID
WHERE  e.JobTitle = 'Marketing Assistant';

-- hash match
SELECT soh.BillToAddressID
FROM   Sales.Customer AS c
       LEFT OUTER JOIN
       Sales.SalesOrderHeader AS soh
       ON c.CustomerID = soh.CustomerID;


--merge join
SELECT poh.PurchaseOrderID,
       poh.OrderDate,
       pod.ProductID,
       pod.DueDate,
       poh.VendorID
FROM   Purchasing.PurchaseOrderHeader AS poh
       INNER JOIN
       Purchasing.PurchaseOrderDetail AS pod
       ON poh.PurchaseOrderID = pod.PurchaseOrderID;


-- hash match
SELECT soh.PurchaseOrderNumber,
       soh.AccountNumber,
       sod.OrderQty,
       sod.LineTotal,
       c.CardNumber
FROM   Sales.SalesOrderHeader AS soh
       INNER JOIN
       Sales.SalesOrderDetail AS sod
       ON soh.SalesOrderID = sod.SalesOrderID
       INNER JOIN
       Sales.CreditCard AS c
       ON soh.CreditCardID = c.CreditCardID;

-- hash + parallelism
-- what happens to the cost when the order by is dropped?
SELECT   p.Name,
         sod.OrderQty,
         sod.UnitPrice
FROM     Production.Product AS p
         INNER JOIN
         Sales.SalesOrderDetail AS sod
         ON p.ProductID = sod.ProductID
ORDER BY p.Name DESC;

















