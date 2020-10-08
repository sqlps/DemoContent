/*
Author: SQLMaestros.com
*/
USE OA_DB

SET NOCOUNT ON
/*
select count(1) - 9153183 NewRows_Cnt, count(1) Total_Cnt from orders
select count(1) - 9153183 NewRows_Cnt, count(1) Total_Cnt from ordersCS
*/
 
--Cleanup new records 
delete from orders where OrderID > 9153183
delete from ordersCS where OrderID > 9153183

SET NOCOUNT OFF