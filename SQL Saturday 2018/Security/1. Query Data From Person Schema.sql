-- ==========================================
-- Step 1) Query against GDPR data
-- ===========================================
/*
1. Ensure Audit running in powerShell E:\Demos\Azure\Azure SQLDB\Auditing.ps1
*/
-- ==========================================
-- Step 2) Query against GDPR data
-- ===========================================
Select * from Person.Person
Where LastName like 'sa%'
-- ==========================================
-- Step 3) Data Exfiltration Attack
-- ===========================================
Select * from Person.Person
-- ==========================================
-- Step 4) Query against GDPR data
-- ===========================================
/*
1. Stop Audit Log from PowerShell
2. View log in SSMS
3. Check Log Analytics
*/