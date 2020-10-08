
-- Create a simple dB
CREATE DATABASE [MySecureDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'MySecureDB', FILENAME = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\MySecureDB.mdf' , SIZE = 4MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'MySecureDB_log', FILENAME = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\MySecureDB_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

-- Create a simple table and insert some value
USE MySecureDB
CREATE TABLE client_data(name NVARCHAR(30), SSN CHAR(20))
GO
INSERT INTO client_data VALUES('Fred', '123-01-1234');
INSERT INTO client_data VALUES('George', '123-01-1235');
INSERT INTO client_data VALUES('Bill', '123-01-1236');

SELECT * from client_data
GO

-- Normal backup without encryption nor compression
BACKUP DATABASE [MySecureDB]
TO DISK = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\mytestdb_nocompress_noencrypt.bak'
WITH
  NOFORMAT,
  NOINIT,
  NAME = N'mytestdb - uncompressed, unencrypted',
  SKIP,
  NOREWIND,
  NOUNLOAD,
  NO_COMPRESSION,
  STATS = 10
GO

-- Normal backup with compression
BACKUP DATABASE [MySecureDB]
TO DISK = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\mytestdb_compress_noencrypt.bak'
WITH
  NOFORMAT,
  NOINIT,
  NAME = N'mytestdb - compressed, unencrypted',
  SKIP,
  NOREWIND,
  NOUNLOAD,
  COMPRESSION,
  STATS = 10
GO

-- We need to setup master key and certificate for backup encryption
USE [master];
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MySuperPassword-2013'
GO

CREATE CERTIFICATE BackupEncryptCert
   WITH SUBJECT = 'My Backup Encryption';
GO

-- We should always backup our certificate on-prem for later use
Use [master]
BACKUP CERTIFICATE BackupEncryptCert TO FILE = 'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\BackupEncryptCert.cert'
    WITH PRIVATE KEY ( FILE = 'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\BackupEncryptCert.privatekey' , 
    ENCRYPTION BY PASSWORD = 'MyCertPassword-2013' );
GO

-- Now we can do backup encryption
BACKUP DATABASE [MySecureDB]
TO DISK = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\mytestdb_nocompress_encrypt.bak'
WITH
  NOFORMAT,
  NOINIT,
  NAME = N'mytestdb - uncompressed, encrypted',
  SKIP,
  NOREWIND,
  NOUNLOAD,
  NO_COMPRESSION,
  ENCRYPTION (
   ALGORITHM = AES_256,
   SERVER CERTIFICATE = BackupEncryptCert
   ),
  STATS = 10
GO

-- Compression also works with Backup encryption
BACKUP DATABASE [MySecureDB]
TO DISK = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\mytestdb_compress_encrypt.bak'
WITH
  NOFORMAT,
  NOINIT,
  NAME = N'mytestdb - compressed, encrypted',
  SKIP,
  NOREWIND,
  NOUNLOAD,
  COMPRESSION,
  ENCRYPTION (
   ALGORITHM = AES_256,
   SERVER CERTIFICATE = BackupEncryptCert
   ),
  STATS = 10
GO

-- In fact, we can backup to Azure Storage using encryption and compression
-- But first we need to create credential from our Azure Storage
CREATE CREDENTIAL mycredential 
WITH IDENTITY= '<insert your Azure storage name here>'
, SECRET = '<insert your Azure storage secret key here>'
GO

-- Now backup to Azure Storage (encrypted and compressed) but secure because certificate is stored on-prem
BACKUP DATABASE[MySecureDB] 
TO URL = 'http://<your Azure storage URL>/backup/mytestdb_compress_encrypt.bak' 
WITH CREDENTIAL = 'mycredential',
  NOFORMAT,
  NOINIT,
  NAME = N'mytestdb - compressed, encrypted',
  SKIP,
  NOREWIND,
  NOUNLOAD,
  COMPRESSION,
  ENCRYPTION (
   ALGORITHM = AES_256,
   SERVER CERTIFICATE = BackupEncryptCert
   ),
  STATS = 10;
GO 

-- TESTING: Let's now drop the certificate
USE [master]
GO
DROP CERTIFICATE BackupEncryptCert;
GO

-- Drop the database
USE [master]
GO
DROP DATABASE [MySecureDB]
GO

-- This should fail because we did not have certificate
USE [master]
RESTORE DATABASE [MySecureDB]
FROM DISK = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\mytestdb_compress_encrypt.bak'
WITH FILE = 1,
NOUNLOAD,
STATS = 10
GO

-- This should work because we restore from non-encrypted backup
USE [master]
RESTORE DATABASE [MySecureDB]
FROM DISK = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\mytestdb_compress_noencrypt.bak'
WITH FILE = 1,
NOUNLOAD,
REPLACE,
STATS = 10
GO

-- Let's drop the database again
USE [master]
GO
DROP DATABASE [MySecureDB]
GO

-- This time we restore our certificate first before restore the database
Use [master]
CREATE CERTIFICATE BackupEncryptCert
    FROM FILE = 'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\BackupEncryptCert.cert'
    WITH PRIVATE KEY ( FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\BackupEncryptCert.privatekey' , 
    DECRYPTION BY PASSWORD = 'MyCertPassword-2013' );
GO

-- Restore database should work now
USE [master]
RESTORE DATABASE [MySecureDB]
FROM DISK = N'D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\Backup\mytestdb_compress_encrypt.bak'
WITH FILE = 1,
NOUNLOAD,
REPLACE,
STATS = 10
GO

-- Let's drop the database again
USE [master]
GO
DROP DATABASE [MySecureDB]
GO

-- This time we restore from Azure Storage
RESTORE DATABASE [MySecureDB] 
FROM URL = 'http://<your Azure storage URL>/backup/mytestdb_compress_encrypt.bak' 
WITH CREDENTIAL = 'mycredential'
, STATS = 5
GO

-- Test the result
USE MySecureDB
GO
SELECT * from client_data
GO

-- Clean up
USE [master]
GO
DROP DATABASE [MySecureDB]
GO

DROP CERTIFICATE BackupEncryptCert;
GO

DROP CREDENTIAL mycredential
GO

DROP MASTER KEY
GO

-- Also drop all the files in the backup folders (on-prem and Azure Storage)

SELECT backup_set_id, name, backup_size, compressed_backup_size, key_algorithm, encryptor_thumbprint, encryptor_type FROM msdb.dbo.backupset

SELECT media_set_id, is_password_protected, is_compressed, is_encrypted FROM msdb.dbo.backupmediaset