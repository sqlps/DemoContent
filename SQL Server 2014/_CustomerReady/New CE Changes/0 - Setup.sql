/* This Sample Code is provided for the purpose of illustration only and is not intended
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys fees, that arise or
result from the use or distribution of the Sample Code.*/

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
