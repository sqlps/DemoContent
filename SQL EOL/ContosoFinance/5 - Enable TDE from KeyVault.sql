--====================================================================================================================================================================
-- TRANSPARENT DATA ENCRYPTION [TDE]
--====================================================================================================================================================================

-- ================================================
-- Step 1) Create the Master Key to encrypt the DEK
-- ================================================
use master; 
go
select * from sys.symmetric_keys
go
-- Create the master key that will be used to encrypt the certificate. The password used does not have to be the same on servers that you are going to restore to.
use master; 
go
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssword'
--ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'P@ssw0rd'
--BACKUP MASTER KEY TO FILE = 'path_to_file' ENCRYPTION BY PASSWORD = 'password'
go

use master; 
go
CREATE CERTIFICATE MyServerCert WITH SUBJECT = 'My DEK Certificate'; 
go

-- Since no specific encryption password has been used, the Database Master Key (DMK) is used as encryption password. 
--The ?pvt_key_encryption_type_desc column of the sys.certificates catalog view will have a value of ENCRYPTED_BY_MASTER_KEY

Select * from sys.certificates
select @@version
--Create the DEK
use ContosoFinance_TDE; 
go
CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_128 ENCRYPTION BY SERVER CERTIFICATE MyServerCert 
go

-- ================================================
-- Step 2) ALWAYS BACKUP YOUR CERTS
-- ================================================

--Backup the Certificate
Use master
GO
BACKUP CERTIFICATE MyServerCert TO FILE = 'C:\Data\Certs\MyServerCert.cer' 
WITH PRIVATE KEY ( FILE = 'C:\Data\Certs\MyServerCert.pvk' , 
ENCRYPTION BY PASSWORD = 'P@ssword123' );

--Note: if you don't backup the private key, you will get:
/*Msg 15507, Level 16, State 1, Line 1
A key required by this operation appears to be corrupted.
Msg 3013, Level 16, State 1, Line 1
--Same applies if you try to restore w.o the key
*/

-- ================================================
-- Step 3) Insert Sample Data
-- ================================================

Use ContosoFinance_TDE_NoTDE
Go
Create Table SampleData (FirstName varchar(50), LastName Varchar(50))
GO
Insert SampleData 
Values ('Pankaj', 'Satyaketu')
GO

-- ================================================
-- Step 4) Use HEX Editor to read the data file
-- ================================================
-- 1 Stop SQL
-- 2 open the MDF C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\ 
-- Restart SQL

-- ================================================
-- Step 5) Enable Encryption
-- ================================================

--Enable TDE
ALTER DATABASE ContosoFinance_TDE
SET ENCRYPTION ON 
GO

-- Checking Status of Encryption Scan
Select percent_complete, * from sys.dm_database_encryption_keys

--
-- Try opening file again in HxD

-- ================================================
-- Step 6) Try to restore somewhere else (OPTIONAL)
-- ================================================

--Try to restore the database backup on another SQL Server instance. It will fail. 
-- Now restore the certificate that you had backed up in the previous steps on the second instance where you are trying to restore the backup and then try restore again

USE Master;
GO
CREATE CERTIFICATE MyServerCert --Name can be anything
    FROM FILE = 'C:\Temp\MyServerCert.cer' 
    WITH PRIVATE KEY (FILE = 'C:\Temp\MyServerCert.pvk', 
    DECRYPTION BY PASSWORD = 'P@ssword123');
	-- The password provided in this step has to match the password provided when backing up the certificate.
GO 

-- To change the cert used to protect the DEK
ALTER DATABASE ENCRYPTION KEY ENCRYPTION BY SERVER CERTIFICATE [<NewCertificateName in Master DB>]

--To regen the DEK which does a full re-encrption of the DB
ALTER DATABASE ENCRYPTION KEY REGENERATE WITH ALGORITHM = AES_128

-- ================================================
-- Step 7) Cleanup
-- ================================================

--Disable TDE
ALTER DATABASE AdventureWorks2016 
SET ENCRYPTION OFF
go
Use Adventureworks2016
go
DROP DATABASE ENCRYPTION KEY
go
Drop Table SampleData
go
Use Master
go
DROP CERTIFICATE MyServerCert
go
DROP MASTER KEY 
GO