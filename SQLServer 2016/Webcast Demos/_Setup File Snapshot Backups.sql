-- ============================================================================================================
-- Step 1)  Create a master key and Server certificate
-- ============================================================================================================
-- From Azure Storage Explorer
-- 1) Make sure you connect to your Azure Storage account with HTTPS
-- 2) Connect to storage explorer and select the container 
-- 3) Hit the Security button
-- 4) Go to the Shared Access Signatures
-- 5) Set and expiration date
-- 6) Select List, Delete, Read, Write
-- 7) Click Generate Signature and copy
-- 8) Go to Access Level tab and hit "Update Access Level"
-- 9) Parse Signature and use to create Credential

USE master
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SqlDem0Key';
GO
CREATE CERTIFICATE SqlDemoCert WITH SUBJECT = 'SqlDemo DEK Certification'
GO

-- Now backup the certificate
BACKUP CERTIFICATE SqlDemoCert
TO FILE = 'C:\Demos\SQLServer 2016\5. Admin and Hybrid Cloud\SqlDemoCert.CER'
WITH PRIVATE KEY
(
     FILE = 'C:\Demos\SQLServer 2016\5. Admin and Hybrid Cloud\SQLPrivateKeyFile.PVK',
     ENCRYPTION BY PASSWORD = 'SqlDem0Key'
);
GO

-- Sample Signature: 
https://pankajtsp.blob.core.windows.net/data?sv=2014-02-14&sr=c&sig=XQgyyaHbvb4qq%2FB9b9DVy1bvSAPj6jPgdLfK7VeILRI%3D&st=2016-01-26T00%3A00%3A00Z&se=2020-02-03T00%3A00%3A00Z&sp=rwdl

USE master
GO

CREATE CREDENTIAL [https://pankajtsp.blob.core.windows.net/data] 
WITH IDENTITY= 'SHARED ACCESS SIGNATURE'
, SECRET = 'sv=2014-02-14&sr=c&sig=XQgyyaHbvb4qq%2FB9b9DVy1bvSAPj6jPgdLfK7VeILRI%3D&st=2016-01-26T00%3A00%3A00Z&se=2020-02-03T00%3A00%3A00Z&sp=rwdl' --This is everything after ?
GO

-- Show created credential-
SELECT * from sys.credentials

-- Now create a database which uses this container
CREATE DATABASE AdventureworksDW_Azure
ON
( NAME = AdventureworksDW2008_Data,
    FILENAME = 'https://pankajtsp.blob.core.windows.net/data/AdventureWorksDW2008_Azure.mdf' )
LOG ON
( NAME = AdventureworksDW2008_log,
    FILENAME = 'https://pankajtsp.blob.core.windows.net/data/AdventureWorksDW2008_Azure.ldf')
	
GO

--  to show the data files are in cloud storage
SELECT * FROM sys.master_files WHERE credential_id IS NOT NULL
GO
-- Now refresh Databases
-- Now refresh storage explorer


-- Now encrypt the database
USE foo
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE SqlDemoCert
GO

ALTER DATABASE foo
SET ENCRYPTION ON
GO
SELECT * FROM sys.dm_database_encryption_keys WHERE encryptor_type = 'CERTIFICATE'

-- Insert some data
USE foo
CREATE TABLE client_data(name NVARCHAR(30), SSN CHAR(20))
GO
INSERT INTO client_data VALUES('Fred', '123-01-1234');
INSERT INTO client_data VALUES('George', '123-01-1235');
INSERT INTO client_data VALUES('Bill', '123-01-1236');

SELECT * from client_data
GO

-- Detach the database to move it to another machine
USE master
EXEC sp_detach_db 'foo', 'true';



-- cleanup 
-- or drop the database if you're done with the data files too
use master
DROP database foo
GO
DROP CREDENTIAL  [https://<Your Azure storage with folder location>] 
GO
DROP CERTIFICATE SqlDemoCert
GO
DROP MASTER KEY
GO

Machine 2:
-- initial setup
-- Create a master key and Server certificate
USE master
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SqlDem0Key';
GO

CREATE CERTIFICATE SqlDemoCert
FROM FILE = 'C:\data\SqlDemoCert.CER'
WITH PRIVATE KEY
(
     FILE = 'C:\data\SQLPrivateKeyFile.PVK',
     DECRYPTION BY PASSWORD = 'SqlDem0Key'
);
GO

-- To use XStore integration first create a SQL Server Credential to store my storage container Shared Access Certificate
CREATE CREDENTIAL [https://<Your Azure storage with folder location>] 
WITH IDENTITY= 'SHARED ACCESS SIGNATURE'
, SECRET = '<insert your Azure storage Shared Access Signature (SAS) key here>'
GO

-- demo part
-- 1. Refresh storage explorer in SSMS

-- 2. Attach the database which uses this container
USE master
Go
CREATE DATABASE foo
ON
( NAME = foo_dat,
    FILENAME = 'https://<Your Azure storage with folder location>/foo.mdf' )
LOG ON
( NAME = foo_log,
    FILENAME = 'https://<Your Azure storage with folder location>/foolog.ldf')
FOR ATTACH
GO

-- 3. refresh databases in SSMS
-- show data
USE foo
SELECT * from client_data