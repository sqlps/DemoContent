-- ============================================
-- Step 1) Drop All Tables
-- ============================================
Select 'Drop Table '+name
From sys.tables
where type = 'U'


-- Truncate Table Customers
--Truncate Table Visits

-- ============================================
-- Step 2) Drop All Procs
-- ============================================
Select 'Drop Procedure '+name
From sys.objects
where type = 'P'

