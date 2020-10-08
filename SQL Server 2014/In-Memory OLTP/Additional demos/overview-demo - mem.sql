use master
go

-- enable for in-memory OLTP - change file path as needed
ALTER DATABASE imoltp ADD FILEGROUP imoltp_mod 
	CONTAINS MEMORY_OPTIMIZED_DATA
GO
ALTER DATABASE imoltp 
	ADD FILE (name='imoltp_mod', filename='c:\data\imoltp_mod') 
	TO FILEGROUP imoltp_mod 
GO

USE imoltp
go

-- memory-optimized table
CREATE TABLE dbo.T1_inmem (
   c1 int not null primary key 
		nonclustered hash with (bucket_count=20000000),
   c2 int not null index ix_2 nonclustered 
		hash with (bucket_count=20000000),
   c3 datetime2 not null,
   c4 nchar(400)
)
WITH (MEMORY_OPTIMIZED=ON)
GO

CREATE PROCEDURE usp_Insert1MRows
WITH NATIVE_COMPILATION, EXECUTE AS OWNER, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, 
				   LANGUAGE=N'English')

	DECLARE @i int = 0
	WHILE @i < 1000000
	BEGIN
	  INSERT INTO dbo.T1_inmem 
		VALUES (@i, @i/2, GETDATE(), N'my string')
	  SET @i += 1
	END

END
GO

select db_id()
go
-- show generated files

-- show checkpoint files

EXEC usp_Insert1MRows
GO

select count(*) as 'Row count' from dbo.T1_inmem
go

checkpoint
go

delete from dbo.T1_inmem
go


checkpoint
go

checkpoint
go
