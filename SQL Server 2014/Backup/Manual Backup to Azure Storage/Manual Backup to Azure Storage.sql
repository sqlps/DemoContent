-- Simple Test of Manual Backup to Azure Storage

-- 0. Pre-demo
-- Create a container called backup
-- Download AdventureWorks database from sample database site http://msftdbprodsamples.codeplex.com/releases/view/55330 

-- 1. Create Credential and Certificate
USE [master];
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MySuperPassword-2013'
GO

CREATE CERTIFICATE BackupEncryptCert
   WITH SUBJECT = 'My Backup Encryption';
GO

CREATE CREDENTIAL mycredential 
WITH IDENTITY= '<insert your Azure storage name here>'
, SECRET = '<insert your Azure storage secret key here>'
GO

-- 2. Backup AdventureWorks database
BACKUP DATABASE[AdventureWorks] 
TO URL = 'http://<your Azure storage URL>/backup/AdventureWorksTest1.bak' 
WITH CREDENTIAL = 'mycredential';
GO 

-- 3. Drop AdventureWorks database first
DROP DATABASE AdventureWorks
GO

-- 4. Restore AdventureWorks database
RESTORE DATABASE AdventureWorks 
FROM URL = 'http://<your Azure storage URL>/backup/AdventureWorksTest1.bak' 
WITH CREDENTIAL = 'mycredential'
, STATS = 5
GO

-- 5. Test simple query
USE AdventureWorks
GO
SELECT TOP 5 * FROM HumanResources.Department
GO

-- 6. Cleanup 
USE master
GO
DROP CERTIFICATE BackupEncryptCert;
GO
DROP CREDENTIAL mycredential
GO
DROP MASTER KEY
GO