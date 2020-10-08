--From: https://msdn.microsoft.com/library/mt631669.aspx#Anchor_1
-- ====================================
-- Step 1) Setup
-- ====================================
Use Master
Go

DROP DATABASE IF Exists TemporalProductInventory
GO

CREATE DATABASE [TemporalProductInventory]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'TemporalProductInventory', FILENAME = N'D:\DATA\TemporalProductInventory.mdf' , SIZE = 512000KB , FILEGROWTH = 1024KB ), 
 FILEGROUP [Memory_Optimized] CONTAINS MEMORY_OPTIMIZED_DATA 
( NAME = N'Mem_Optimized', FILENAME = N'D:\DATA\TemporalProductInventory_mod\' )
 LOG ON 
( NAME = N'TemporalProductInventory_log', FILENAME = N'D:\DATA\TemporalProductInventory_log.ldf' , SIZE = 51200KB , FILEGROWTH = 10%)
GO

USE TemporalProductInventory
GO

BEGIN
    --If table is system-versioned, SYSTEM_VERSIONING must be set to OFF first 
    IF ((SELECT temporal_type FROM SYS.TABLES WHERE object_id = OBJECT_ID('dbo.ProductInventory', 'U')) = 2)
    BEGIN
        ALTER TABLE [dbo].[ProductInventory] SET (SYSTEM_VERSIONING = OFF)
    END
    DROP TABLE IF EXISTS [dbo].[ProductInventory]
	   DROP TABLE IF EXISTS [dbo].[ProductInventoryHistory]
END
GO

CREATE TABLE [dbo].[ProductInventory]
(
    ProductId int NOT NULL,
    LocationID INT NOT NULL,
    Quantity int NOT NULL CHECK (Quantity >=0),

    SysStartTime datetime2(0) GENERATED ALWAYS AS ROW START  NOT NULL ,
    SysEndTime datetime2(0) GENERATED ALWAYS AS ROW END  NOT NULL ,
    PERIOD FOR SYSTEM_TIME(SysStartTime,SysEndTime),

    --Primary key definition
    CONSTRAINT PK_ProductInventory PRIMARY KEY NONCLUSTERED (ProductId, LocationId)
)
WITH
(
    MEMORY_OPTIMIZED=ON, 	
    SYSTEM_VERSIONING = ON 
    (        
        HISTORY_TABLE = [dbo].[ProductInventoryHistory],        
        DATA_CONSISTENCY_CHECK = ON
    )
)
GO

CREATE CLUSTERED COLUMNSTORE INDEX IX_ProductInventoryHistory ON [ProductInventoryHistory]
WITH (DROP_EXISTING = ON);
GO

CREATE PROCEDURE [dbo].[spQueryInventoryLatestState]
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')
  	SELECT ProductId, LocationID, Quantity, SysStartTime
	  FROM dbo.ProductInventory
  	ORDER BY ProductId, LocationId
END;
GO
EXEC [dbo].[spQueryInventoryLatestState];

