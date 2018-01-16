-- ====================================
-- Step 1) Setup
-- ====================================
use Master 
Go

ALTER Database db_rls_demo_hospital
Set Single_user with Rollback immediate
Go

Drop Database db_rls_demo_hospital
GO

USE [master]
RESTORE DATABASE [db_rls_demo_hospital] FROM  DISK = N'D:\Backup\db_rls_demo_hospital.bak' WITH  FILE = 1,  MOVE N'db_rls_demo_hospital' TO N'D:\DATA\db_rls_demo_hospital.mdf',  MOVE N'db_rls_demo_hospital_log' TO N'D:\DATA\db_rls_demo_hospital_log.ldf',  NOUNLOAD,  STATS = 5
GO

-- ====================================
-- Step 2) View Current data
-- ====================================
-- Lab 1: RLS security where users connect directly to the database
USE db_rls_demo_hospital
GO

-- 1.1 Explore the DB before RLS is implemented
-- You can see the patients
SELECT * FROM [patients];
GO

-- View the database role members
SELECT user_name(role_principal_id) Role, user_name(member_principal_id) Member
FROM sys.database_role_members
GO

-- View the existing users, roles, and the wing they are assigned to
SELECT s.empId, s.[role], e.name, user_name(e.databasePrincipalId) as [SqlUserName], 
s.wing, s.startTime, s.endTime 
FROM staffDuties s 
INNER JOIN employees e ON (e.empId = s.empId) 
ORDER BY empId;
GO

-- ====================================
-- Step 4) Modify the security policy with a new, more complex predicate function
-- ====================================

-- Create a new schema
CREATE SCHEMA [Security]
GO

CREATE FUNCTION [Security].fn_securitypredicate2(@wing int, @startTime datetime, @endTime datetime)
RETURNS TABLE 
WITH SCHEMABINDING
AS
    RETURN SELECT 1 as [fn_securitypredicate_result] 
	FROM dbo.StaffDuties d 
	INNER JOIN dbo.Employees e ON (d.EmpId = e.EmpId) 
    WHERE (e.databasePrincipalId = database_principal_id() 
	AND (   -- nurses & doctors can see the data for the wings they were working on...
			( (is_member('nurse') = 1  OR is_member('doctor') = 1 ) AND @wing = d.Wing)
			OR
			-- doctors can also see the data from the "emergency" wing
			( is_member('doctor') = 1 AND @wing = 3)
		)
		AND ( -- during the time of the day they were on duty
			(d.endTime >= @startTime) 
			AND 
			((d.startTime <= isnull(@endTime, getdate())))
		)
	)
	OR (-- RLS won't apply to 'administrator' members
		-- Note: This group could also be a domain security group instead of a SQL role
		is_member('administrator') = 1
	)
GO

-- Modify the policy to bind the new predicate function to patients (replacing the old filter predicate)
CREATE SECURITY POLICY [Security].[PatientsSecurity] 
	 ADD FILTER PREDICATE [Security].[fn_securitypredicate2](wing, startTime, endTime) 
	ON dbo.[patients]
GO

-- ====================================
-- Step 5) Verify that the new policy works as expected
-- ====================================
-- 
EXECUTE ('SELECT * FROM [patients];') AS USER = 'CodyR' --admin
GO
EXECUTE ('SELECT * FROM [patients];') AS USER = 'NightingaleF' --nurse in wing 3
GO
EXECUTE ('SELECT * FROM [patients];') AS USER = 'AllenM' --nurse across 1 2 and 3
GO
EXECUTE ('SELECT * FROM [patients];') AS USER = 'CharcotJ' --doctor can see all patients in wing 3 and their patients
GO


-- 1.5 Finally, let's look at the showplan to see how the query optimizer applies RLS
-- When policy is disabled, the filter predicate isn't applied (just an index scan, as normal)
ALTER SECURITY POLICY [Security].PatientsSecurity WITH (STATE = OFF)
GO
SET SHOWPLAN_ALL ON
GO
SELECT * FROM patients
GO
SET SHOWPLAN_ALL OFF
GO

-- When policy is enabled, the query optimizer applies the filter predicate
ALTER SECURITY POLICY [Security].PatientsSecurity WITH (STATE = ON)
GO
SET SHOWPLAN_ALL ON
GO
SELECT * FROM patients
GO
SET SHOWPLAN_ALL OFF
GO



