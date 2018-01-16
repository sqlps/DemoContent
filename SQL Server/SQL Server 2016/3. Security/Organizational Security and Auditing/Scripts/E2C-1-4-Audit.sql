USE master ;
GO
-- Create the server audit
CREATE SERVER AUDIT Payrole_Security_Audit
   TO FILE (FILEPATH = 'C:\SQLAUDITS' ) ;
GO
-- Enable the server audit
ALTER SERVER AUDIT Payrole_Security_Audit WITH (STATE = ON);
GO
-- Move to the target database
USE AdventureWorks2016 ;
GO
-- Create the database audit specification
CREATE DATABASE AUDIT SPECIFICATION Audit_Pay_Tables
FOR SERVER AUDIT Payrole_Security_Audit
ADD (SELECT , INSERT ON HumanResources.EmployeePayHistory BY dbo )
WITH (STATE = ON) ;
GO