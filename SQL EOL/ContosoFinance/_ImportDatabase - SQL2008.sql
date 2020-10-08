-- ====================================================================
-- Step 1) ImportDatabase from ContosoFinance.bacpac
-- ====================================================================
-- Import to SQL 2008/R2

-- ====================================================================
-- Step 2) Create your App Credentials to be used
-- ====================================================================
--Ex: 
Use Master
GO

CREATE LOGIN AppUser WITH password='$trongP@ssw0rd';
GO

Use ContosoFinance 
GO

CREATE User AppUser From Login AppUser
GO
-- Grant Perms
exec sp_addrolemember 'db_datareader', 'AppUser'; 
exec sp_addrolemember 'db_datawriter', 'AppUser'; 
exec sp_addrolemember 'db_owner', 'AppUser'; 
GRANT EXECUTE ON [GetEngineEdition] to AppUser

