-- https://msdn.microsoft.com/en-us/library/mt734211(v=sql.1).aspx
use WideWorldImporters
GO

EXECUTE DataLoadSimulation.PopulateDataToCurrentDate
        @AverageNumberOfCustomerOrdersPerDay = 5000,
        @SaturdayPercentageOfNormalWorkDay = 80,
        @SundayPercentageOfNormalWorkDay = 25,
        @IsSilentMode = 1,
        @AreDatesPrinted = 1;
