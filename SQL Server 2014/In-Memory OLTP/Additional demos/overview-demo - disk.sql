use master
go
IF DB_ID('imoltp') is not null
BEGIN
	alter database imoltp set single_user with ROLLBACK IMMEDIATE
	alter database imoltp set multi_user 
	drop database imoltp
END
go

CREATE DATABASE imoltp
    ON 
    PRIMARY(NAME = [imoltp_data], 
			FILENAME = 'C:\data\imoltp.mdf', size=1GB)
	LOG ON (name = [imoltp_log], Filename='C:\data\imoltp_log.ldf', 
			size=10GB)
GO


SET NOCOUNT ON
GO
USE imoltp
GO

if object_id('dbo.usp_Insert1MRows') is not null
	drop proc dbo.usp_Insert1MRows;
go

if object_id('dbo.T1_inmem') is not null
	drop table dbo.T1_inmem;
go

if object_id('dbo.T1_ondisk') is not null
	drop table dbo.T1_ondisk;
go

USE imoltp
GO

-- disk-based table
CREATE TABLE dbo.T1_ondisk (
   c1 int not null primary key,

   c2 int not null index ix_c2 nonclustered,

   c3 datetime2 not null,
   c4 nchar(400)
)
GO

SET NOCOUNT ON
GO
BEGIN TRAN
	DECLARE @i int = 0
	WHILE @i < 1000000
	BEGIN
	  INSERT INTO dbo.T1_ondisk 
		VALUES (@i, @i/2, GETDATE(), N'my string')
	  SET @i += 1
	END
COMMIT
GO

select count(*) as 'Row count' from dbo.T1_ondisk
go

delete from dbo.T1_ondisk
go

rollback
