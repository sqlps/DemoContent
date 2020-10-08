-- =====================================================================================================
-- Step 1) Kick off workload
-- =====================================================================================================

-- C:\Demos\WWI - Original\workload-drivers\order-insert

-- =====================================================================================================
-- Step 2) Find rate at which stock is being sold
-- =====================================================================================================

USE WideWorldImporters;
GO
SET NOCOUNT ON
GO


DECLARE @StartingTime datetime2(7) = SYSDATETIME();

SELECT ol.StockItemID, [Description], SUM(Quantity - PickedQuantity) AS AllocatedQuantity
FROM Sales.OrderLines AS ol --WITH (NOLOCK)
GROUP BY ol.StockItemID, [Description];

PRINT 'Using nonclustered columnstore index: ' + CAST(DATEDIFF(millisecond, @StartingTime, SYSDATETIME()) AS varchar(20)) + ' ms';

SET @StartingTime = SYSDATETIME();

SELECT ol.StockItemID, [Description], SUM(Quantity - PickedQuantity) AS AllocatedQuantity
FROM Sales.OrderLines AS ol --WITH (NOLOCK)
GROUP BY ol.StockItemID, [Description]
OPTION (IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX);

PRINT 'Without nonclustered columnstore index: ' + CAST(DATEDIFF(millisecond, @StartingTime, SYSDATETIME()) AS varchar(20)) + ' ms';
GO
