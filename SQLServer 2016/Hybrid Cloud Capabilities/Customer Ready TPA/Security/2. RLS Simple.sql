/* This Sample Code is provided for the purpose of illustration only and is not intended 
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE 
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR 
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You 
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or 
result from the use or distribution of the Sample Code.
*/

/*
RLS is implemented by using the CREATE SECURITY POLICY Transact-SQL statement, 
and predicates created as inline table valued functions.
*/

--0. Clean-up:
USE AdventureWorks2014
GO

DROP USER IF Exists Doctor 
DROP USER IF Exists Nurse1 
DROP USER IF Exists Nurse2
DROP USER IF Exists Nurse3
GO
DROP SECURITY POLICY If Exists StaffFilter
GO
DROP FUNCTION If Exists Security.fn_securitypredicate
GO
DROP SCHEMA If Exists Security;
GO
DROP TABLE If Exists Patients
GO

--1). Once connected to the test database run the below query to create the logins we will be using within this demo:
USE AdventureWorks2014
GO

CREATE USER Doctor WITHOUT LOGIN;
CREATE USER Nurse1 WITHOUT LOGIN;
CREATE USER Nurse2 WITHOUT LOGIN;
CREATE USER Nurse3 WITHOUT LOGIN;

--2). Run the below query to create a Patients table which we will define a security policy against later on in the demo

--Create Tables
CREATE TABLE Patients
    (
    PatientID int,
    FirstName varchar(50),
    LastName varchar(50),
    Symptom varchar(50),
	StaffMember varchar(20)
    );
GO

--Create some data

INSERT Patients VALUES 
(1, 'Syed', 'Abbas', 'Common Cold', 'Doctor'), 
(2, 'David', 'Campbell', 'Pinkeyes','Nurse1'), 
(3, 'Garrett', 'Vargas', 'Chicken Pox','Nurse2'),
(4, 'Tsvi', 'Reiter', 'Broken Leg','Nurse1'), 
(5, 'Jillian', 'Carson', 'Amnesia','Nurse2'), 
(6, 'Missy', 'May', 'Hypertension','Nurse1'),
(7, 'Michael', 'Blythe', 'Amnesia','Nurse1'), 
(8, 'Rachel', 'Valdez', 'Inner Thigh Injury','Nurse2'), 
(9, 'Amy', 'Alberts', 'Overdose','Nurse1'),
(10, 'Linda', 'Mitchell', 'Sports Related Injury','PROCESSING'), 
(11, 'José', 'Saraiva', 'Cut under eye','IN LOBBY'),
(12, 'Jae', 'Pak', 'Looking for Beth Greene','IN LOBBY'), 
(13, 'Ranjit', 'Varkey-Chudukatil', 'Serious Hand Injury','Nurse2'), 
(14, 'Stephen', 'Jiang', 'Broken Nose','Nurse1'),
(15, 'Lynn', 'Tsoflias', 'Sports Related Injury','PROCESSING'), 
(16, 'Pamela', 'Ansman-Wolfe', 'Zombie','IN LOBBY'),
(17, 'Tete', 'Mensa-Annan', 'Cut on arm','IN LOBBY'),
(18, 'Shu', 'Ito', 'Pregnancy Related','Nurse1'), 
(19, 'Shai', 'Bassli', 'Barn related injury, Zombie','Nurse2'), 
(20, 'Max', 'Benson', 'Serious hand related injury.. Could be Zombie','Nurse1'),
(21, 'Krishna', 'Sunkammurali', 'Possible ACL injury','Nurse2'),
(22, 'Stephen', 'Jiang', 'Elbow injury','Nurse3'),
(23, 'Thierry', 'D''Hers', 'Bumped his head','Nurse1'), 
(24, 'Christian', 'Kleinerman', 'Treadmill related injury','Nurse2'), 
(25, 'Stephen', 'Tsoflias', 'Lower back injury','Nurse1');
GO
revert
-- View the rows in the table
SELECT * FROM Patients;
GO

