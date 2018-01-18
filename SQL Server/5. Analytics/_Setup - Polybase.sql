----------------------------------------------------------------
-- AdventureWorksDW2016CTP3 samples: PolyBase
----------------------------------------------------------------

-- This sample will show you how to query and load data from Azure blob storage
-- to AdventureWorks2016CTP3 database using PolyBase.

USE AdventureWorksDW2016CTP3
go


------------------------------- Configuration ------------------------------------------------------------------


-- Specify the type of data source you want to query. 
-- Choose Option 7 for Azure blob storage.
exec sp_configure 'hadoop connectivity', 7;
Reconfigure;

-- Restart SQL Server to set the changes. This will automatically restart
-- "SQL Server PolyBase Engine" and "SQL Server PolyBase Data Movement Service". 

-- Verify hadoop connectivity run_value is set to 7.
exec sp_configure 'hadoop connectivity';


-- STEP 1: Create a database master key to encrypt database scoped credential secret in the next step.
-- Replace <password> with a password to encrypt the master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd';


-- STEP 2: Create a database scoped credential to authenticate against your Azure storage account.
-- Replace the <storage_account_key> with your Azure storage account key (primary access key). 
-- To find the key, open to your storage account on Azure Portal (https://portal.azure.com/).
CREATE DATABASE SCOPED CREDENTIAL AzureStorageCredential 
WITH IDENTITY = 'PankajTSP', 
SECRET = 'urNQyRRp2KLY/IQupxRvGhkOmKzCNx402WomFtNq3iHZUYSQlC8UcCFb20rTNs1HdH/5pKvWcXteFynK/GAK5Q==';


-- STEP 3: Create an external data source to specify location and credential for your Azure storage account.
-- Replace the <container_name> with your Azure storage blob container.
-- Replace the <storage_account_name> with your Azure storage account name.

CREATE EXTERNAL DATA SOURCE AzureStorage 
WITH (	
		TYPE = Hadoop, 
		LOCATION = 'wasbs://polybase@pankajtsp.blob.core.windows.net',
		CREDENTIAL = AzureStorageCredential
); 




-- Step 4: Create an external file format to specify the layout of data stored in Azure blob storage. 
-- The data is in a comma-separated text file.
CREATE EXTERNAL FILE FORMAT TextFile 
WITH (
		FORMAT_TYPE = DelimitedText, 
		FORMAT_OPTIONS (FIELD_TERMINATOR = '|')
);

-- Step 5: Create an external table to reference data stored in your Azure blob storage account.
-- Specify column properties for the table.
-- Replace LOCATION: <file_path> with the relative path of your file from the blob container.
-- If the file is directly under your blob container, the location would simply be 'FactResellerSalesArchive.txt'.
CREATE EXTERNAL TABLE dbo.FactResellerSalesArchiveExternal (
	[ProductKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[DueDateKey] [int] NOT NULL,
	[ShipDateKey] [int] NOT NULL,
	[ResellerKey] [int] NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[SalesTerritoryKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[RevisionNumber] [tinyint] NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[ExtendedAmount] [money] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [money] NULL,
	[TotalProductCost] [money] NULL,
	[SalesAmount] [money] NULL,
	[TaxAmt] [money] NULL,
	[Freight] [money] NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[CustomerPONumber] [nvarchar](25) NULL,
	[OrderDate] [datetime] NULL,
	[DueDate] [datetime] NULL,
	[ShipDate] [datetime] NULL
)
WITH (
		LOCATION='FactResellerSalesArchive.txt', 
		DATA_SOURCE=AzureStorage, 
		FILE_FORMAT=TextFile
);

