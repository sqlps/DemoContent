-- ====================================
-- Step 1) Setup
-- ====================================
ALTER Database DynamicDataMasking
Set Single_user with Rollback immediate
Go

Drop Database DynamicDataMasking
GO

Create Database DynamicDataMasking
GO

Use DynamicDataMasking
Go

CREATE TABLE Membership
  (MemberID int IDENTITY PRIMARY KEY,
   FirstName varchar(100) MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)') NULL,
   LastName varchar(100) NOT NULL,
   Phone# varchar(12) MASKED WITH (FUNCTION = 'default()') NULL,
   Email varchar(100) MASKED WITH (FUNCTION = 'email()') NULL);

INSERT Membership (FirstName, LastName, Phone#, Email) VALUES 
('Roberto', 'Tamburello', '555.123.4567', 'RTamburello@contoso.com'),
('Janice', 'Galvin', '555.123.4568', 'JGalvin@contoso.com.co'),
('Zheng', 'Mu', '555.123.4569', 'ZMu@contoso.net');

SELECT * FROM Membership;

-- ====================================
-- Step 2) Create non admin user
-- ====================================
CREATE USER TestUser WITHOUT LOGIN;
GRANT SELECT ON Membership TO TestUser;

EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT;

-- ============================================================
-- Step 3) Add Mask to existing column and modify existing mask
-- ============================================================
ALTER TABLE Membership
ALTER COLUMN LastName ADD MASKED WITH (FUNCTION = 'partial(2,"XXX",0)');

ALTER TABLE Membership
ALTER COLUMN LastName varchar(100) MASKED WITH (FUNCTION = 'default()');

EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT;

-- ============================================================
-- Step 4) Grant/Revoke unmask to TestUser
-- ============================================================

GRANT UNMASK TO TestUser;
EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT; 

-- Removing the UNMASK permission
REVOKE UNMASK TO TestUser;
EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT; 
