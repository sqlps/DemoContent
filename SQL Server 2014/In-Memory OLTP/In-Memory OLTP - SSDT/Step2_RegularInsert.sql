SET STATISTICS TIME OFF
GO
SET NOCOUNT ON
GO

-- TIMED INSERTION OF DATA ROWS 
DECLARE @starttime DATETIME2 = SYSDATETIME(),
        @duration INT

DECLARE @i INT = 1
DECLARE @rowcount int = 100000
DECLARE @c NCHAR(50) = N'12345678901234567890123456789012345678'

BEGIN TRAN
WHILE @i < @rowcount
BEGIN
       INSERT INTO dbo.[Value] VALUES (@i, @c)
       SET @i += 1
END
COMMIT

SET @duration = DATEDIFF(ms, @starttime, SYSDATETIME())
SELECT 'Insert into SQL Table with Clustered Index: ' + CAST(@duration as VARCHAR(10)) + ' ms'

DELETE FROM dbo.Value