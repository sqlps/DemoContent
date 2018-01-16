-- =====================================================================================================
-- Step 1) Cleanup
-- =====================================================================================================

USE WideWorldImporters;
GO

-- WWI have decided to store some national ID and credit card details for suppliers
-- but these details need to always be encrypted

-- Remove any existing column keys and/or table
DROP TABLE IF EXISTS Purchasing.Supplier_PrivateDetails;
IF EXISTS (SELECT 1 FROM sys.column_encryption_keys WHERE name = N'WWI_ColumnEncryptionKey')
BEGIN
	DROP COLUMN ENCRYPTION KEY WWI_ColumnEncryptionKey;
END;
IF EXISTS (SELECT 1 FROM sys.column_master_keys WHERE name = N'WWI_ColumnMasterKey')
BEGIN
	DROP COLUMN MASTER KEY WWI_ColumnMasterKey;
END;
GO


-- =====================================================================================================
-- Step 2) Create CMK
-- =====================================================================================================

USE [WideWorldImporters]
/****** Object:  ColumnMasterKey [WWI_ColumnMasterKe]    Script Date: 6/17/2016 6:47:59 PM ******/
CREATE COLUMN MASTER KEY [WWI_ColumnMasterKey]
WITH
(
	KEY_STORE_PROVIDER_NAME = N'MSSQL_CERTIFICATE_STORE',
	KEY_PATH = N'CurrentUser/My/A592C23FEFED8528F5A4E42B9A7CE9D8ECE54853'
)
GO



-- =====================================================================================================
-- Step 3) Create CEK
-- =====================================================================================================
USE [WideWorldImporters]
/****** Object:  ColumnEncryptionKey [WWI_ColumnEncryptionKey]    Script Date: 6/17/2016 6:48:20 PM ******/
CREATE COLUMN ENCRYPTION KEY [WWI_ColumnEncryptionKey]
WITH VALUES
(
	COLUMN_MASTER_KEY = [WWI_ColumnMasterKey],
	ALGORITHM = 'RSA_OAEP',
	ENCRYPTED_VALUE = 0x016E000001630075007200720065006E00740075007300650072002F006D0079002F00610035003900320063003200330066006500660065006400380035003200380066003500610034006500340032006200390061003700630065003900640038006500630065003500340038003500330035A8E0C5E083DD72585C56EC9B91F84CEED15F4691A1823CC1F977C9916A6845C9EEE7CC333A0039EAE5343EC7FC7CDA9A8744D4805BA321EE0FCB14A2705EF8F8C5B19C7044BFDFF58B375926C6D415A59F9B6F7DDC2F0646D696F44EC9638511693211419A18D55AF182E092DEA81945F057B7371E4AE39768FFBF32E1555F66368F4F15CF95EE5C5B86D6B8EC8E583C44ADB82A45241A27B76F96277F670727AAD70B4897880FF2984305FA806E06BB35C2190127AC0C5F5DA6B3D61A0BA32DBECAE5455DAC26C2D484072FE02A4BDCE5AA47F73E769D12B9441B5019EAD62680FD7461D04C434A1B7572954E088F506DEAFD5AD36186C1F05EC61B6E18355D5E3827A3DB04911D7A4A87D40D0CFE48808837D903B8C8543EAF47A845825820BE496FFA33E1597A6B795FF66734548997A2C6FD10F476AF487D810FA04DFC0C104EDF8A9095DF6B3F56DABC98DA41C5290AC3E466C3D0419433196194D08239A44B8C953DBE6E865B738442450DBA2EFC51067D2605D10A706F3875B906FDE9FDD30FE2BB808724A52D971E66D25D80D2EF3EDFC63BC82E423726C4CD4C5392878B97676FA4274E00623E8E49C2DDC6B364DB587C6B6C6CDF07CE6BF41C94260B7F37323A6B3EFEC374BF01C15C23FB5AD7BF158A50B0ACDBB230297CDCA4EB8D05DD44C463E5B86FB20A2F95909E8C5CEBC7A5999B201A78F75BA11FC064
)
GO

-- =====================================================================================================
-- Step 3) Create XE to track parameters being passed
-- =====================================================================================================

CREATE EVENT SESSION [AlwaysEncrypted] ON SERVER 
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name)
    WHERE ([sqlserver].[client_app_name]=N'.Net SqlClient Data Provider')),
ADD EVENT sqlserver.rpc_starting(
    ACTION(sqlserver.client_app_name)
    WHERE ([sqlserver].[client_app_name]=N'.Net SqlClient Data Provider')),
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.client_app_name)
    WHERE ([sqlserver].[client_app_name]=N'.Net SqlClient Data Provider')),
ADD EVENT sqlserver.sp_statement_starting(
    ACTION(sqlserver.client_app_name)
    WHERE ([sqlserver].[client_app_name]=N'.Net SqlClient Data Provider')),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[client_app_name],N'.Net SqlClient Data Provider'))),
ADD EVENT sqlserver.sql_batch_starting(
    ACTION(sqlserver.client_app_name)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[client_app_name],N'.Net SqlClient Data Provider'))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_app_name)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[client_app_name],N'.Net SqlClient Data Provider'))),
ADD EVENT sqlserver.sql_statement_starting(
    ACTION(sqlserver.client_app_name)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[client_app_name],N'.Net SqlClient Data Provider')))
ADD TARGET package0.event_file(SET filename=N'AlwaysEncrypted')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=1 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO



