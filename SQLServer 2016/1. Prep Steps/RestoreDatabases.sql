IF EXISTS (SELECT * FROM sys.databases WHERE name = 'IoT_SmartGrid')
BEGIN
	ALTER DATABASE IoT_SmartGrid SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE IoT_SmartGrid
END
GO
RESTORE DATABASE IoT_SmartGrid FROM  DISK = N'D:\Backup\IoT_SmartGrid.bak'




IF EXISTS (SELECT * FROM sys.databases WHERE name = 'AdventureWorks2016CTP3_AG')
BEGIN
	ALTER AVAILABILITY GROUP [PankajTSP-AG01] REMOVE DATABASE Adventureworks2016CTP3_AG;
	ALTER DATABASE AdventureWorks2016CTP3_AG SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE AdventureWorks2016CTP3_AG
END
GO

USE [master]
RESTORE DATABASE [Adventureworks2016CTP3_AG] FROM  DISK = N'D:\Backup\Adventureworks2016CTP3.bak' WITH  FILE = 1,  
MOVE N'Adventureworks2016CTP3_Data' TO N'D:\Data\Adventureworks2016CTP3_AG_Data.mdf',  MOVE N'Adventureworks2016CTP3_Log' TO N'D:\Data\Adventureworks2016CTP3_AG_Log.ldf',  
MOVE N'Adventureworks2016CTP3_mod' TO N'D:\Data\Adventureworks2016CTP3_AG_mod',  NOUNLOAD,  STATS = 5
GO

ALTER AVAILABILITY GROUP [PankajTSP-AG01]
ADD DATABASE [Adventureworks2016CTP3_AG];
GO


IF EXISTS (SELECT * FROM sys.databases WHERE name = 'INMEM_DB')
BEGIN
	ALTER DATABASE INMEM_DB SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE INMEM_DB
END
GO

USE [master]
RESTORE DATABASE [INMEM_DB] FROM  DISK = N'D:\Backup\INMEM_DB.bak' WITH  FILE = 1,  MOVE N'ElusionX_ProdDB' TO N'D:\DATA\ElusionX_ProdDB.mdf',  MOVE N'ElusionX_ProdDB_log' TO N'D:\DATA\ElusionX_ProdDB_log.ldf',  MOVE N'memory_optimized_file_1' TO N'D:\DATA\memory_optimized_file_11',  NOUNLOAD,  STATS = 5
GO


IF EXISTS (SELECT * FROM sys.databases WHERE name = 'clinic')
BEGIN
	ALTER DATABASE clinic SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE clinic
END
GO

USE [master]
RESTORE DATABASE clinic FROM  DISK = N'F:\Backup\clinic.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
GO


IF EXISTS (SELECT * FROM sys.databases WHERE name = 'PowerConsumption')
BEGIN
	ALTER DATABASE PowerConsumption SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE PowerConsumption
END
GO

USE [master]
RESTORE DATABASE [PowerConsumption] FROM  DISK = N'D:\Backup\PowerConsumption.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'TicketReservations')
BEGIN
	ALTER DATABASE [TicketReservations] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [TicketReservations]
END
GO

USE [master]
RESTORE DATABASE [TicketReservations] FROM  DISK = N'D:\Backup\TicketReservations.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
GO


IF EXISTS (SELECT * FROM sys.databases WHERE name = 'AdventureWorks2016CTP3')
BEGIN
	ALTER DATABASE AdventureWorks2016CTP3 SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE AdventureWorks2016CTP3
END
GO

USE [master]
RESTORE DATABASE [AdventureWorks2016CTP3] FROM  DISK = N'F:\Backup\Adventureworks2016CTP3.bak' WITH  FILE = 1,  
MOVE N'AdventureWorks2016CTP3_Data' TO N'F:\Data\AdventureWorks2016CTP3_Data.mdf',  MOVE N'AdventureWorks2016CTP3_Log' TO N'D:\Data\AdventureWorks2016CTP3_Log.ldf',  
MOVE N'AdventureWorks2016CTP3_mod' TO N'D:\Data\AdventureWorks2016CTP3_mod',  NOUNLOAD,  STATS = 5
GO



USE [master]
RESTORE DATABASE [AdventureworksDW2016CTP3] FROM  DISK = N'F:\Backup\AdventureWorksDW2016CTP3.bak' WITH  FILE = 1, 
MOVE N'AdventureWorksDW2014_Data' TO N'F:\Data\AdventureWorksDW2016CTP3_Data.mdf',  
MOVE N'AdventureWorksDW2014_Log' TO N'F:\Data\AdventureWorksDW2016CTP3_Log.ldf',  NOUNLOAD,  STATS = 5
GO

