-- ===================================
-- Step 1) Create LoadTest Schema
-- ===================================

CREATE SCHEMA [LoadTest]
GO

-- ======================================
-- Step 2) Create LoadTest Login And User
-- ======================================
--Create Role to exec procs
CREATE ROLE db_executor

-- Grant execute rights to the new role
GRANT EXECUTE TO db_executor

--YOU MUST BE IN MASTER FOR THIS STEP.
--Create the login.
CREATE LOGIN LoadTest WITH password='P@ssw0rd';

--Create login in DB
CREATE USER [LoadTest] FOR LOGIN [LoadTest] WITH DEFAULT_SCHEMA=[dbo]
GO

--Add Permissions
exec sp_addrolemember 'db_datareader', 'LoadTest'; 
exec sp_addrolemember 'db_datawriter', 'LoadTest'; 
exec sp_addrolemember 'db_executor', 'LoadTest'; 


-- ===================================
-- Step 3) Create Tables
-- ===================================

If Exists(select t.name from sys.tables t inner join sys.schemas s on t.schema_id = s.schema_id where t.name = 'LoadTable' and s.name = 'LoadTest')
	Drop Table LoadTest.LoadTable
GO

SELECT TOP 2000 
      [Title]
      ,[FirstName]
      ,[MiddleName]
      ,[LastName]
      ,[Suffix]
      ,[PhoneNumber]
      ,[PhoneNumberType]
      ,[EmailAddress]
      ,[EmailPromotion]
      ,[AddressType]
      ,[AddressLine1]
      ,[AddressLine2]
      ,[City]
      ,[StateProvinceName]
      ,[PostalCode]
      ,[CountryRegionName]
Into LoadTest.LoadTable
FROM [Sales].[vIndividualCustomer]
GO

If Exists(select t.name from sys.tables t inner join sys.schemas s on t.schema_id = s.schema_id where t.name = 'LoadTableDest' and s.name = 'LoadTest')
	Drop Table LoadTest.LoadTableDest
GO

CREATE TABLE [LoadTest].[LoadTableDest](
	[Title] [nvarchar](8) NULL,
	[FirstName] [dbo].[Name] NOT NULL,
	[MiddleName] [dbo].[Name] NULL,
	[LastName] [dbo].[Name] NOT NULL,
	[Suffix] [nvarchar](10) NULL,
	[PhoneNumber] [dbo].[Phone] NULL,
	[PhoneNumberType] [dbo].[Name] NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[EmailPromotion] [int] NOT NULL,
	[AddressType] [dbo].[Name] NOT NULL,
	[AddressLine1] [nvarchar](60) NOT NULL,
	[AddressLine2] [nvarchar](60) NULL,
	[City] [nvarchar](30) NOT NULL,
	[StateProvinceName] [dbo].[Name] NOT NULL,
	[PostalCode] [nvarchar](15) NOT NULL,
	[CountryRegionName] [dbo].[Name] NOT NULL
)
GO

-- ======================================
-- Step 4) Add Procs
-- ======================================

--Proc used to setup collection table
If Exists(select p.name from sys.procedures p inner join sys.schemas s on p.schema_id = s.schema_id where p.name = 'usp_ResetTables' and s.name = 'LoadTest')
	Drop Procedure LoadTest.[usp_ResetTables]
GO

CREATE Procedure [LoadTest].[usp_ResetTables]
AS

If Exists(select t.name from sys.tables t inner join sys.schemas s on t.schema_id = s.schema_id where t.name = 'Results' and s.name = 'LoadTest')
	Drop Table LoadTest.Results

CREATE TABLE [LoadTest].[Results](
		[TestScenario] [nvarchar](50) NOT NULL,
		[TimeStamp] [datetime] NOT NULL,
		[RunNumber] [int] identity(1,1),
		[RowCount] [int] 
	)
CREATE Clustered INDEX IX_CI_LoadTest ON LoadTest.Results
    (RunNumber)
