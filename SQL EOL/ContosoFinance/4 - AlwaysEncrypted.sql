-- ============================================
-- Use the following steps to export Cert to be imported
-- ============================================
-- https://beanalytics.wordpress.com/2016/09/15/using-sql-always-encrypted-with-azure-web-app-service/

--Encrypt SSN from SSMS
-- WebApp needs to be atleast Basic

GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO  AppUser 
GRANT VIEW ANY COLUMN ENCRYPTION KEY  DEFINITION TO  AppUser 
GO

Select * from Customers