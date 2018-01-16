-- =============================================
-- Step 1) Check current stock price and history
-- =============================================
use TradingSystemv2
Go

--Current
select * from v_CustomerPortfolio
where customernumber = 10
order by 1

-- 4 years ago
select * from v_CustomerPortfolio
For System_time as of '2012-09-10 00:00:00'
--For System_time between  '2016-05-20 00:00:00'and '2016-05-25 00:00:00'
where customernumber = 10 and symbol = 'MSFT'
order by 1
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