If Exists(select t.name from sys.tables t inner join sys.schemas s on t.schema_id = s.schema_id where t.name = 'LoadTableDest' and s.name = 'LoadTest')
	Drop Table LoadTest.LoadTableDest

CREATE TABLE [LoadTest].[LoadTableDest](
	[Title] [nvarchar](8) NULL,
	[FirstName] [dbo].[Name] NOT NULL,
	[MiddleName] [dbo].[Name] NULL,
	[LastName] [dbo].[Name] NOT NULL,
	[Suffix] [nvarchar](10) NULL,
	[PhoneNumber] [dbo].[Phone] NULL,
	[PhoneNumberType] [dbo].[Name] NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[EmailPromotion] [int] NOT NULL,
	[AddressType] [dbo].[Name] NOT NULL,
	[AddressLine1] [nvarchar](60) NOT NULL,
	[AddressLine2] [nvarchar](60) NULL,
	[City] [nvarchar](30) NOT NULL,
	[StateProvinceName] [dbo].[Name] NOT NULL,
	[PostalCode] [nvarchar](15) NOT NULL,
	[CountryRegionName] [dbo].[Name] NOT NULL
)
Create Clustered Index IX_LoadTest_LoadTableDest
On LoadTest.LoadTableDest (FirstName,LastName)
GO




--Proc used to record results
If Exists(select p.name from sys.procedures p inner join sys.schemas s on p.schema_id = s.schema_id where p.name = 'usp_InsertResults' and s.name = 'LoadTest')
	Drop Procedure LoadTest.[usp_InsertResults]
GO

CREATE Procedure [LoadTest].[usp_InsertResults]
	@TestScenario nvarchar(50),
	@RowCount int = 1
AS

Declare @TimeStamp datetime

Set @TimeStamp = GetDate()
Insert LoadTest.Results(TestScenario,[TimeStamp],[RowCount])
Values(@TestScenario, @TimeStamp, @RowCount)
GO

--Proc used to pull performance data consumed by PowerBI
If Exists(select p.name from sys.procedures p inner join sys.schemas s on p.schema_id = s.schema_id where p.name = 'usp_GetPerfMetrics' and s.name = 'LoadTest')
	Drop Procedure LoadTest.[usp_GetPerfMetrics]
GO

CREATE Procedure [LoadTest].[usp_GetPerfMetrics]
	@TestScenarioFilter nvarchar(50)
As

Declare @TestScenario nvarchar(50),
		@CurrentExecutionCount int,
		@CollectionTime DateTime,
		@BatchRequests int,
		@connections int,
		@ResourceStatsTime DateTime2,
		@avg_cpu_percent decimal(5,2),
		@avg_data_io_percent decimal(5,2),
		@avg_log_write_percent decimal(5,2),
		@avg_memory_usage_percent decimal(5,2),
		@runtime int,
		@RunMessage varchar(4000)

Set @CollectionTime = GetDate()
-- ===================================
-- Get the current executions
-- ===================================

select @CurrentExecutionCount = Sum([RowCount]), @TestScenario = TestScenario 
from LoadTest.Results
where TestScenario = @TestScenarioFilter
Group By TestScenario

-- ==========================================
-- Get Batch Requests/sec
-- NOTE: Does not work on pre-v12 Azure SQLDB
-- ==========================================

--See: http://blogs.msdn.com/b/psssql/archive/2013/09/23/interpreting-the-counter-values-from-sys-dm-os-performance-counters.aspx for translation
Declare @Value1 bigint,
		@Value2 bigint

select @Value1 = cntr_value from sys.dm_os_performance_counters where counter_name = 'Batch Requests/sec'
WaitFor Delay '00:00:01'
select @Value2 = cntr_value from sys.dm_os_performance_counters where counter_name = 'Batch Requests/sec'
select @BatchRequests = (@Value2 - @Value1)

-- ===================================
-- Get connections
-- ===================================
SELECT
      @connections = count(s.session_id)
FROM
      sys.dm_exec_sessions s
      INNER JOIN sys.dm_exec_connections e
      ON s.session_id = e.session_id

