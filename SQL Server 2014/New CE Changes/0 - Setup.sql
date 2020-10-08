Use MyDemoDB
GO

If Exists (Select Name from sys.objects where name = 'Cars' and Type = 'U')
	Drop Table Cars
Go

Create Table Cars(Make varchar(50), Model varchar(25))
GO
Insert Cars(Make,Model)
Values('Honda','Civic')
GO 50
Insert Cars(Make,Model)
Values('Honda','Pilot')
GO 50
Insert Cars(Make,Model)
Values('Honda','Accord')
GO 50
Insert Cars(Make,Model)
Values('Honda','CRZ')
GO 50
Insert Cars(Make,Model)
Values('Ford','Explorer')
GO 50
Insert Cars(Make,Model)
Values('Ford','Ranger')
GO 50
Insert Cars(Make,Model)
Values('Pontiac','Aztec')
GO 700
