-- ============================================
-- Step 1) Create the databases
-- ============================================

CREATE DATABASE StackOverFlowEE
( MAXSIZE = 500 MB, EDITION = 'basic', SERVICE_OBJECTIVE = 'basic' ) ;

CREATE DATABASE StackOverFlowEE_DMS
( MAXSIZE = 500 MB, EDITION = 'basic', SERVICE_OBJECTIVE = 'basic' ) ;

-- ============================================
-- Step 2) Create Login with Password in master
-- ============================================

CREATE LOGIN stackoverflowguy WITH password='$tr0ngP@$$w0rd';

-- ============================================
-- Step 2) Create User mapped to Login within DB
-- ============================================

CREATE User stackoverflowguy From Login stackoverflowguy

-- ============================================
-- Step 3) Add roles needed
-- ============================================
exec sp_addrolemember 'db_datareader', 'LoadTest'; 