-- ===================================
-- Get Resource Usage
-- ===================================
;With RingBuffer
As (Select CONVERT(xml, record) AS [record] 
      From sys.dm_os_ring_buffers 
      Where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
      And record Like  N'%<SystemHealth>%')
Select Top (1)
      @avg_cpu_percent = record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int')
From RingBuffer
Order By record.value('(./Record/@id)[1]', 'int')  Desc;


DECLARE @SQLRestartDateTime Datetime,
		@TimeInSeconds Float,
		@Data_IOPs decimal (5,2),
		@Log_IOPs decimal (5,2),
		@Memory_MB bigint

		 
SELECT @SQLRestartDateTime = create_date FROM sys.databases WHERE database_id = 2
SET @TimeInSeconds = Datediff(s,@SQLRestartDateTime,GetDate())

SELECT @Data_IOPs =  ROUND((num_of_reads + num_of_writes)/@TimeInSeconds,4)
FROM sys.dm_io_virtual_file_stats(db_id('Adventureworks2014_OnPrem'),null) IVFS
JOIN sys.master_files MF ON IVFS.database_id = MF.database_id AND IVFS.file_id = MF.file_id
Where MF.type_desc ='ROWS'   

SELECT @Log_IOPs =  ROUND((num_of_reads + num_of_writes)/@TimeInSeconds,4)
FROM sys.dm_io_virtual_file_stats(db_id('Adventureworks2014_OnPrem'),null) IVFS
JOIN sys.master_files MF ON IVFS.database_id = MF.database_id AND IVFS.file_id = MF.file_id
Where MF.type_desc ='Log'


SELECT @Memory_MB = (count(*)*8)/1024
FROM sys.dm_os_buffer_descriptors
where db_name(database_id) = 'Adventureworks2014_OnPrem'
GROUP BY db_name(database_id) ,database_id


-- ===================================
-- Get Run Time
-- ===================================
Select @runtime = datediff(ss,min(TimeStamp),max(TimeStamp))
From LoadTest.Results
If ((select count(session_id) from sys.dm_exec_sessions where program_name = 'OSTRESS') > 0)
	SET @RunMessage = 'Running for '+RIGHT(CONVERT(CHAR(8),DATEADD(second,@runTime,0),108),5)+' (MM:SS)'
Else
	SET @RunMessage = 'Completed. Ran for '+RIGHT(CONVERT(CHAR(8),DATEADD(second,@runTime,0),108),5)+' (MM:SS)'

-- ===================================
-- Send Results back to be displayed
-- ===================================

Select @TestScenario As 'TestScenario', @CollectionTime As 'CollectionTime' , @CurrentExecutionCount As 'CurrentExecutionCount' ,  @BatchRequests As 'Batch_Requests_per_sec' , @connections As 'Connections' ,
		@CollectionTime as 'dm_db_resource_stats__end_time' , @avg_cpu_percent as 'Avg_cpu_percent' , @Data_IOPs as 'Avg_data_io_percent' , 
		@Log_IOPs as 'Avg_log_write_percent' , @Memory_MB as 'Avg_memory_usage_percent', @RunMessage as 'RunMessage'


--Proc used to generate ReadWorkload

If Exists(select p.name from sys.procedures p inner join sys.schemas s on p.schema_id = s.schema_id where p.name = 'usp_ReadWorkLoad' and s.name = 'LoadTest')
	Drop Procedure LoadTest.[usp_ReadWorkLoad]
GO

CREATE Procedure [LoadTest].[usp_ReadWorkLoad]
	@Scenario nvarchar(50) 
AS

SELECT SalesQuota, SUM(SalesYTD) 'TotalSalesYTD', GROUPING(SalesQuota) AS 'Grouping'
FROM Sales.SalesPerson
GROUP BY SalesQuota WITH ROLLUP;
exec LoadTest.usp_InsertResults @Scenario

