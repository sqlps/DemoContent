/*
Do not change the database path or name variables.
It will be properly coded for build and deployment
This is using sqlcmd variable substitution
*/
ALTER DATABASE [$(DatabaseName)]
	ADD FILEGROUP [HekatonFilegroup] CONTAINS MEMORY_OPTIMIZED_DATA
GO

/*
The database must have a MEMORY_OPTIMIZED_DATA filegroup
before the memory optimized table can be created.
*/

/*
The bucket count should be set to about two times the 
maximum expected number of distinct values in the 
index key, rounded up to the nearest power of two.
*/
CREATE TABLE [dbo].Value
(
	[Id] INT NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 500000),
	[Value] NVARCHAR (50) NOT NULL,
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)
GO

