-- Demo Database administrators who cannot see user data

-- ===================================
-- Step 1) Create DB
-- ===================================

If Exists( Select Name from sys.databases where name = 'SensitiveDatabase')
	Drop Database [SensitiveDatabase]
GO

CREATE DATABASE [SensitiveDatabase]
GO

USE [SensitiveDatabase]
GO

CREATE TABLE [dbo].[SensitiveTable](
	[FullName] [nvarchar](50) NULL,
	[SocialSecurity] [nvarchar](50) NULL,
	[Salary] [money] NULL
) ON [PRIMARY]
GO

INSERT INTO [dbo].[SensitiveTable]
           ([FullName]
           ,[SocialSecurity]
           ,[Salary])
     VALUES
           ('Bob Jones'
           ,'123-45-6789'
           ,1000000)
GO

INSERT INTO [dbo].[SensitiveTable]
           ([FullName]
           ,[SocialSecurity]
           ,[Salary])
     VALUES
           ('Mary White'
           ,'321-54-9876'
           ,1500000)
GO

SELECT * FROM SensitiveTable
GO

-- ==========================================================================
-- Step 2) Create Server Role for for DBA who can manage DB, but not see data
-- ==========================================================================

-- Create a login, new server role, allow CONTROL SERVER permission but
-- deny SELECT ALL USER SECURABLES permission
USE master
GO

CREATE LOGIN Mary WITH PASSWORD = 'pass@word1'

-- Create a new server role and we will limit the access 
CREATE SERVER ROLE MyLimitedAdmin AUTHORIZATION sysadmin
  
-- Add login Mary into the newly created server role
ALTER SERVER ROLE MyLimitedAdmin ADD MEMBER Mary

-- Add CONTROL SERVER permission to the new server role to manage the dB instance
USE master
GO
GRANT CONTROL SERVER to MyLimitedAdmin 

-- However, we deny the new server role to see any user data but can do other DBA tasks 
-- such as backup the databases, etc.
DENY SELECT ALL USER SECURABLES to MyLimitedAdmin --New in SQL Server 2014

-- ==========================================================================
-- Step 3) Create Server Role for for DBA who can manage DB, but not see data
-- ==========================================================================

-- Test SELECT -> This should fail
EXECUTE AS LOGIN = 'Mary'
SELECT * FROM SensitiveDatabase..SensitiveTable
REVERT
-- Test SELECT -> This should work after I revert
SELECT * FROM SensitiveDatabase..SensitiveTable

-- ==========================================================================
-- Step 4) Test backup database -> this should succeed
-- ==========================================================================
EXECUTE AS LOGIN = 'Mary'

BACKUP DATABASE SensitiveDatabase
TO DISK = 'G:\Backup\SensitiveDatabase.bak'
WITH FORMAT,
MEDIANAME = 'Z_Test',
NAME = 'Full backup of Sensitive Database'

Revert
-- ==========================================================================
-- Step 5) What if I wanted to prevent Mary from Impersonating others?
-- ==========================================================================

--Login as Mary into the server in another window

--Validate that I cannot see the data
SELECT * FROM SensitiveDatabase..SensitiveTable

--Remove the DENY ON SELECT ALL
Execute AS Login = 'sa'
GRANT SELECT ALL USER SECURABLES to MyLimitedAdmin --New in SQL Server 2014
REVERT

--Can I see the data now?
SELECT * FROM SensitiveDatabase..SensitiveTable

-- ==========================================================================
-- Step 6) Remove the loophole
-- ==========================================================================

DENY SELECT ALL USER SECURABLES to MyLimitedAdmin --New in SQL Server 2014
DENY IMPERSONATE ANY LOGIN to MyLimitedAdmin --New in SQL Server 2014

-- ==========================================================================
-- Step 7) Re-Test if Mary can impersonate
-- ==========================================================================
--Login as Mary into the server in another window

--Validate that I cannot see the data
SELECT * FROM SensitiveDatabase..SensitiveTable

--Remove the DENY ON SELECT ALL
Execute AS Login = 'sa'
GRANT SELECT ALL USER SECURABLES to MyLimitedAdmin --New in SQL Server 2014
REVERT

--Can I see the data now?
SELECT * FROM SensitiveDatabase..SensitiveTable

-- ==========================================================================
-- Step 5) Cleanup
-- ==========================================================================

USE master
GO
ALTER SERVER ROLE MyLimitedAdmin DROP MEMBER Mary
GO
DROP SERVER ROLE MyLimitedAdmin
GO
-- Select 'Kill '+cast(session_id as char(3)) from sys.dm_exec_sessions where login_name = 'Mary'
DROP LOGIN Mary
GO
DROP DATABASE SensitiveDatabase
GO


