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

DBCC FREEPROCCACHE

Use AdventureWorksDW2012
Go
--Show the last date is 20080831
Select Max(DateKey) From FactCurrencyRate


--Insert 10 Records outside the histogram
Insert Into FactCurrencyRate Values(3,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(9,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(2,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(1,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(4,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(13,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(11,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(12,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(14,20101201,1,1,'2010-12-01 00:00:00.000')
Insert Into FactCurrencyRate Values(30,20101201,1,1,'2010-12-01 00:00:00.000')

--Lets see the histogram
DBCC Show_Statistics (FactCurrencyRate,'_WA_Sys_00000005_108B795B')

Set Statistics Profile ON
GO

--See estimate with old CE
--Bad estimate could be detremiental if it chose a nested loop when it estimates 1 row.
Select * from FactCurrencyRate where datekey = 20101201
option (querytraceon 9481)

-- And the new CE
ALTER DATABASE [AdventureworksDW2012] SET COMPATIBILITY_LEVEL = 120
GO
Select * from FactCurrencyRate where datekey = 20101201

--Optionally show Xevents