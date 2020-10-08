/* This Sample Code is provided for the purpose of illustration only and is not intended
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys fees, that arise or
result from the use or distribution of the Sample Code.*/



-- Demo Database administrators who cannot see user data

-- Pre Demo: You should create a dummy database called SensitiveDatabase
-- create a table called SensitiveTable, and insert some dummy data
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

-- 1. Create a login, new server role, allow CONTROL SERVER permission but
--    deny SELECT ALL USER SECURABLES permission
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
DENY SELECT ALL USER SECURABLES to MyLimitedAdmin

-- 2. Test by login in as Mary in SSMS
-- Copy this part onwards of the code after login as Mary

-- 3. Test SELECT -> This should fail
USE SensitiveDatabase
GO

SELECT * FROM SensitiveTable
GO

-- 4. Test backup database -> this should succeed
BACKUP DATABASE SensitiveDatabase
TO DISK = 'G:\Backup\SensitiveDatabase.bak'
WITH FORMAT,
MEDIANAME = 'Z_Test',
NAME = 'Full backup of Sensitive Database'

-- 5. Clean up
USE master
GO
ALTER SERVER ROLE MyLimitedAdmin DROP MEMBER Mary
GO
DROP SERVER ROLE MyLimitedAdmin
GO
DROP LOGIN Mary
GO
DROP DATABASE SensitiveDatabase
GO
