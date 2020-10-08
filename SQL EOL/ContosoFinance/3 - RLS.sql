

-- Reset the demo
DROP SECURITY POLICY IF EXISTS Security.customerSecurityPolicy
DROP FUNCTION IF EXISTS Security.customerAccessPredicate
DROP SCHEMA IF EXISTS Security
go

-- Observe existing schema
SELECT * FROM [dbo].[ApplicationUsercustomers]
go

select * from Customers
-- Mapping table, assigning application users to customers
-- We'll use RLS to ensure that application users can only access customers assigned to them
SELECT * FROM ApplicationUsercustomers
go

-- Create separate schema for RLS objects
-- (not required, but best practice to limit access)
CREATE SCHEMA Security
go

-- Create predicate function for RLS
-- This determines which users can access which rows
CREATE FUNCTION Security.customerAccessPredicate(@customerID int)
	RETURNS TABLE
	WITH SCHEMABINDING
AS
	RETURN SELECT 1 AS isAccessible
	FROM dbo.ApplicationUsercustomers
	WHERE 
	(
		-- application users can access only customers assigned to them
		customer_customerID = @customerID
		AND ApplicationUser_Id = CAST(SESSION_CONTEXT(N'UserId') AS nvarchar(128)) 
	)
	OR 
	(
		-- DBAs can access all customers
		--IS_MEMBER('db_owner') = 1 (Original)
		--select * from AspNetUsers where Email = 'admin@contoso.com'
		CAST(SESSION_CONTEXT(N'UserId') AS nvarchar(128)) = '3c13e848-e04e-4eca-af0c-9d4abcb40209' OR IS_MEMBER('db_owner') = 1
	)
go

-- Create security policy that adds this function as a security predicate on the customers and Visits tables
--	Filter predicates filter out customers who shouldn't be accessible by the current user
--	Block predicates prevent the current user from inserting any customers who aren't mapped to them
CREATE SECURITY POLICY Security.customerSecurityPolicy
	ADD FILTER PREDICATE Security.customerAccessPredicate(customerID) ON dbo.customers,
	ADD BLOCK PREDICATE Security.customerAccessPredicate(customerID) ON dbo.customers,
	ADD FILTER PREDICATE Security.customerAccessPredicate(customerID) ON dbo.Visits,
	ADD BLOCK PREDICATE Security.customerAccessPredicate(customerID) ON dbo.Visits
go



