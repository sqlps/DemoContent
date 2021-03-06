USE [AdventureWorks2016CTP3]
GO
DROP PROCEDURE IF EXISTS [dbo].[diff_ProductCatalog]
GO
CREATE PROCEDURE
[dbo].[diff_ProductCatalog] @id int, @date datetime2(0), @latest datetime2(0) = null as
begin

	declare @v1 nvarchar(max) = 
		(case when (@latest is null)
			then (select * from ProductCatalog where ProductID = @id for json path, without_array_wrapper)
			else (select * from ProductCatalog for system_time as of @latest where ProductID = @id for json path, without_array_wrapper)
		end)

	declare @v2 nvarchar(max) = 
		(select * from ProductCatalog for system_time as of @date where ProductID = @id for json path, without_array_wrapper)

	select v1.[key] as [Column], v1.value as v1, v2.value as v2
	from openjson(@v1) v1
		join openjson(@v2) v2 on v1.[key] = v2.[key]
	where v1.value <> v2.value

end
