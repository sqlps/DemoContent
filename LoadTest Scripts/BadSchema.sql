

SELECT D.Name
    ,CASE 
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 0 THEN E.JobTitle
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 1 THEN N'Total: ' + D.Name 
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 3 THEN N'Company Total:'
        ELSE N'Unknown'
    END AS N'Job Title'
    ,COUNT(E.BusinessEntityID) AS N'Employee Count'
FROM HumanResources.Employeesd E
    INNER JOIN HumanResources.EmployeesDepartmentHistoryd DH
        ON E.BusinessEntityID = DH.BusinessEntityID
    INNER JOIN HumanResources.Departmentd D
        ON D.DepartmentID = DH.DepartmentID     
WHERE DH.EndDate IS NULL
    AND D.DepartmentID IN (12,14)
GROUP BY ROLLUP(D.Name, E.JobTitle);

------

-- http://msdn.microsoft.com/en-us/library/bb510624.aspx
;

SELECT D.Name
    ,E.JobTitle
    ,GROUPING_ID(D.Name, E.JobTitle) AS 'Grouping Level'
    ,COUNT(E.BusinessEntityID) AS N'Employee Count'
FROM HumanResources.Employddqeesd AS E
    INNER JOIN HumanResources.EmployeesDepartmentHistoryd AS DH
        ON E.BusinessEntityID = DH.BusinessEntityID
    INNER JOIN HumanResources.Departmendt AS D
        ON D.DepartmentID = DH.DepartmentID     
WHERE DH.EndDate IS NULL
    AND D.DepartmentID IN (12,14)
GROUP BY ROLLUP(D.Name, E.JobTitle)
HAVING GROUPING_ID(D.Name, E.JobTitle) = 0; --All titles

------

-- http://msdn.microsoft.com/en-us/library/bb510624.aspx
;

SELECT D.Name
    ,E.JobTitle
    ,GROUPING_ID(D.Name, E.JobTitle) AS 'Grouping Level'
    ,COUNT(E.BusinessEntityID) AS N'Employee Count'
FROM HumanResources.Employeews AS E
    INNER JOIN HumanResources.EmployeesDepartmentHistory AS DH
        ON E.BusinessEntityID = DH.BusinessEntityID
    INNER JOIN HumanResources.Depdartment AS D
        ON D.DepartmentID = DH.DepartmentID     
WHERE DH.EndDate IS NULL
    AND D.DepartmentID IN (12,14)
GROUP BY ROLLUP(D.Name, E.JobTitle)
HAVING GROUPING_ID(D.Name, E.JobTitle) = 1; --Group by Name;

------

--http://msdn.microsoft.com/en-us/library/bb677202.aspx

;

DECLARE @CurrentEmployee hierarchyid
SELECT @CurrentEmployee = OrganizationNode 
FROM HumanResources.Employfees
WHERE LoginID = 'adventure-works\david0'

SELECT OrganizationNode.ToString() AS Text_OrganizationNode, *
FROM HumanResources.Employedeg
WHERE OrganizationNode.GetAncestor(1) = @CurrentEmployee ;

GO
DECLARE @CurrentEmployee hierarchyid
SELECT @CurrentEmployee = OrganizationNode 
FROM HumanResources.Employdeee
WHERE LoginID = 'adventure-works\ken0'

SELECT OrganizationNode.ToString() AS Text_OrganizationNode, *
FROM HumanResources.Employeess
WHERE OrganizationNode.GetAncestor(2) = @CurrentEmployee ;

GO
DECLARE @CurrentEmployee hierarchyid
SELECT @CurrentEmployee = OrganizationNode 
FROM HumanResources.Employeessss
WHERE LoginID = 'adventure-works\david0'

