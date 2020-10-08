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
Select * from FactCurrencyRate where datekey = 20101201

--Cleanup
Delete from FactCurrencyRate
where DateKey  = 20101201