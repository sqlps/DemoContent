-- =======================================
-- Step 1) diskbased temp tables
-- =======================================
SET NOCOUNT ON;
GO
CREATE PROCEDURE sp_temp
AS
    BEGIN
        IF NOT EXISTS (SELECT * FROM tempdb.sys.objects WHERE name=N'##temp1')
             CREATE TABLE ##temp1
                    (
                      c1 INT NOT NULL ,
                      c2 NVARCHAR(4000)
                    );
        BEGIN TRAN
        DECLARE @i INT = 0;
        WHILE @i < 100
            BEGIN
                INSERT  ##temp1
                VALUES  ( @i, N'abc' );
                SET @i += 1;
            END;
        COMMIT
    END;
GO

-- =======================================
-- Step 2)In-Mem TempTable
-- =======================================
CREATE TABLE dbo.temp1
(c1 INT NOT NULL INDEX ix_1 ,
 c2 NVARCHAR(4000))
WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_ONLY);
GO
DROP PROCEDURE IF EXISTS sp_temp_inmem
GO
CREATE PROCEDURE sp_temp_inmem
AS
    BEGIN
        BEGIN TRAN
        DECLARE @i INT = 0;
        WHILE @i < 100
            BEGIN
                INSERT  dbo.temp1
                VALUES  ( @i, N'abc' );
                SET @i += 1;
            END;
        COMMIT
    END;