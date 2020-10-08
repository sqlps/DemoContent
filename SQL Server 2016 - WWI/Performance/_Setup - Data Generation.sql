-- =====================================================================================================
-- Step 1) Kick off workload
-- =====================================================================================================

--See: https://msdn.microsoft.com/en-us/library/mt734211(v=sql.1).aspx
Use WideWorldImporters
GO

  EXECUTE DataLoadSimulation.PopulateDataToCurrentDate
        @AverageNumberOfCustomerOrdersPerDay = 60,
        @SaturdayPercentageOfNormalWorkDay = 50,
        @SundayPercentageOfNormalWorkDay = 0,
        @IsSilentMode = 1,
        @AreDatesPrinted = 1;