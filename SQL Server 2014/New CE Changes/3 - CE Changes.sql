--Setup output to show statistics
--Enable graphical execition plan also show CardinalityEstimationModelVersion between runs from XML version of Execution plan
Set Statistics profile ON
GO
Use MyDemoDB
Go

--Table Cars has 1000 Rows. 200 Hondas and 50 Civics

-- Step 1) Run with Old CE
ALTER DATABASE [MyDemoDB] SET COMPATIBILITY_LEVEL = 110
GO
Select * from Cars Where Make = 'Honda' and Model = 'Civic'
--OLD CE treats predicates independantly. To get Estimates Rows = 0.05 * 0.2 * 1000 = 10

-- Step 2) Run with New CE
ALTER DATABASE [MyDemoDB] SET COMPATIBILITY_LEVEL = 120
GO
Select * from Cars Where Make = 'Honda' and Model = 'Civic'

--Alternatively we could use TF2312 to enable new CE or 9481 for old CE
ALTER DATABASE [MyDemoDB] SET COMPATIBILITY_LEVEL = 110
GO
Select * from Cars Where Make = 'Honda' and Model = 'Civic'
OPTION (QUERYTRACEON 2312)
--NEW CE treats predicates assumes that the predicates are related. To get Estimates Rows = 0.05 * sqrt(0.2) * 1000 = 22.36. If there was a 3rd predicate it would be sqrt(sqrt(predicate))



