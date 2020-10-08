USE master
GO
-- 1. Create a login, new server role for audit, allow CONNECT ANY DATABASE permission but
--    deny SELECT ALL USER SECURABLES permission

CREATE LOGIN Jane WITH PASSWORD = 'pass@word1'

-- Create a new server role and we will limit the access 
CREATE SERVER ROLE MyAuditor AUTHORIZATION sysadmin
  
-- Add login Jane into the newly created server role
ALTER SERVER ROLE MyAuditor ADD MEMBER jane

GRANT CONNECT ANY DATABASE to MyAuditor

GRANT VIEW ANY DEFINITION to MyAuditor

GRANT ALTER ANY SERVER AUDIT to MyAuditor

DENY SELECT ALL USER SECURABLES to MyAuditor

-- 2. Test by login in as Jane in SSMS. This should be successful
-- Copy this part onwards of the code after login as Jane

-- 3. Test by trying to go into any user databases. This should fail

USE AdventureWorks
GO

SELECT * from AdventureWorks.HumanResources.Department
GO

-- 4. Test creating new server level auditing. This should be successful
USE master
go

CREATE SERVER AUDIT [Audit-20140228-180015]
TO APPLICATION_LOG
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
	,AUDIT_GUID = '1985d220-8a84-4b60-93d9-66a36701dd0f'
)
ALTER SERVER AUDIT [Audit-20140228-180015] WITH (STATE = ON)
GO

CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpecification-20140228-180034]
FOR SERVER AUDIT [Audit-20140228-180015]
ADD (FAILED_LOGIN_GROUP)
WITH (STATE = ON)
GO

-- (Optional) You can try to show the audit is successful by looking at the Application Log after failed login try

-- 5. Clean up
USE master
GO
ALTER SERVER ROLE MyAuditor DROP MEMBER Jane
GO
DROP SERVER ROLE MyAuditor
GO
DROP LOGIN Jane
GO
-- Make sure you disable first before dropping
DROP SERVER AUDIT [Audit-20140228-180015]
GO
-- Make sure you disable first before dropping
DROP SERVER AUDIT SPECIFICATION [ServerAuditSpecification-20140228-180034]
GO