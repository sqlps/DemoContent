USE Adventureworks2008R2
GO

DROP TYPE dbo.test_disk
Go
CREATE TYPE dbo.test_disk AS TABLE
(c1 INT NOT NULL,
 c2 CHAR(10));
 GO

ALTER PROCEDURE usp_diskbasedTV
AS
 
Declare @counter int = 0
DECLARE @tv dbo.test_disk

While (@counter < 10001)
BEGIN
	INSERT  @tv VALUES  ( 1, 'n' )
	INSERT  @tv VALUES  ( 2, 'm' )
	DELETE  FROM @tv
	SET @counter +=1
END
GO 


--On 2014+ Box

 --In-Memory
 DROP TYPE IF EXISTS dbo.test_memory
Go
 CREATE TYPE dbo.test_memory AS TABLE
(c1 INT NOT NULL INDEX ix_c1, --Atleast 1 index
 c2 CHAR(10))
WITH (MEMORY_OPTIMIZED=ON);
