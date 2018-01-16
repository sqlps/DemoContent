-- Demo Database administrators who cannot see user data

-- Pre Demo: You should create a dummy database called SensitiveDatabase
-- create a table called SensitiveTable, and insert some dummy data
CREATE DATABASE [SensitiveDatabase]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Test', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Test.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Test_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Test_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
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
TO DISK = 'C:\Backup\SensitiveDatabase.bak'
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
