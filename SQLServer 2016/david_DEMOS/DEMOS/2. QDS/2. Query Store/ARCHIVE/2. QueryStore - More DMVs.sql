--Reference: https://msdn.microsoft.com/en-us/library/dn817826.aspx

--The following query returns information about queries and plans in the query store.

SELECT Txt.query_text_id, Txt.query_sql_text, Pl.plan_id, Qry.*
FROM sys.query_store_plan AS Pl
JOIN sys.query_store_query AS Qry
    ON Pl.query_id = Qry.query_id
JOIN sys.query_store_query_text AS Txt
    ON Qry.query_text_id = Txt.query_text_id ;

--Option Management

--Is Query Store currently active?

/*Query Store stores its data inside the user database and that is why it has size limit (configured with MAX_STORAGE_SIZE_MB). 
If data in Query Store hits that limit Query Store will automatically change state from read-write to read-only and stop collecting new data.
Query sys.database_query_store_options (Transact-SQL) to determine if Query Store is currently active, and whether it is currently collects runtime 
stats or not.*/

SELECT actual_state, actual_state_desc, readonly_reason, 
current_storage_size_mb, max_storage_size_mb
FROM sys.database_query_store_options;

--Query Store status is determined by actual_state column. If it’s different than the desired status, the readonly_reason column can give you more information. When Query Store size exceeds the quota, the feature will switch to readon_only mode.

--Get Query Store options

--To find out detailed information about Query Store status, execute following in a user database.

SELECT * FROM sys.database_query_store_options;

--Setting Query Store interval

--You can override interval for aggregating query runtime statistics (default is 60 minutes).

ALTER DATABASE <database_name> 
SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 15);

--Note that arbitrary values are not allowed - you should use one of the following: 1, 5, 10, 15, 30, 60, and 1440 minutes.

--Query Store space usage

--To check current the Query Store size and limit execute the following statement in the user database.

SELECT current_storage_size_mb, max_storage_size_mb 
FROM sys.database_query_store_options;

--If the Query Store storage is full use the following statement to extend the storage.

ALTER DATABASE <database_name> 
SET QUERY_STORE (MAX_STORAGE_SIZE_MB = <new_size>);

--Set all Query Store options

--You can set multiple Query Store options at once with a single ALTER DATABASE statement.

ALTER DATABASE <database name> 
SET QUERY_STORE (
    OPERATION_MODE = READ_WRITE,
    CLEANUP_POLICY = 
    (STALE_QUERY_THRESHOLD_DAYS = 30),
    DATA_FLUSH_INTERVAL_SECONDS = 3000,
    MAX_STORAGE_SIZE_MB = 500,
    INTERVAL_LENGTH_MINUTES = 15,
    SIZE_BASED_CLEANUP_MODE = AUTO,
    QUERY_CAPTURE_MODE = AUTO
    MAX_PLANS_PER_QUERY = 1000
);

--Cleaning up the space

--Query Store internal tables are created in the PRIMARY filegroup during database creation and that configuration cannot be changed later. If you are running out of space you might want to clear older Query Store data by using the following statement.

ALTER DATABASE <db_name> SET QUERY_STORE CLEAR;

