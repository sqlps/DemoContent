--<INTERNAL>Full instructions found @ https://microsoft.sharepoint.com/teams/bidpwiki/Pages1/Enabling%20Transparent%20Data%20Encryption%20using%20Extensible%20Key%20Management%20(EKM).aspx 

--1) Need to enable EKM Provider
sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE ;
GO

sp_configure 'EKM provider enabled', 1 ;
GO
RECONFIGURE ;
GO

--2) Install the CryptoProvider on the SQL Server

--3) Create the CryptoProvider
CREATE CRYPTOGRAPHIC PROVIDER EKM_Prov 
FROM FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Binn\USBCryptoProvider.dll'

--4) If the EKM module uses basic authentication, create a credential and add the credential to a user. 
-- A credential is a record that contains the authentication information (credentials) required to connect to a resource outside SQL Server. 
-- In our case, the EKM module uses Basic Authentication (UserName and Password).

CREATE CREDENTIAL sa_ekm_tde_cred 
WITH IDENTITY = 'user1', -- This is the same username specified in the USBProvider.xml file.
SECRET = '~yukon90' -- This is the same username specified in the USBProvider.xml file.
FOR CRYPTOGRAPHIC PROVIDER EKM_Prov ;
GO

ALTER LOGIN [northamerica\pansaty] -- The account [DomainName\userName] should be a high privileged user such as sysadmin.
ADD CREDENTIAL sa_ekm_tde_cred ;
GO

--Create an asymmetric key protected by the EKM provider.
USE master ;
GO

CREATE ASYMMETRIC KEY ekm_login_key1 
FROM PROVIDER [EKM_Prov]
WITH ALGORITHM = RSA_1024,
PROVIDER_KEY_NAME = 'SQL_Server_Key' ;
GO

--6)The following procedure creates a credential with to be authenticated by the EKM, and adds that to a login that is based on an asymmetric key. 
--  Users cannot login using that login, but the Database Engine will be able to authenticate itself with the EKM device.

CREATE CREDENTIAL ekm_tde_cred 
WITH IDENTITY = 'user1', -- This can be any username specified in the USBProvider.xml file.
SECRET = '~yukon90' -- This is the password for the username specified in previous step from the USBProvider.xml file.
FOR CRYPTOGRAPHIC PROVIDER EKM_Prov ;
GO

-- Execute the following statement to add a login used by TDE, and add the new credential to the login:

CREATE LOGIN EKM_Login 
FROM ASYMMETRIC KEY ekm_login_key1 ;
GO

ALTER LOGIN EKM_Login 
ADD CREDENTIAL ekm_tde_cred ;

-- 7) Create a symmetric database encryption key in the user database (TDE_EKM_TEST as show in the example below.

Use Adventureworks
go 

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER ASYMMETRIC KEY ekm_login_key1 ;
GO

-- If you're trying to switch from DEK protected by Cert to EKM use below
/*
Use Adventureworks
go 

ALTER DATABASE ENCRYPTION KEY
ENCRYPTION BY SERVER ASYMMETRIC KEY ekm_login_key1 ;
GO


*/

--8) Enable TDE.

ALTER DATABASE Adventureworks 
SET ENCRYPTION ON ;
GO

-- 9) Check the DMVs

-- Checking Status of Encryption Scan
Select * from sys.dm_database_encryption_keys
 
  ------------------
 /* START CLEANUP */
 ------------------
ALTER DATABASE Adventureworks 
SET ENCRYPTION OFF 
GO

ALTER LOGIN EKM_Login 
DROP CREDENTIAL ekm_tde_cred ;
GO

DROP CREDENTIAL ekm_tde_cred
GO
DROP LOGIN EKM_Login 

Use AdventureWorks
DROP DATABASE ENCRYPTION KEY
GO

ALTER LOGIN [northamerica\pansaty]
DROP CREDENTIAL sa_ekm_tde_cred ;

DROP CREDENTIAL sa_ekm_tde_cred ;

DROP CRYPTOGRAPHIC PROVIDER EKM_Prov 

use master
DROP ASYMMETRIC KEY ekm_login_key1 
GO

sp_configure 'EKM provider enabled', 0 ;
GO
RECONFIGURE ;
GO

  ----------------
 /* END CLEANUP */
 ----------------