SELECT D.Name
    ,CASE 
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 0 THEN E.JobTitle
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 1 THEN N'Total: ' + D.Name 
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 3 THEN N'Company Total:'
        ELSE N'Unknown'
    END AS N'Job Title'
    ,COUNT(E.BusinessEntityID) AS N'Employee Count'
FROM HumanResources.Employee E
    INNER JOIN HumanResources.EmployeeDepartmentHistory DH
        ON E.BusinessEntityID = DH.BusinessEntityID
    INNER JOIN HumanResources.Department D
        ON D.DepartmentID = DH.DepartmentID     
WHERE DH.EndDate IS NULL
    AND D.DepartmentID IN (12,14)
GROUP BY ROLLUP(D.Name, E.JobTitle);
exec LoadTest.usp_InsertResults @Scenario

SELECT D.Name
    ,E.JobTitle
    ,GROUPING_ID(D.Name, E.JobTitle) AS 'Grouping Level'
    ,COUNT(E.BusinessEntityID) AS N'Employee Count'
FROM HumanResources.Employee AS E
    INNER JOIN HumanResources.EmployeeDepartmentHistory AS DH
        ON E.BusinessEntityID = DH.BusinessEntityID
    INNER JOIN HumanResources.Department AS D
        ON D.DepartmentID = DH.DepartmentID     
WHERE DH.EndDate IS NULL
    AND D.DepartmentID IN (12,14)
GROUP BY ROLLUP(D.Name, E.JobTitle)
HAVING GROUPING_ID(D.Name, E.JobTitle) = 0; --All titles
exec LoadTest.usp_InsertResults @Scenario

SELECT D.Name
    ,E.JobTitle
    ,GROUPING_ID(D.Name, E.JobTitle) AS 'Grouping Level'
    ,COUNT(E.BusinessEntityID) AS N'Employee Count'
FROM HumanResources.Employee AS E
    INNER JOIN HumanResources.EmployeeDepartmentHistory AS DH
        ON E.BusinessEntityID = DH.BusinessEntityID
    INNER JOIN HumanResources.Department AS D
        ON D.DepartmentID = DH.DepartmentID     
WHERE DH.EndDate IS NULL
    AND D.DepartmentID IN (12,14)
GROUP BY ROLLUP(D.Name, E.JobTitle)
HAVING GROUPING_ID(D.Name, E.JobTitle) = 1; --Group by Name;
exec LoadTest.usp_InsertResults @Scenario


DECLARE @CurrentEmployee hierarchyid
SELECT @CurrentEmployee = OrganizationNode 
FROM HumanResources.Employee
WHERE LoginID = 'adventure-works\david0'
exec LoadTest.usp_InsertResults @Scenario

SELECT OrganizationNode.ToString() AS Text_OrganizationNode, *
FROM HumanResources.Employee
WHERE OrganizationNode.GetAncestor(1) = @CurrentEmployee ;
exec LoadTest.usp_InsertResults @Scenario

SELECT @CurrentEmployee = OrganizationNode 
FROM HumanResources.Employee
WHERE LoginID = 'adventure-works\david0'
exec LoadTest.usp_InsertResults @Scenario

SELECT OrganizationNode.ToString() AS Text_OrganizationNode, *
FROM HumanResources.Employee
WHERE OrganizationNode.GetAncestor(0) = @CurrentEmployee ;
exec LoadTest.usp_InsertResults @Scenario

DECLARE @TargetEmployee hierarchyid ;
SELECT @CurrentEmployee = '/2/3/1.2/5/3/' ;
SELECT @TargetEmployee = @CurrentEmployee.GetAncestor(2) ;
SELECT @TargetEmployee.ToString(), @TargetEmployee ;


SELECT CustomerID, OrderDate, SubTotal, TotalDue
FROM Sales.SalesOrderHeader
WHERE SalesPersonID = 35
ORDER BY OrderDate 
--,--COMPUTE SUM(SubTotal), SUM(TotalDue);
exec LoadTest.usp_InsertResults @Scenario




