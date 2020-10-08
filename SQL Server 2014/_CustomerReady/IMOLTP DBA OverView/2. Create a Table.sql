/* This Sample Code is provided for the purpose of illustration only and is not intended
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys fees, that arise or
result from the use or distribution of the Sample Code.*/

/******************
 * TALKING POINTS *
 ******************
 1) Requires at least one index with a max of 8, for durable tables it must have a PK
 2) The Hash index is the primary index form you should use for Memory Optimized Tables. 
    Hash indexes work different from regular indexes, in several ways: 
		a) The Hash index is created on the sum of the data in the index, if two or more columns are included in the Index, 
		   all values must be included in the SARGable query for the index to be usable, and “LIKE ‘name%’” wont use a hash index.
		b) Hash indexes point to the initial record that evaluates to the Bucket, that record then points to the next entry in the chain, etc.
 3) Multiple Hash indexes can be specified.
 4) Memory Optimized Tables do not support Clustered indexes.
 5) When a Hash index is defined, you define the size of the index – the Bucket Count. 
    The bucket count is always rounded up the next power of 2 – BUCKET_COUNT = 30000 actually creates a Index with 32768 buckets. 
	A Hash index should be sized with a Bucket Count greater than the expected cardinality of the index fields. 
	Ex: An integer field with expected values of 1 – 100, the bucket count should be 128.
 6) In most cases the bucket count should be between 1 and 2 times the number of distinct values in the index key. 
    If the index key contains a lot of duplicate values, on average there are more than 10 rows for each index key value, use a nonclustered index instead 
 7) Creating a table will create a DLL that includes the functions for accessing indexes and retrieving data from the table 
 8) Collation consideration: Te dependency on the collation really comes down to the fact that In-Memory OLTP table indexes must have a *_BIN2 collation 
    if you were attempting to create an index on a character column. If there was no indexes on character columns you’d not have any issues and if you did 
	have a character column you would have to create the column in the table definition with the right collation.*/


-- Step 1) Create the Table
Use IMOLTP_Demo
GO

If Exists (Select Name from sys.sysobjects where name = 'IMOLTP_Tbl1' and type = 'U')
BEGIN
	DROP PROCEDURE InsertRecords
	Drop Table IMOLTP_Tbl1
END

CREATE TABLE IMOLTP_Tbl1 ( 
    CustomerNo    INT NOT NULL IDENTITY(1,1) PRIMARY KEY --4bytes
               NONCLUSTERED HASH WITH (BUCKET_COUNT = 1000000), 
			   -- Hash Index Need to round up to a ^2 = 2^20 = 1048576. Size = 1048576*8bytes = 8MB
	CustomerSeq int NULL,
    Firstname   Char(50) NOT NULL, 
    Lastname    CHAR(50) NOT NULL, 
	Email	    CHAR(100) NOT NULL, 
    OrderDate   DATETIME    NOT NULL --8 bytes
	Index ix_OrderDate NonClustered)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

Select OBJECT_ID('IMOLTP_Tbl1')
--Go to D:\SQL\MSSQL11.MSSQLSERVER\MSSQL\DATA\xtp
GO


--Check Sizing of Hash Bucket and Memory allocated
Select * from sys.dm_db_xtp_hash_index_stats -- This DMV is very useful to deal with Hash indexes. You can determine if a Hash index is low on buckets or has many duplicate keys.  This was introduced in my previous tip "Considerations on BUCKET_COUNT on hash indexes for Memory-Optimized tables". 
Select * from sys.dm_db_xtp_table_memory_stats -- Shows allocated and used memory of user and system tables. 

CREATE TABLE IMOL_Tbl2 ( 
    IDX_Col    INT NOT NULL PRIMARY KEY 
               NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000), 
	id_num int IDENTITY(10,1),
    CharCol1   VARCHAR(32) NULL, 
    Name       VARCHAR(32) NULL, 
    Mod_Date   DATETIME    NOT NULL, ) 
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

GO

-- Step 2) View the table dlls

-- Browse to F:\DATA\xtp

Select * from sys.dm_os_loaded_modules
where name like 'F:\Data\xtp%'
