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

--REQUIRES SQL Server 2014

--Setup output to show statistics
--Enable graphical execution plan also show CardinalityEstimationModelVersion between runs from XML version of Execution plan
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



Select * into MyDemoDB..Cars From MyDemoDB_Original..Cars