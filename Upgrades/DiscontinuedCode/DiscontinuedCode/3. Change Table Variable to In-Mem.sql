ALTER DATABASE Adventureworks2008R2 ADD FILEGROUP Adventureworks2008R2_mod CONTAINS MEMORY_OPTIMIZED_DATA

ALTER DATABASE Adventureworks2008R2 ADD FILE (name='Adventureworks2008R2_mod1', filename='D:\data\Adventureworks2008R2_mod1') TO FILEGROUP Adventureworks2008R2_mod
GO

ALTER PROCEDURE usp_diskbasedTV
AS
 
Declare @counter int = 0
DECLARE @tv  dbo.test_memory

While (@counter < 10001)
BEGIN
	INSERT  @tv VALUES  ( 1, 'n' )
	INSERT  @tv VALUES  ( 2, 'm' )
	DELETE  FROM @tv
	SET @counter +=1
END
GO 