--Permissions
GRANT SELECT,INSERT,UPDATE,DELETE ON Patients TO Doctor;
GRANT SELECT,INSERT,UPDATE,DELETE ON Patients TO Nurse1;
GRANT SELECT,INSERT,UPDATE,DELETE ON Patients TO Nurse2;
GRANT SELECT,INSERT,UPDATE,DELETE ON Patients TO Nurse3;
GO

-- 3. Setup Security
CREATE SCHEMA Security; --Not a requirement, but recommended BP
GO

CREATE FUNCTION Security.fn_securitypredicate(@Staff AS sysname)
    RETURNS TABLE
	WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS fn_securitypredicate_result 
WHERE @Staff = USER_NAME() OR USER_NAME() = 'Doctor'; --Give me the permissions matching current user, or the doctor can see all patients
GO


--4.	Create the security Policy. Create a security policy adding the function as a filter predicate. The state must be set to ON to enable the policy.
--Create the policy

/* JUST FILTER PREDICATE:
CREATE SECURITY POLICY StaffFilter
ADD FILTER PREDICATE Security.fn_securitypredicate(StaffMember) 
ON dbo.Patients
WITH (STATE = ON);
GO
*/

--FILTER AND BLOCK PREDICATE:
CREATE SECURITY POLICY StaffFilter
ADD FILTER PREDICATE Security.fn_securitypredicate(StaffMember) ON dbo.Patients,
ADD BLOCK PREDICATE Security.fn_securitypredicate(StaffMember) ON dbo.Patients
WITH (STATE = ON);
GO

--5.	Test Access
--Run the below which impersonates the login of the Doctor, ..this should return all rows:

EXECUTE AS USER = 'Doctor';
SELECT * FROM patients; 
REVERT;

--6. Run the below which impersonates the login of Nurse1. This should return a limited number of rows:
EXECUTE AS USER = 'Nurse1';
SELECT * FROM patients; 
REVERT;

--7. Run the below which impersonates the login of Nurse2. This should return a limited number of rows:
EXECUTE AS USER = 'Nurse2';
SELECT * FROM patients; 
REVERT;

--8. Run the below which impersonates the login of Nurse3. This should return a limited number of rows:
EXECUTE AS USER = 'Nurse3';
SELECT * FROM patients; 
REVERT;

--8. View metadata about the policies and predicates that have been created
SELECT * FROM sys.security_policies 

SELECT * FROM sys.security_predicates 

--9. BLOCK PREDICATE IN ACTION; UPDATE EXAMPLE
EXECUTE AS USER = 'Nurse2';
SELECT * FROM Patients 
WHERE LastName = 'Sunkammurali' --Who is his nurse?
REVERT;

EXECUTE AS USER = 'Nurse1';
--No dice, you aren't Krishna's Nurse
UPDATE patients 
SET Symptom = 'Bowl of soup got cold.'
WHERE LastName = 'Sunkammurali'
REVERT;

EXECUTE AS USER = 'Doctor'; --The Doctor, can do it all
UPDATE patients 
SET Symptom = 'Bowl of soup got cold.'
WHERE LastName = 'Sunkammurali'
REVERT;

--10. BLOCK PREDICATE IN ACTION; UPDATE EXAMPLE
EXECUTE AS USER = 'Nurse3'; --ZOMBIE COVER UP!!!
DELETE FROM patients 
WHERE Symptom LIKE '%Zombie%'
REVERT;

EXECUTE AS USER = 'Doctor'; --CHECKING ZOMBIE INFECTED PATIENTS
SELECT * FROM patients 
WHERE Symptom LIKE '%Zombie%'
REVERT;

--11. BLOCK PREDICATE IN ACTION; INSERT EXAMPLE
EXECUTE AS USER = 'Nurse3'; --TRYING TO SNEAK HER FRIEND INTO THE SYSTEM!!
INSERT INTO patients
(PatientID, FirstName, LastName, Symptom, StaffMember)
VALUES
(26, 'Jeremy','Tsoflias','Shin splints from soccer game','Nurse2')
GO
REVERT;

--12. DISABLE THE SECURITY POLICY; NURSE3 TEST
ALTER SECURITY POLICY StaffFilter
WITH (STATE = OFF);
GO

--Run the below which impersonates the login of Nurse3.
EXECUTE AS USER = 'Nurse3';
SELECT * FROM patients; 
REVERT;