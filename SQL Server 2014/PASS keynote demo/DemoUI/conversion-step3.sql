USE Fabrikam
GO


USE FabrikamDev
GO
ALTER PROCEDURE [dbo].[sp_find_most_purchased_products_by_type]
	@type int, @top_x int
AS BEGIN
	SELECT TOP 5 ProductId, [Type] as purchases FROM most_recommended_products_after WHERE [type] = @type ORDER BY Ranking DESC
END
GO
