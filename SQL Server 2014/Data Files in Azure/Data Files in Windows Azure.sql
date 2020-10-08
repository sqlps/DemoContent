-- From Azure Storage Explorer
-- 1) Make sure you connect to your Azure Storage account with HTTPS
-- 2) Connect to storage explorer and select the container 
-- 3) Hit the Security button
-- 4) Go to the Shared Access Signatures
-- 5) Set and expiration date
-- 6) Select List, Delete, Read, Write
-- 7) Click Generate Signature and copy
-- 8) Go to Access Level tab and hit "Update Access Level"
-- 9) Parse Signature and use to create Credential

--Sample Signature
https://pankajtsp.blob.core.windows.net/sqlbackups?sv=2014-02-14&sr=c&sig=Ztz%2FQyymKu%2BQHih7fsmspl29cO%2BiBIkFRJHjq9mXQEs%3D&st=2015-03-31T04%3A00%3A00Z&se=2015-04-08T04%3A00%3A00Z&sp=rwdl

If Exists (Select name from sys.credentials where name = 'https://pankajtsp.blob.core.windows.net/sqlbackups')
	DROP CREDENTIAL [https://pankajtsp.blob.core.windows.net/sqlbackups] 
go

USE master
CREATE CREDENTIAL [https://pankajtsp.blob.core.windows.net/sqlbackups] 
   WITH IDENTITY='SHARED ACCESS SIGNATURE', -- this is a mandatory string and do not change it. 
   SECRET = 'sv=2014-02-14&sr=c&sig=Ztz%2FQyymKu%2BQHih7fsmspl29cO%2BiBIkFRJHjq9mXQEs%3D&st=2015-03-31T04%3A00%3A00Z&se=2015-04-08T04%3A00%3A00Z&sp=rwdl' -- this is everything after the ? mark 
GO  

--Create a database that uses a SQL Server credential  
CREATE DATABASE TestDB1  
ON 
(NAME = TestDB1_data, 
   FILENAME = 'https://pankajtsp.blob.core.windows.net/sqlbackups/TestDB1Data1.mdf') 
 LOG ON 
(NAME = TestDB1_log, 
    FILENAME = 'https://pankajtsp.blob.core.windows.net/sqlbackups/TestDB1Log1.ldf') 
GO 