SELECT SalesPersonID, CustomerID, OrderDate, SubTotal, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY SalesPersonID, OrderDate 
----COMPUTE SUM(SubTotal), SUM(TotalDue) BY SalesPersonID;
exec LoadTest.usp_InsertResults @Scenario

SELECT *
FROM Production.Product
ORDER BY Name ASC;
-- Alternate way.
exec LoadTest.usp_InsertResults @Scenario

SELECT p.*
FROM Production.Product AS p
ORDER BY Name ASC;
exec LoadTest.usp_InsertResults @Scenario

/*
This example returns all rows (no WHERE clause is specified), and 
only a subset of the columns (Name, ProductNumber, ListPrice) from 
the Product table in the AdventureWorks2012 database. Additionally, 
a column heading is added.
*/



SELECT Name, ProductNumber, ListPrice AS Price
FROM Production.Product 
ORDER BY Name ASC;
exec LoadTest.usp_InsertResults @Scenario


/*
This example returns only the rows for Product that have a product 
line of R and that have days to manufacture that is less than 4.
*/



SELECT Name, ProductNumber, ListPrice AS Price
FROM Production.Product 
WHERE ProductLine = 'R' 
AND DaysToManufacture < 4
ORDER BY Name ASC;
exec LoadTest.usp_InsertResults @Scenario
/*
This is the query that calculates the revenue for each product in 
each sales order.
*/







SELECT DISTINCT JobTitle
FROM HumanResources.Employee
ORDER BY JobTitle;
exec LoadTest.usp_InsertResults @Scenario

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
D. Creating tables with SELECT INTO 
The following first example creates a temporary table named 
#Bicycles in tempdb. 
*/


/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
  E. Using correlated subqueries 
The following example shows queries that are semantically 
equivalent and illustrates the difference between using the 
EXISTS keyword and the IN keyword. Both are examples of a 
valid subquery that retrieves one instance of each product 
name for which the product model is a long sleeve lo jersey, 
and the ProductModelID numbers match between the Product and 
ProductModel tables.
*/



SELECT DISTINCT Name
FROM Production.Product AS p 
WHERE EXISTS
    (SELECT *
     FROM Production.ProductModel AS pm 
     WHERE p.ProductModelID = pm.ProductModelID
           AND pm.Name LIKE 'Long-Sleeve Lo Jersey%');
		   exec LoadTest.usp_InsertResults @Scenario

-- OR



SELECT DISTINCT Name
FROM Production.Product
WHERE ProductModelID IN
    (SELECT ProductModelID 
     FROM Production.ProductModel
     WHERE Name LIKE 'Long-Sleeve Lo Jersey%');

	 exec LoadTest.usp_InsertResults @Scenario
/*
The following example uses IN in a correlated, or repeating, 
subquery. This is a query that depends on the outer query for 
its values. The query is executed repeatedly, one time for each 
row that may be selected by the outer query. This query 
retrieves one instance of the first and last name of each 
employee for which the bonus in the SalesPerson table is 5000.00 
and for which the employee identification numbers match in the 
Employee and SalesPerson tables.
*/



SELECT DISTINCT p.LastName, p.FirstName 
FROM Person.Person AS p 
JOIN HumanResources.Employee AS e
    ON e.BusinessEntityID = p.BusinessEntityID WHERE 5000.00 IN
    (SELECT Bonus
     FROM Sales.SalesPerson AS sp
     WHERE e.BusinessEntityID = sp.BusinessEntityID);

	 exec LoadTest.usp_InsertResults @Scenario
/*
The previous subquery in this statement cannot be evaluated 
independently of the outer query. It requires a value for 
Employee.BusinessEntityID, but this value changes as the SQL 
Server Database Engine examines different rows in Employee.

A correlated subquery can also be used in the HAVING clause of 
an outer query. This example finds the product models for which 
the maximum list price is more than twice the average for the 
model.
*/



