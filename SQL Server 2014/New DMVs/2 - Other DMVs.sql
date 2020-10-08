-- From http://www.mssqltips.com/sqlservertip/3111/new-sql-server-2014-dynamic-management-views

-- Management data about buffer pool extensions, storing the buffer pool on SSD.
Select * from sys.dm_os_buffer_pool_extension_configuration 


select * from sys.dm_resource_governor_resource_pool_volumes


--lots of DMVs for XTP
Select * from sys.sysobjects where name like '%_xtp%' and xtype = 'V'