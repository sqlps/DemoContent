CREATE PROCEDURE usp_RunDiscontinuedCode
AS


------------------------------------------------------------
-- 1. NON ANSI JOIN TYPE
------------------------------------------------------------
-- Using *= Join Type which is same as LEFT OUTER JOIN
Select top 10 *
from Purchasing.PurchaseOrderHeader POH , Purchasing.PurchaseOrderDetail POD
WHERE POD.PurchaseOrderDetailID *= POH.PurchaseOrderID
 
--Should Be
Select top 10 *
from Purchasing.PurchaseOrderHeader POH 
LEFT OUTER JOIN Purchasing.PurchaseOrderDetail POD
ON POD.PurchaseOrderDetailID = POH.PurchaseOrderID

------------------------------------------------------------
-- 2. COMPUTE BY DISCONTINUED IN 2012
------------------------------------------------------------
-- Using COMPUTE KEY WORD
Select top 10 EmployeeID, VendorID, TotalDue
from Purchasing.PurchaseOrderHeader POH 
INNER JOIN Purchasing.PurchaseOrderDetail POD
ON POD.PurchaseOrderDetailID = POH.PurchaseOrderID
ORDER BY EmployeeID, VendorID
COMPUTE SUM(TotalDue) BY EmployeeID, VendorID

-- Using ROLLUP Instead
Select TOP 10 EmployeeID, VendorID, SUM(TotalDue) as 'SUM'
from Purchasing.PurchaseOrderHeader POH 
INNER JOIN Purchasing.PurchaseOrderDetail POD
ON POD.PurchaseOrderDetailID = POH.PurchaseOrderID
GROUP BY TotalDue, EmployeeID, VendorID
WITH ROLLUP
ORDER BY EmployeeID, VendorID

GO