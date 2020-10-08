
-- **********************************************************************************
--     Using FactResellerSalesPartCopy without the columnstore index                    
--***********************************************************************************
use AdventureWorksDW2012
go

set statistics time on;
set statistics io on;

-- ***Enable Actual Execution Plan on GUI***

--***********************************************************************************
-- STEP 1:	A simple query just on the fact table
--			Using NO columnstore index 

--			should take approximately 24 secs

dbcc dropcleanbuffers;

select distinct(SalesTerritoryKey)
from dbo.FactResellerSalesPartCopy with (index=CI_FactReseller) --Force the clustered index

--***********************************************************************************
-- STEP 2:	A simple two table join with a predicate and a group by
--			Using NO columnstore index  
--
--			should take about 17 sec

dbcc dropcleanbuffers;

select f.SalesTerritoryKey, t.SalesTerritoryCountry, COUNT(*) SalesCount, SUM(f.SalesAmount) SalesAmount
from dbo.FactResellerSalesPartCopy f with (index=CI_FactReseller), dbo.DimSalesTerritory t
where f.SalesTerritoryKey = t.SalesTerritoryKey
and t.SalesTerritoryCountry <> 'United States'
group by f.SalesTerritoryKey, t.SalesTerritoryCountry;

--***********************************************************************************
-- STEP 3:	A more interesting star join with filtering and aggregation
--			Using NO columnstore index
--			
--			should take about 26 sec

dbcc dropcleanbuffers;

select f.SalesTerritoryKey, t.SalesTerritoryCountry, d.CalendarQuarter, COUNT(*) SalesCount, SUM(f.SalesAmount) SalesAmount
from dbo.FactResellerSalesPartCopy f  with (index=CI_FactReseller), dbo.DimSalesTerritory t, DimDate d
where f.SalesTerritoryKey = t.SalesTerritoryKey
and f.OrderDateKey = d.DateKey
and d.CalendarYear <>2004
and t.SalesTerritoryCountry <> 'United States'
group by f.SalesTerritoryKey, t.SalesTerritoryCountry, d.CalendarQuarter
order by d.CalendarQuarter asc, SUM(f.SalesAmount) desc, t.SalesTerritoryCountry asc;

