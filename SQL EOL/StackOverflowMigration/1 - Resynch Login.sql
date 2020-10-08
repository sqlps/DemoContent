--Use sp_revlogin to generate login scripts

-- ============================================
-- Step 1) Create login scripting from original
-- ============================================
-- Login: StackOverFlowGuy
CREATE LOGIN [StackOverFlowGuy] WITH PASSWORD=0x0100943CA7DFD243ACCFD17FA6EEF5095AB365DD48CFD06024FF HASHED, CHECK_POLICY=OFF, CHECK_EXPIRATION=OFF, SID=0x77B5E135AC3B454DA1A1C286B541F717
 
-- Within database
Create User  [StackOverFlowGuy]  from Login  [StackOverFlowGuy] 

Exec sp_addrolemember 'db_owner', [stackoverflowguy]