
-- STEP 1: Create a database master key to encrypt database scoped credential secret in the next step.
-- Replace <password> with a password to encrypt the master key
Use AdventureworksDW2016CTP3 
Go
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'P@ssw0rd'
ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'P@ssw0rd';


-- STEP 1: Create a database master key to encrypt database scoped credential secret in the next step.
-- Replace <password> with a password to encrypt the master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd';