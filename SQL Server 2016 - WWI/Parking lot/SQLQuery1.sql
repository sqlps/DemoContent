-- https://msdn.microsoft.com/en-us/library/mt734203(v=sql.1).aspx


--JSON
exec Website.SearchForCustomers '', 9
--App Sesstings stored as JSON
select * from Application.SystemParameters
--USer preference stored as JSON
Select * from  Application.People

--IMOLTP
select top 10 * from Warehouse.ColdRoomTemperatures
select top 10 * from Warehouse.VehicleTemperatures
Website.RecordColdRoomTemperatures

--CSI
select count(*) from Warehouse.StockItemTransactions 
select top 10 * from Warehouse.StockItemTransactions 

--ddm
execute as user  = 'ddm_user'
select top 10* from Purchasing.Suppliers
revert


--String split
select value, *
from sales.Invoices
CROSS APPLY string_split(DeliveryInstructions,',')  