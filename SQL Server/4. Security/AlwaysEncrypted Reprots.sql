select JobTitle, MaritalStatus, Count(*) '#Employees' from employee_encrypted
group by JobTitle, MaritalStatus
Order by 3 desc

Select GroupName, Name, Count(*) as '# Employees'
from HumanResources.Department D
Inner Join HumanResources.EmployeeDepartmentHistory EDH
On D.DepartmentID = EDH.DepartmentID
Inner Join employee_encrypted EE
On EE.BusinessEntityID = EDH.BusinessEntityID
group by D.GroupName, D.Name
Order by 3 desc

EXECUTE AS USER = 'DDM_User'
go


Select GroupName, Name, HireDate,FirstName, LastName,  SocialSecurity, BirthDate, MaritalStatus, GEnder, loginid
from HumanResources.Department D
Inner Join HumanResources.EmployeeDepartmentHistory EDH
On D.DepartmentID = EDH.DepartmentID
Inner Join employee_encrypted EE
On EE.BusinessEntityID = EDH.BusinessEntityID
Inner Join Person.person PP
On PP.BusinessEntityID = EE.BusinessEntityID
--where loginid = 'RLS_User'
Where groupname ='Sales and Marketing'
Order by 3 desc

REVERT

Select * from HumanResources.EmployeeDepartmentHistory
Select * from HumanResources.EmployeePayHistory
Select * from employee_encrypted
Select * from person.person