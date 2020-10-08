-- ================================================
-- Step 1) Create Creds
-- ================================================
Select * from sys.credentials

CREATE CREDENTIAL [https://pankajcsa.blob.core.windows.net/sqlbackups] 
WITH IDENTITY= 'SHARED ACCESS SIGNATURE'
, SECRET = 'sv=2014-02-14&sr=c&sig=4kAJE4hNAmLHY9mJbE2wPWXkNKz69aV33zXqjZkwovs%3D&se=2019-12-19T05%3A00%3A00Z&sp=rwdl' --This is everything after ?
GO

-- ================================================
-- Step 2) RESTORE DATABASE FROM URL
-- ================================================
RESTORE DATABASE ContosoFinance_NonDMA FROM URL = N'https://pankajcsa.blob.core.windows.net/sqlbackups/ContosoFinance.bak'