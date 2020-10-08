--Configure query for profiling with sys.dm_exec_query_profiles
SET STATISTICS PROFILE ON;
GO
--Optionally return the final results of the query to SHOWPLAN XML
SET SHOWPLAN XML ON;
GO
--Next, run your query in this session
USE AdventureWorks2012;
GO
--Hey look at me drive CPU
select * from Production.Product P
CROSS Join Production.ProductCategory
CROSS JOIN Production.ProductDescription
Where P.Name Not Like '%Nut%' and  ProductNumber not in ('HN-3816','CS-6583','RW-M928')
Go


/**************
 * NEW WINDOW *
 **************/
 
SELECT  
       node_id,physical_operator_name, SUM(row_count) row_count, SUM(estimate_row_count) AS estimate_row_count, 
   CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count)
FROM sys.dm_exec_query_profiles 
WHERE session_id> 50
GROUP BY node_id,physical_operator_name
ORDER BY node_id;