SELECT p1.ProductModelID
FROM Production.Product AS p1
GROUP BY p1.ProductModelID
HAVING MAX(p1.ListPrice) >= ALL
    (SELECT AVG(p2.ListPrice)
     FROM Production.Product AS p2
     WHERE p1.ProductModelID = p2.ProductModelID);
	 exec LoadTest.usp_InsertResults @Scenario

/*
This example uses two correlated subqueries to find the names 
of employees who have sold a particular product.
*/



SELECT DISTINCT pp.LastName, pp.FirstName 
FROM Person.Person pp JOIN HumanResources.Employee e
ON e.BusinessEntityID = pp.BusinessEntityID WHERE pp.BusinessEntityID IN 
(SELECT SalesPersonID 
FROM Sales.SalesOrderHeader
WHERE SalesOrderID IN 
(SELECT SalesOrderID 
FROM Sales.SalesOrderDetail
WHERE ProductID IN 
(SELECT ProductID 
FROM Production.Product p 
WHERE ProductNumber = 'BK-M68B-42')));
exec LoadTest.usp_InsertResults @Scenario

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
F. Using GROUP BY 
The following example finds the total of each sales order in 
the database.
*/



SELECT SalesOrderID, SUM(LineTotal) AS SubTotal
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
ORDER BY SalesOrderID;

exec LoadTest.usp_InsertResults @Scenario
------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
Because of the GROUP BY clause, only one row containing the sum of all 
sales is returned for each sales order.

G. Using GROUP BY with multiple groups 
The following example finds the average price and the sum of 
year-to-date sales, grouped by product ID and special offer ID.
*/



SELECT ProductID, SpecialOfferID, AVG(UnitPrice) AS 'Average Price', 
    SUM(LineTotal) AS SubTotal
FROM Sales.SalesOrderDetail
GROUP BY ProductID, SpecialOfferID
ORDER BY ProductID;
exec LoadTest.usp_InsertResults @Scenario

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
  H. Using GROUP BY and WHERE 
The following example puts the results into groups after retrieving 
only the rows with list prices greater than $1000.
*/



SELECT ProductModelID, AVG(ListPrice) AS 'Average List Price'
FROM Production.Product
WHERE ListPrice > $1000
GROUP BY ProductModelID
ORDER BY ProductModelID;
exec LoadTest.usp_InsertResults @Scenario

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
I. Using GROUP BY with an expression 
The following example groups by an expression. You can group 
by an expression if the expression does not include aggregate 
functions.
*/



SELECT AVG(OrderQty) AS 'Average Quantity', 
NonDiscountSales = (OrderQty * UnitPrice)
FROM Sales.SalesOrderDetail
GROUP BY (OrderQty * UnitPrice)
ORDER BY (OrderQty * UnitPrice) DESC;
exec LoadTest.usp_InsertResults @Scenario

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
J. Using GROUP BY with ORDER BY 
The following example finds the average price of each type of 
product and orders the results by average price.
*/



SELECT ProductID, AVG(UnitPrice) AS 'Average Price'
FROM Sales.SalesOrderDetail
WHERE OrderQty > 10
GROUP BY ProductID
ORDER BY AVG(UnitPrice);
exec LoadTest.usp_InsertResults @Scenario

------

/* http://msdn.microsoft.com/en-us/library/ms187731.aspx
K. Using the HAVING clause 
The first example that follows shows a HAVING clause with an 
aggregate function. It groups the rows in the SalesOrderDetail 
table by product ID and eliminates products whose average order 
quantities are five or less. The second example shows a HAVING 
clause without aggregate functions. 
*/

GO

--Proc used to generate Insert Workload
If Exists(select p.name from sys.procedures p inner join sys.schemas s on p.schema_id = s.schema_id where p.name = 'usp_InsertWorkload' and s.name = 'LoadTest')
	Drop Procedure [LoadTest].usp_InsertWorkload
go

CREATE Procedure [LoadTest].usp_InsertWorkload
	@Scenario nvarchar(50) 
AS

	insert into LoadTest.LoadTableDest
	select * from LoadTest.LoadTable

	exec LoadTest.usp_InsertResults @Scenario, 2000
GO