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

-- =============================================
-- Step 0) Establish the relationship for existing tables
-- =============================================
Use TradingSystem
GO

-- ALTER TABLE Portfolio  ADD  PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
-- ALTER TABLE dbo.Portfolio SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Portfolio_History))
GO
-- =============================================
-- Step 1) Check current stock price and history
-- =============================================

--Current
select * from v_CustomerPortfolio
where customernumber = 10
order by 1

-- Go back in time
select * from v_CustomerPortfolio
For System_time as of '2013-04-22 00:00:00'
--For System_time between  '2013-04-20 00:00:00'and '2016-05-25 00:00:00'
where customernumber = 10 
order by 1

-- without view
SELECT *
FROM(
select c.customernumber, FirstName, middlename, LastName, SSN, P.symbol, quantity, price,p.sysstarttime, p.sysendtime, (price*quantity) as 'Value' 
from customers c
inner join portfolio  For System_time as of '2013-04-22 00:00:00' p
on c.customernumber = p.customernumber
inner join stockprices
FOR SYSTEM_TIME AS OF '2013-04-22 00:00:00' s 
on s.symbol = p.symbol 
where c.customernumber = 10 
) a


 --- 

-- What was the price of a stock during for last 2 weeks
-- From: https://msdn.microsoft.com/en-us/library/dn935015.aspx
--Rows that became active exactly on the lower boundary defined by the FROM endpoint are included 
--and records that became active exactly on the upper boundary defined by the TO endpoint are not included.
select * from stockprices
FOR SYSTEM_TIME FROM '2016-05-21 00:00:00' TO '2016-06-06 00:00:00'
where symbol = 'MSFT'

--rows returned includes rows that became active on the upper boundary defined by the <end_date_time> endpoint.
select * from stockprices
FOR SYSTEM_TIME BETWEEN '2016-05-21 00:00:00' AND '2016-06-06 00:00:00'
where symbol = 'MSFT'

--value of my portfolio over time
SELECT a.Firstname, a.lastname, Sum(a.quantity*a.Price) 'Portfolio Value', SysStartTime
FROM(
select c.customernumber, FirstName, middlename, LastName, SSN, P.symbol, quantity, price,s.sysstarttime, s.sysendtime, (price*quantity) as 'Value' 
from customers c
inner join portfolio  For System_time BETWEEN '2016-05-21 00:00:00' AND '2016-06-06 00:00:00' p
on c.customernumber = p.customernumber
inner join stockprices
FOR SYSTEM_TIME BETWEEN '2016-05-21 00:00:00' AND '2016-06-06 00:00:00' s 
on s.symbol = p.symbol 
where c.customernumber = 10 
) a
group by a.Firstname, a.lastname,SysStartTime
order by 4