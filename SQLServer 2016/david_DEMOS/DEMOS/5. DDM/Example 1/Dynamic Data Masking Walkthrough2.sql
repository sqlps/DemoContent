--DYNAMIC DATA MASKING
/*Dynamic Data Masking will obfuscate data based upon your permissions and can be used to 
mask sensitive data after implementing Dynamic Data Masking*/

USE [AdventureWorks2014]
GO

--0 - Cleanup
DROP TABLE Membership
GO
DROP USER TestUser
GO

--1 - Creating a dynamic data mask
/*The following example creates a table with three different types of dynamic data masks. 
The example populates the table and selects to show the result.*/
USE [AdventureWorks2014]
GO

CREATE TABLE Membership
  (MemberID int IDENTITY PRIMARY KEY,
   EmployeeID int,
   FirstName varchar(100) MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)') NULL,
   LastName varchar(100) NOT NULL,
   Salary Money MASKED WITH (FUNCTION = 'random(100000, 10000000)') NULL,
   SSN varchar(100) MASKED WITH (FUNCTION = 'partial(0,"***-**-",4)') NULL,
   Phone# varchar(12) MASKED WITH (FUNCTION = 'default()') NULL,
   Email varchar(100) MASKED WITH (FUNCTION = 'email()') NULL);

INSERT Membership (EmployeeID, FirstName, LastName, Salary, SSN, Phone#, Email) VALUES 
(324,'Roberto', 'Tamburello', '35000', '1', '555.123.4567', 'RTamburello@contoso.com'),
(685,'Janice', 'Galvin', '42000','1', '555.123.4568', 'JGalvin@contoso.com.co'),
(283,'Zheng', 'Mu', '75000','1', '555.123.4569', 'ZMu@contoso.net')
GO

INSERT INTO Membership (EmployeeID, FirstName, LastName, Salary, SSN, Phone#, Email) 
(
SELECT BusinessEntityID, FirstName, LastName, ISNULL(SalesQuota,80000),'1', PhoneNumber, EmailAddress
  FROM [AdventureWorks2014].[Sales].[vSalesPerson]

WHERE PhoneNumber NOT LIKE '%)%'
)

Update Membership 
SET SSN = CAST(LEFT(CAST(ABS(CAST(CAST(NEWID() as BINARY(10)) as int)) as varchar(max)) + '00000000',9) as int)
GO

--Examine the data
SELECT * FROM Membership;

--2 - Creating a dynamic data mask
/*A new user is created and granted SELECT permission on the table. 
Queries executed as the TestUser view masked data.*/

CREATE USER TestUser WITHOUT LOGIN;
GRANT SELECT ON Membership TO TestUser;

EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT;

--3 - Adding or editing a mask on an existing column
/*Use the ALTER TABLE statement to add a mask to an existing column in the table, or to edit the mask on that column. The following example adds a masking function to the LastName column:*/

ALTER TABLE Membership
ALTER COLUMN LastName ADD MASKED WITH (FUNCTION = 'partial(2,"XXX",0)');

EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT;

--The following example changes a masking function on the LastName column:

ALTER TABLE Membership
ALTER COLUMN LastName varchar(100) MASKED WITH (FUNCTION = 'default()');

EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT;

--The following example changes a masking function on the EmployeeID column:

ALTER TABLE Membership
ALTER COLUMN EmployeeID ADD MASKED WITH (FUNCTION = 'random(1000,9000)');

EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT;

--4 - Querying for Masked Columns
/*Use sys.masked_columns view to query for table columns that have a masking function applied to them. 
This view inherits from sys.columns view. It returns all columns in sys.columns view, plus is_masked and masking_function 
columns—indicating if a column is masked, and if so, what masking function is defined. 
This view only shows columns on which there is a masking function applied.
*/

SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function
FROM sys.masked_columns AS c
JOIN sys.tables AS tbl 
    ON c.[object_id] = tbl.[object_id]
WHERE is_masked = 1;

--5 - Granting permission to view unmasked data
/*Granting UNMASK permission allows TestUser to see data unmasked.*/

GRANT UNMASK TO TestUser;
EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT; 

-- Removing the UNMASK permission
REVOKE UNMASK TO TestUser;

--6 - Dropping a dynamic data mask
/*The following statement drops the mask on the LastName column created in the previous example:*/

ALTER TABLE Membership 
ALTER COLUMN LastName DROP MASKED;

--Test drop of LastName mask
EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership;
REVERT; 

--7 - Examining AGGREGATES 

SELECT SUM(Salary) FROM Membership; --3,042,000.00

EXECUTE AS USER = 'TestUser';
SELECT SUM(Salary) FROM Membership
REVERT;

--8 - JOINING MASKED AND UNMASKED TABLES 

GRANT SELECT ON Sales.vSalesPerson TO TestUser;

EXECUTE AS USER = 'TestUser';
SELECT a.FirstName, a.LastName, a.Salary, a.SSN, a.Phone#, a.Email,
b.City, b.JobTitle, b.AddressLine1, b.AddressLine2,b.City,b.StateProvinceName,b.PostalCode 
FROM Membership a
JOIN Sales.vSalesPerson b
ON a.LastName = b.LastName AND
a.FirstName = b.FirstName
REVERT;

--9 - ATTEMPTING TO SEND DATA TO A TEMP TABLE TO UNMASK
EXECUTE AS USER = 'TestUser';
SELECT MemberID, EmployeeID, FirstName, LastName, Salary, SSN, Phone#, Email
INTO #EvilAttempt
FROM Membership;
REVERT;

SELECT * FROM #EvilAttempt


--10 - DDM IS GOOD, BUT ITS POSSIBLE TO NARROW DOWN RESULTS (USE IN COMBINATION WITH AUDITING TO COMBAT)
SELECT * FROM Membership --Note Zheng Mu's salary

EXECUTE AS USER = 'TestUser';
SELECT * FROM Membership
WHERE Salary > 70000 AND SALARY < 80000
REVERT;

