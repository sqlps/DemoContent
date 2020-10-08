USE AdventureWorks2016
select * from HumanResources.EmployeePayHistory where BusinessEntityID= 4
GO
Update HumanResources.EmployeePayHistory set rate = 69.8462
where BusinessEntityID=4 and RateChangeDate = '2007-12-05 00:00:00.000'
GO