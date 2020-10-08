SELECT magic FROM dbo.tblhoudini
GO
SELECT symptom,hospital FROM dbo.tbldoctor
GO
SELECT * FROM dbo.tblsocialmedia
GO
SELECT tacotime FROM Person.Address
GO
INSERT INTO Person.Address 
(AddressLine1,City,StateProvinceID,PostalCode,ModifiedDate)  
VALUES (N'3446 Stonewall Drive','Kennesaw',82,32796, GETDATE(),'This will fail');
GO