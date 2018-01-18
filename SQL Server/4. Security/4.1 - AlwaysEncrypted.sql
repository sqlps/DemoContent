--USE GUI TO SHOW
-- ====================================
-- Step 1) Setup
-- ====================================
Use AdventureWorks2014
Go
---------------------------------------------
DROP TABLE IF EXISTS employee_encrypted

Select * into employee_encrypted
From HumanResources.Employee
Go

sp_rename 'dbo.employee_encrypted.NationalIDNumber', 'SocialSecurity', 'Column'
GO

CREATE CLUSTERED INDEX [CI_SocialSecurity] ON [dbo].[employee_encrypted]
(
	[SocialSecurity] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

-- ============================================
-- Step 2) Validate data is not encrypted
-- ============================================
Use AdventureWorks2014
Go

Select * from employee_encrypted

-- ============================================
-- Step 3) Step thru Wizard to Encrypt the data
-- ============================================
--Launch Wizard

-- ============================================
-- Step 4) View encrypted data after wizard
-- ============================================
Use AdventureWorks2014
Go

Select * from employee_encrypted
--Connection String 
-- Data Source=SQL2016-SQL1;Initial Catalog=Adventureworks2016;Integrated Security=True;Column Encryption Setting=Enabled

-- ============================================
-- Step 5) Query with filter
-- ============================================
Select Loginid, MaritalStatus,Gender
from employee_encrypted
where SocialSecurity = '830150469'  -- No dice

-- Need to paramertize it and SSMS 17.0 with Parameterization for AE enabled see: https://blogs.msdn.microsoft.com/sqlsecurity/2016/12/13/parameterization-for-always-encrypted-using-ssms-to-insert-into-update-and-filter-by-encrypted-columns/
DECLARE @SSN nvarchar(15) = '830150469'
Select Loginid, MaritalStatus,Gender
from employee_encrypted
where SocialSecurity = @SSN
go
-- ============================================
-- Step 6) Insert/Update some data
-- ============================================
Declare @SSN nvarchar(15)= '5585842154',
		@MS nchar(1) = 'M',
		@Gender nchar(1) ='M'
Insert employee_encrypted (BusinessEntityID, SocialSecurity, LoginID, JobTitle, BirthDate, MaritalStatus, Gender, HireDate, SalariedFlag, VacationHours, SickLeaveHours, CurrentFlag, rowguid, ModifiedDate)
values(99999, @SSN, 'pankajtsp\pankajadmin', 'Chief Janitor', '01/01/89', @MS, @Gender, '01/01/2013', 1, 10,40,1, '7E632B21-0D11-4BBA-8A68-8CAE14C20AE6', '2014-06-30 00:00:00.000')
GO

--
UPDATE employee_encrypted
SET JobTitle = 'Chief Sanitation Engineer'
Where SocialSecurity = '5585842154'


Declare @SSN nvarchar(15)= '5585842154'
UPDATE employee_encrypted
SET JobTitle = 'Chief Sanitation Engineer'
Where SocialSecurity = @SSN

Select *
from employee_encrypted
where SocialSecurity = @SSN
GO

Declare @SSN nvarchar(15)= '5585842154'
Delete from employee_encrypted
where SocialSecurity = @SSN
GO