Use AdventureworksDW2016CTP3
GO

OPEN MASTER KEY DECRYPTION BY PASSWORD = 'P@ssw0rd';
GO
ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'P@ssw0rd';  
GO  

USE [master]
GO
ALTER DATABASE [Adventureworks2016CTP3] SET RECOVERY FULL WITH NO_WAIT
GO



/*
USE [master]
RESTORE DATABASE [AdventureWorks2014] FROM  DISK = N'F:\Backup\AdventureWorks2014.bak' WITH  FILE = 1,  
MOVE N'AdventureWorks2014_Data' TO N'D:\Data\AdventureWorks2014_Data.mdf',  MOVE N'AdventureWorks2014_Log' TO N'D:\Data\AdventureWorks2014_Log.ldf'
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'QueryStoreDemo')
BEGIN
	ALTER DATABASE [QueryStoreDemo] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE QueryStoreDemo
END
GO

USE [master]
RESTORE DATABASE [QueryStoreDemo] FROM  DISK = N'F:\Backup\QueryStore.bak' WITH  FILE = 1,  MOVE N'QueryStoreDEmo_log' 
TO N'D:\Log\QueryStoreDEmo_log.ldf',  NOUNLOAD,  STATS = 5

GO
*/

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'db_rls_demo_hospital')
BEGIN
	ALTER DATABASE db_rls_demo_hospital SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE db_rls_demo_hospital
END

USE [master]
RESTORE DATABASE [db_rls_demo_hospital] FROM  DISK = N'F:\Backup\db_rls_demo_hospital.bak' WITH  FILE = 1,  MOVE N'db_rls_demo_hospital' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\db_rls_demo_hospital.mdf',  MOVE N'db_rls_demo_hospital_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\db_rls_demo_hospital_log.ldf',  NOUNLOAD,  STATS = 5
GO


IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Customer1')
BEGIN
	ALTER DATABASE Customer1 SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE Customer1
END

USE [master]
RESTORE DATABASE [Customer1] FROM  DISK = N'F:\Backup\Customer1.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5

GO


Drop Database IF exists [WideWorldImporters] 
GO

USE [master]
RESTORE DATABASE [WideWorldImporters] FROM  DISK = N'F:\Backup\WideWorldImporters-Full.bak' WITH  REPLACE, FILE = 1,  MOVE N'WWI_Primary' TO N'F:\Data\WideWorldImporters.mdf',  MOVE N'WWI_UserData' TO N'F:\Data\WideWorldImporters_UserData.ndf',  MOVE N'WWI_Log' TO N'D:\Data\WideWorldImporters.ldf',  NOUNLOAD,  STATS = 5

GO


GO

Drop Database IF exists [WideWorldImportersDW] 
GO
USE [master]
RESTORE DATABASE [WideWorldImportersDW] FROM  DISK = N'F:\Backup\WideWorldImportersDW-Full.bak' WITH  FILE = 1,  MOVE N'WWI_Primary' TO N'F:\Data\WideWorldImportersDW.mdf',  MOVE N'WWI_UserData' TO N'F:\Data\WideWorldImportersDW_UserData.ndf',  MOVE N'WWI_Log' TO N'D:\Data\WideWorldImportersDW.ldf',  NOUNLOAD,  STATS = 5
GO


Use [WideWorldImporters]
GO

EXECUTE DataLoadSimulation.PopulateDataToCurrentDate
        @AverageNumberOfCustomerOrdersPerDay = 5000,
        @SaturdayPercentageOfNormalWorkDay = 80,
        @SundayPercentageOfNormalWorkDay = 25,
        @IsSilentMode = 1,
        @AreDatesPrinted = 1;

GO


/*
Use AdventureworksDW2008_Azure
Go
Select Count(*) from factresellersales_CCI
GO

*/

USe AdventureworksDW_Azure
GO
SELECT
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactResellerSales f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey in (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO


  SELECT
	EnglishProductSubcategoryName AS Type, 
	SUM(OrderQuantity) AS Quantity, 
	SUM(ExtendedAmount) AS Value,
	SUM(CASE WHEN OrderDateKey = 20040708 THEN OrderQuantity ELSE 0 END) AS OrdersToday
FROM FactResellerSales_CCI f
    JOIN DimProduct p ON p.ProductKey = f.ProductKey
    JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
WHERE p.ProductSubcategoryKey in (1, 2, 3)
GROUP BY EnglishProductSubcategoryName
GO

DBCC DROPCLEANBUFFERS
GO


 