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

CREATE COLUMN MASTER KEY [WWI_ColumnMasterKey]
WITH
(
	KEY_STORE_PROVIDER_NAME = N'MSSQL_CERTIFICATE_STORE',
	KEY_PATH = N'LocalMachine/My/2A36A5B76B5AB5CB34C6FBF20DDF455DB69AD4FD'
)
GO

-- =====================================================================================================
-- Step 3) Create CEK
-- =====================================================================================================
CREATE COLUMN ENCRYPTION KEY [WWI_ColumnEncryptionKey]
WITH VALUES
(
	COLUMN_MASTER_KEY = [WWI_ColumnMasterKey],
	ALGORITHM = 'RSA_OAEP',
	ENCRYPTED_VALUE = 0x01700000016C006F00630061006C006D0061006300680069006E0065002F006D0079002F003200610033003600610035006200370036006200350061006200350063006200330034006300360066006200660032003000640064006600340035003500640062003600390061006400340066006400744B98B24B57334A3D5DCCB6A1C92C5C013A950C962CCD67480FE6FD2A16ED89850D4FDC1274E3E3DFAFFF0898402107C00633104951EC762E3FE2D820F6E502FEF3A4A43B7F0FCA1E7A7EF099883064B5538610AEE81FDD63CF65BF368523572FC5A9AE2F0C15349DA8A01F77E96CDC86022D20F8F97CD6DA84DDC2EB22470EA1CC0B0DAA50435053B95ED89D85B9737DBEF8DE145DE8DDAD8AD6BBBBD4E87D9B6C4A8FEDBE69029091AF9FEF46BA3CFF63793E700D4DCF98F5A5DA4DFD0A480179565827C29CE04F44B801A0B2161F8D70ED8B8EA356EA9FA6E78F4D4404E6DB7273B569A148233FC69F1533CB530E298763C3F28D57DD180930B768D939C267971DCD089E1AC467B7C8A3ED86F38ACD52A47D70245A140CD5AA9797F36A00EC923831C834503B51FE01E1E832CD5616405F0128D5622B59C71200D5535BA4430A045A23AFA4E00524380AC59A62E647CE6FDB7731F710CCCE0B15C30E46720F5EF3E3CEFA52D0B80F14C970C4E73ED4AE502510C6B59949B754F151C3AD2852C3FAA24BCFF8DA65B9F50231A25A2C7E3541F764153D6B43C0D999246B847088FBF33200387BA43A627DEE847D97700A4636A5948BCE13A57C50F112283BEAE34DA3659154F845E3388ABFB6FBE7C050286F66FFB6FEACE125FDE4642DF147DAF40FD54DC85DD22A47AFE9729ADFCDF93D235523A4BBF95FF8B337700DE082
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



