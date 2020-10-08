CREATE DATABASE clinic
( MAXSIZE = 500 MB, EDITION = 'basic', SERVICE_OBJECTIVE = 'basic' ) ;

-- ============================================
-- Step 2) Create Login with Password in master
-- ============================================
--OLD WAY
--CREATE LOGIN ContosoClinicApplication WITH password='$trongP@ssw0rd';

-- ============================================
-- Step 2) Create User mapped to Login within DB
-- ============================================
--OLD WAY
-- CREATE User ContosoClinicApplication From Login ContosoClinicApplication

--ContainedLogin for portability
CREATE USER AppUser WITH PASSWORD = '$trongP@ssw0rd';

-- ============================================
-- Step 3) Add roles needed
-- ============================================
exec sp_addrolemember 'db_datareader', 'AppUser'; 
exec sp_addrolemember 'db_datawriter', 'AppUser'; 
GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO  AppUser 
GRANT VIEW ANY COLUMN ENCRYPTION KEY  DEFINITION TO  AppUser 
GRANT EXECUTE ON [GetEngineEdition] to AppUser