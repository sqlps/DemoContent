-- =====================================================================================================
-- Step 1) View current memberships
-- =====================================================================================================
Use WideWorldImporters
GO

SELECT * FROM sys.database_principals where name like 'Great%'; -- note the role for Great Lakes and the user for Great Lakes
GO

-- =====================================================================================================
-- Step 2) View all customers
-- =====================================================================================================
--Note current count
Select * from Sales.customers
GO

--Visualize it
SELECT c.Border 
FROM [Application].Countries AS c
WHERE c.CountryName = N'United States'
UNION ALL
SELECT c.Deliverylocation FROM Sales.Customers c; -- and note count and map
GO

-- =====================================================================================================
-- Step 3) Run as Great lakes user
-- =====================================================================================================
-- impersonate the user GreatLakesUser
EXECUTE AS USER = 'GreatLakesUser';
GO

-- Now note the count and which rows are returned
-- even though we have not changed the command

SELECT * FROM Sales.Customers; 
GO

-- Visualize it
SELECT c.Border 
FROM [Application].Countries AS c
WHERE c.CountryName = N'United States'
UNION ALL
SELECT c.DeliveryLocation 
FROM Sales.Customers AS c;
GO

-- updating rows that are accessible to a non-accessible row is blocked
UPDATE Sales.Customers            -- Attempt to update
SET DeliveryCityID = 3            -- to a city that is not in the Great Lakes Sales Territory
WHERE DeliveryCityID = 32887;     -- for a customer that is in the Great Lakes Sales Territory

REVERT;
GO

-- =====================================================================================================
-- Step 4) Run as Website user
-- =====================================================================================================

-- Log on as SQL login Website with password SQLRocks!00

-- Ensure we are logged on as the website user
SELECT SUSER_SNAME();
GO

-- Note that no customers are visible as yet
SELECT * FROM Sales.Customers; 
GO

-- Set the session context (the website would set this on behalf of the user)
EXEC sp_set_session_context N'SalesTerritory', N'Great Lakes', @read_only = 1;
GO

-- Check the value that was set
SELECT SESSION_CONTEXT(N'SalesTerritory');
GO

-- Note that the user can now access the users based upon the sales territory in the session_context
SELECT * FROM Sales.Customers; 
GO


