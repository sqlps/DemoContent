-- ====================================================
-- Overview: Purpose of this demo is to showcase
-- the ability to have a limited group of DBAs with
-- permissions to maintain an environment, but prevent
-- access to sensitive data
-- ====================================================

-- ====================================================
-- Step 1) Setup
-- ====================================================

-- Create the DB
CREATE DATABASE [SensitiveDatabase]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Test', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Sensitive.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Test_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Sensitive_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

-- Create a new server role and we will limit the access 
CREATE SERVER ROLE LimitedSA AUTHORIZATION sysadmin
GO

USE [master]
GO
CREATE LOGIN [SQLADMIN11\JuniorDBA] FROM WINDOWS WITH DEFAULT_DATABASE=[SensitiveDatabase]
GO

-- Add Offshore team into the newly created server role
ALTER SERVER ROLE LimitedSA ADD MEMBER [sqladmin11\JuniorDBA]

-- Create a sensitive table
USE [SensitiveDatabase]
GO

CREATE TABLE SensitiveTable
  (MemberID int IDENTITY PRIMARY KEY,
   FirstName varchar(100) MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)') NULL,
   LastName varchar(100) NOT NULL,
   Phone# varchar(12) MASKED WITH (FUNCTION = 'default()') NULL,
   Email varchar(100) MASKED WITH (FUNCTION = 'email()') NULL);
GO

INSERT SensitiveTable (FirstName, LastName, Phone#, Email) VALUES 
('Roberto', 'Tamburello', '555.123.4567', 'RTamburello@contoso.com'),
('Janice', 'Galvin', '555.123.4568', 'JGalvin@contoso.com.co'),
('Zheng', 'Mu', '555.123.4569', 'ZMu@contoso.net');
GO

-- Add login as a user in the DB
USE [SensitiveDatabase]
GO
CREATE USER [JuniorDBA] FOR LOGIN [SQLADMIN11\JuniorDBA] WITH DEFAULT_SCHEMA=[dbo]
GO

-- Add CONTROL SERVER permission to the new server role to manage the dB instance
USE master
GO
GRANT CONTROL SERVER to LimitedSA
GO

-- Start locking down
DENY IMPERSONATE ANY LOGIN TO LimitedSA
GO

Use SensitiveDatabase
Go

REVOKE UNMASK to [SQLADMIn11\JuniorDBA]
GO
DENY UNMASK to [SQLADMIn11\JuniorDBA]
GO

-- ===========================================================
-- Step 2) Enable Dynamic Data Masking on Sensitive Table
-- ===========================================================
Use SensitiveDatabase
Go

-- Enable Masking rule
ALTER TABLE SensitiveTable
ALTER COLUMN LastName ADD MASKED WITH (FUNCTION = 'partial(2,"XXX",0)');

ALTER TABLE SensitiveTable
ALTER COLUMN LastName varchar(100) MASKED WITH (FUNCTION = 'default()');


-- ===========================================================
-- Step 3) Test out connected to SSMS as JuniorDBA
-- ===========================================================

-- Try Reading
Use SensitiveDatabase
GO
Select * from SensitiveTable
GO

-- Backup and Restore to another instance where JuniorDBA is SA
BACKUP DATABASE [SensitiveDatabase] TO  DISK = N'\\sqladmin11cdc\Backups\SensitiveDatabase.bak' WITH NOFORMAT, INIT,  
NAME = N'SensitiveDatabase-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- Restore to same server and read as regular admin
USE [master]
RESTORE DATABASE [SensitiveDatabase_Masked] FROM  DISK = N'\\sqladmin11cdc\Backups\SensitiveDatabase.bak' WITH  REPLACE, FILE = 1,  
MOVE N'Test' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Sensitive_masked.mdf', 
MOVE N'Test_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Sensitive_masked_log.ldf',  NOUNLOAD,  STATS = 5
GO

Use SensitiveDatabase_Masked
GO
Select * from SensitiveTable
GO

-- ===========================================================

-- 5. Clean up
-- ===========================================================
USE master
GO
ALTER SERVER ROLE LimitedSA DROP MEMBER [SQLADmin11\JuniorDBA]
GO
DROP SERVER ROLE LimitedSA
GO
--Select * from sys.dm_exec_sessions where login_name = 'SQLADMIN11\JuniorDBA'
-- Kill 57
ALTER DATABASE SensitiveDatabase SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE SensitiveDatabase
GO
ALTER DATABASE SensitiveDatabase_Masked SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE SensitiveDatabase_Masked 
GO
DROP LOGIN [SQLADmin11\JuniorDBA]
GO
