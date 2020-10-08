Select * from sys.dm_db_xtp_hash_index_stats -- This DMV is very useful to deal with Hash indexes. You can determine if a Hash index is low on buckets or has many duplicate keys.  This was introduced in my previous tip "Considerations on BUCKET_COUNT on hash indexes for Memory-Optimized tables". 
Select * from sys.dm_db_xtp_table_memory_stats -- Shows allocated and used memory of user and system tables. 
Select * from sys.dm_db_xtp_object_stats -- Reports row insert, update and delete attempts in Memory-Optimized tables 
Select * from sys.dm_xtp_transaction_stats -- Reports statistics about transactions that have run since the server started. 


--------------
--References--
--------------
-- http://technet.microsoft.com/en-us/library/dn133203.aspx
-- http://www.mssqltips.com/sqlservertip/3111/new-sql-server-2014-dynamic-management-views

Select * from sys.dm_db_xtp_checkpoint_stats -- Shows Checkpoint statistics of the current database. 
Select * from sys.dm_db_xtp_checkpoint_files -- This DMV shows information about checkpoint files, like the type of file (DATA or DELTA files) its size and relative path. 
Select * from sys.dm_db_xtp_gc_cycle_stats -- Shows garbage collection cycles for the current database. 
Select * from sys.dm_db_xtp_hash_index_stats -- This DMV is very useful to deal with Hash indexes. You can determine if a Hash index is low on buckets or has many duplicate keys.  This was introduced in my previous tip "Considerations on BUCKET_COUNT on hash indexes for Memory-Optimized tables". 
Select * from sys.dm_db_xtp_index_stats  -- This DMV contains statistics about Hash and Range indexes collected since the last database restart. It is the Memory-Optimized tables equivalent to sys.dm_db_index_usage_stats. 
Select * from sys.dm_db_xtp_memory_consumers -- This DMV reports stats for memory consumers of the current database. The view returns a row for each memory consumer that the database engine uses. 
Select * from sys.dm_db_xtp_merge_requests -- Use this DMV to view status of data and delta files merge operations both SQL Server and user generated. 
Select * from sys.dm_db_xtp_nonclustered_index_stats -- Displays statistics of Range Indexes in Memory-Optimized Tables. 
Select * from sys.dm_db_xtp_object_stats -- Reports row insert, update and delete attempts in Memory-Optimized tables 
Select * from sys.dm_db_xtp_table_memory_stats -- Shows allocated and used memory of user and system tables. 
Select * from sys.dm_db_xtp_transactions -- Displays information about current transactions on the In-Memory OLTP database engine. 
Select * from sys.dm_xtp_gc_stats -- Gives information about the garbage-collection (GC) process on Memory-Optimized Tables. 
Select * from sys.dm_xtp_gc_queue_stats -- Outputs information about each GC worker queue on the server, and various statistics about each. There is one queue per core. 
Select * from sys.dm_xtp_system_memory_consumers -- Reports system level memory consumers for In-Memory OLTP. 
Select * from sys.dm_xtp_transaction_stats -- Reports statistics about transactions that have run since the server started. 

Select * from sys.indexes
where object_id = object_id('IMOL_Tbl1')



