-- ===================================
-- Step 1) Create Audit Security Role
-- ===================================

CREATE LOGIN MaryFromAudit WITH PASSWORD = 'pass@word1'

-- Create a new server role and we will limit the access 
CREATE SERVER ROLE AuditGroup AUTHORIZATION sysadmin
  
-- Add login Mary into the newly created server role
ALTER SERVER ROLE AuditGroup ADD MEMBER MaryFromAudit

-- Add CONTROL SERVER permission to the new server role to manage the dB instance
USE master
GO
GRANT CONNECT ANY DATABASE to AuditGroup --New with 2014
GRANT SELECT ALL USER SECURABLES to AuditGroup --New with 2014

-- ===================================
-- Step 2) Create a new DB
-- ===================================

If Exists( Select Name from sys.databases where name = 'RandomNewDBDatabase')
	Drop Database [RandomNewDBDatabase]
GO

CREATE DATABASE [RandomNewDBDatabase]
GO

USE [RandomNewDBDatabase]
GO

CREATE TABLE [dbo].[RandomNewDBTable](
	[FullName] [nvarchar](50) NULL,
	[SocialSecurity] [nvarchar](50) NULL,
	[Salary] [money] NULL
) ON [PRIMARY]
GO

INSERT INTO [dbo].[RandomNewDBTable]
           ([FullName]
           ,[SocialSecurity]
           ,[Salary])
     VALUES
           ('Bob Jones'
           ,'123-45-6789'
           ,1000000)
GO

INSERT INTO [dbo].[RandomNewDBTable]
           ([FullName]
           ,[SocialSecurity]
           ,[Salary])
     VALUES
           ('Mary White'
           ,'321-54-9876'
           ,1500000)
GO

-- ===================================
-- Step 3) Test in SSMS
-- ===================================

--Connect as MaryFromAudit/pass@word1 and validate you can browse the new DB

-- ==========================================================================
-- Step 4) Cleanup
-- ==========================================================================

USE master
GO
ALTER SERVER ROLE AuditGroup DROP MEMBER MaryFromAudit
GO
DROP SERVER ROLE AuditGroup
GO
-- Select 'Kill '+cast(session_id as char(3)) from sys.dm_exec_sessions where login_name = 'MaryFromAudit'
DROP LOGIN MaryFromAudit
GO
DROP DATABASE RandomNewDBDatabase
GO


