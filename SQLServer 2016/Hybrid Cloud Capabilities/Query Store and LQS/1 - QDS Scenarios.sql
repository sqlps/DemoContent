-- ===================================
-- Step 1) Plan Regression
-- ===================================
-- Run Powershell script

-- ======================================
-- Step 2) Detect and fix ad hoc workload
-- ======================================
Use Querystoretest
go

ALTER DATABASE  [QueryStoreTest] SET QUERY_STORE CLEAR;

--Run C:\Demos\SQLServer 2016\Webcast Demos\QueryStoreSimpleDemo.exe
/* (1) Do cardinality analysis when suspect on ad-hoc workloads*/
select count(*) as CountQueryTextRows from sys.query_store_query_text;
select count(*) as CountQueryRows from sys.query_store_query;
select count(distinct query_hash) as CountDifferentQueryRows from  sys.query_store_query;
select count(*) as CountPlanRows from sys.query_store_plan;
select count(distinct query_plan_hash) as  CountDifferentPlanRows from  sys.query_store_plan;

/* (2) Get Compile Vs Execution times: ad-hoc workloads tend to spend lot of time in compilation in (ms)*/
EXEC sp_GetCompilAndExecutionTotalTime

/* (3) See query pattern*/
select top 10 * from sys.query_store_query_text


/* (4) I'm not getting new queries? Look at Query Store parameters - is Query Store in READ_ONLY mode*/
select current_storage_size_mb, max_storage_size_mb, 
*  from sys.database_query_store_options

/* (5) How do we fix this problem?*/

/*At the query level: apply the plan guide for selected query template*/
DECLARE @stmt nvarchar(max);
DECLARE @params nvarchar(max);
EXEC sp_get_query_template 
    N'select * from part p join partdetails pp on p.partid = pp.partid where p.partid = 46911',
    @stmt OUTPUT, 
    @params OUTPUT;

EXEC sp_create_plan_guide 
    N'TemplateGuide1', 
    @stmt, 
    N'TEMPLATE', 
    NULL, 
    @params, 
    N'OPTION(PARAMETERIZATION FORCED)';

-- Stop app
ALTER DATABASE  [QueryStoreTest] SET QUERY_STORE CLEAR;
ALTER DATABASE  [QueryStoreTest] SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);

/*(6) Alternative (at the database level): force parametrization for all queries*/
ALTER DATABASE [QueryStoreTest] SET PARAMETERIZATION  FORCED; 

-- Restart app

-- Redo analysis
select count(*) as CountQueryTextRows from sys.query_store_query_text;
select count(*) as CountQueryRows from sys.query_store_query;
select count(distinct query_hash) as CountDifferentQueryRows from  sys.query_store_query;
select count(*) as CountPlanRows from sys.query_store_plan;
select count(distinct query_plan_hash) as  CountDifferentPlanRows from  sys.query_store_plan;

/* (2) Get Compile Vs Execution times: ad-hoc workloads tend to spend lot of time in compilation in (ms)*/
EXEC sp_GetCompilAndExecutionTotalTime

--At this point we could change to AUTO


/*(7) Reset the DB state*/
ALTER DATABASE [QueryStoreTest] SET PARAMETERIZATION  SIMPLE; 

EXEC sp_control_plan_guide N'DROP', N'TemplateGuide1';

ALTER DATABASE  [QueryStoreTest] SET QUERY_STORE CLEAR;
ALTER DATABASE  [QueryStoreTest] SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);

-- ================================================
-- Step 3) Identify atop resource consuming queries
-- ================================================


--Check Top resource consuming query of Adventureworks2014