-- =====================================================================================================
-- Step 1) Run workload
-- =====================================================================================================
-- C:\Demos\SQL Server 2016 - WWI\Performance\IMOLTP\MultithreadedInMemoryTableInsert.exe

-- =====================================================================================================
-- Step 2) View data in table
-- =====================================================================================================
--Validate loads
Select Count(*) From InMemory.VehicleLocations
Select Count(*) From OnDisk.VehicleLocations

--What's in it
Select top 10 * from InMemory.VehicleLocations

-- =====================================================================================================
-- Step 3) Cleanup
-- =====================================================================================================
DELETE FROM InMemory.VehicleLocations
TRUNCATE TABLE OnDisk.VehicleLocations

-- =====================================================================================================
-- Step 4) Optional
-- =====================================================================================================

-- Note the time to insert 500 thousand location rows using on-disk
declare @start datetime2
set @start = SYSDATETIME()

DECLARE @RegistrationNumber nvarchar(20);
DECLARE @TrackedWhen datetime2(2);
DECLARE @Longitude decimal(18,4);
DECLARE @Latitude decimal(18,4);

DECLARE @Counter int = 0;
SET NOCOUNT ON;

WHILE @Counter < 500000
BEGIN
	-- create some dummy data
	SET @RegistrationNumber = N'EA' + RIGHT(N'00' + CAST(@Counter % 100 AS nvarchar(10)), 3) + N'-GL';
	SET @TrackedWhen = SYSDATETIME();
	SET @Longitude = RAND() * 100;
	SET @Latitude = RAND() * 100;

	EXEC OnDisk.InsertVehicleLocation @RegistrationNumber, @TrackedWhen, @Longitude, @Latitude;

	SET @Counter += 1;
END;

select datediff(ms,@start, sysdatetime()) as 'insert into disk-based table (in ms)'
GO

-- Now insert the same number of location rows using in-memory and natively compiled
declare @start datetime2
set @start = SYSDATETIME()

DECLARE @RegistrationNumber nvarchar(20);
DECLARE @TrackedWhen datetime2(2);
DECLARE @Longitude decimal(18,4);
DECLARE @Latitude decimal(18,4);

DECLARE @Counter int = 0;
SET NOCOUNT ON;

WHILE @Counter < 500000
BEGIN
	-- create some dummy data
	SET @RegistrationNumber = N'EA' + RIGHT(N'00' + CAST(@Counter % 100 AS nvarchar(10)), 3) + N'-GL';
	SET @TrackedWhen = SYSDATETIME();
	SET @Longitude = RAND() * 100;
	SET @Latitude = RAND() * 100;

	EXEC InMemory.InsertVehicleLocation @RegistrationNumber, @TrackedWhen, @Longitude, @Latitude;

	SET @Counter += 1;
END;

select datediff(ms,@start, sysdatetime()) as 'insert into memory-optimized table (in ms)'
GO

-- Note that while using the in-memory table and natively-compiled procedure is faster, we are still
-- running our main program via interpreted T-SQL and calling the stored procedure via the interop layer.
-- Let's try calling it from another natively-compiled stored procedure.

declare @start datetime2
set @start = SYSDATETIME()
EXECUTE InMemory.Insert500ThousandVehicleLocations
select datediff(ms,@start, sysdatetime()) as 'insert into memory-optimized table using native compilation (in ms)'
GO