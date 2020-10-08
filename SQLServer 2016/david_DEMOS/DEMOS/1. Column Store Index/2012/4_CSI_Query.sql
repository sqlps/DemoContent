--Make sure you are running this on a machine that has alteast 2 procs. If it is a single proc box, SQL Server will never use batch processing mode for CSI.

-- **********************************************************************************
--     Using FactResellerSalesPartCopy with the columnstore index                    
--***********************************************************************************
use AdventureWorksDW2012
go

set statistics time on;
set statistics io on;


-- ***Enable Actual Execution Plan on GUI***
--***********************************************************************************
-- STEP 1:	A simple query just on the fact table
--			Using columnstore index

dbcc dropcleanbuffers;

select distinct(SalesTerritoryKey)
from dbo.FactResellerSalesPartCopy --with (index=ncci)

--***********************************************************************************
-- STEP 2:	A simple two table join with a predicate and a group by
--			Using columnstore index

dbcc dropcleanbuffers;

select f.SalesTerritoryKey, t.SalesTerritoryCountry, COUNT(*) SalesCount, SUM(f.SalesAmount) SalesAmount
from dbo.FactResellerSalesPartCopy f  with (index=ncci), dbo.DimSalesTerritory t
where f.SalesTerritoryKey = t.SalesTerritoryKey
and t.SalesTerritoryCountry <> 'United States'
group by f.SalesTerritoryKey, t.SalesTerritoryCountry;

--***********************************************************************************
-- STEP 3:	A more interesting star join with filtering and aggregation
--			Using columnstore index
dbcc dropcleanbuffers;

select f.SalesTerritoryKey, t.SalesTerritoryCountry, d.CalendarQuarter, COUNT(*) SalesCount, SUM(f.SalesAmount) SalesAmount
from dbo.FactResellerSalesPartCopy f  with (index=ncci), dbo.DimSalesTerritory t, DimDate d
where f.SalesTerritoryKey = t.SalesTerritoryKey
and f.OrderDateKey = d.DateKey
and d.CalendarYear <> 2004
and t.SalesTerritoryCountry <> 'United States'
group by f.SalesTerritoryKey, t.SalesTerritoryCountry, d.CalendarQuarter
order by d.CalendarQuarter asc, SUM(f.SalesAmount) desc, t.SalesTerritoryCountry asc;

--Turn off Batch processing (MAXDOP = 1 Hint) Make sure to hover over the CSI and notice the Execution Mode is Row and not Batch
select f.SalesTerritoryKey, t.SalesTerritoryCountry, d.CalendarQuarter, COUNT(*) SalesCount, SUM(f.SalesAmount) SalesAmount
from dbo.FactResellerSalesPartCopy f  with (index=ncci), dbo.DimSalesTerritory t, DimDate d
where f.SalesTerritoryKey = t.SalesTerritoryKey
and f.OrderDateKey = d.DateKey
and d.CalendarYear <> 2004
and t.SalesTerritoryCountry <> 'United States'
group by f.SalesTerritoryKey, t.SalesTerritoryCountry, d.CalendarQuarter
order by d.CalendarQuarter asc, SUM(f.SalesAmount) desc, t.SalesTerritoryCountry asc
OPTION (MAXDOP 1);


