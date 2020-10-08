-- This script creates comparable disk-based and memory-optimized tables, as well as corresponding stored procedures 
--   for vehicle location insertion.
-- It then compares the performance of single-threaded inserts (500K rows):
--   - into a disk-based table
--   - into a memory-optimized table
--   - into a memory-optimized table, with rows generated in a natively compiled stored procedure
--
-- Before running the script, make sure to connect to a user database.
Use WideWorldImporters
Go

SET NOCOUNT ON;
SET XACT_ABORT ON;


DROP PROCEDURE IF EXISTS InMemory.Insert500ThousandVehicleLocations
DROP PROCEDURE IF EXISTS InMemory.InsertVehicleLocation
DROP PROCEDURE IF EXISTS OnDisk.InsertVehicleLocation
DROP TABLE IF EXISTS InMemory.VehicleLocations
DROP TABLE IF EXISTS OnDisk.VehicleLocations
GO
DROP SCHEMA IF EXISTS InMemory
DROP SCHEMA IF EXISTS OnDisk
GO

-- We then create the disk based table and insert stored procedure
CREATE SCHEMA OnDisk AUTHORIZATION dbo;
GO

CREATE TABLE OnDisk.VehicleLocations
(
	VehicleLocationID bigint IDENTITY(1,1) PRIMARY KEY,
	RegistrationNumber nvarchar(20) NOT NULL,
	TrackedWhen datetime2(2) NOT NULL,
	Longitude decimal(18,4) NOT NULL,
	Latitude decimal(18,4) NOT NULL
);
GO

CREATE PROCEDURE OnDisk.InsertVehicleLocation
@RegistrationNumber nvarchar(20),
@TrackedWhen datetime2(2),
@Longitude decimal(18,4),
@Latitude decimal(18,4)
WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	INSERT OnDisk.VehicleLocations
		(RegistrationNumber, TrackedWhen, Longitude, Latitude)
	VALUES
		(@RegistrationNumber, @TrackedWhen, @Longitude, @Latitude);
	RETURN 0;
END;
GO

-- And then in-memory and natively-compiled alternatives

CREATE SCHEMA InMemory AUTHORIZATION dbo;
GO

CREATE TABLE InMemory.VehicleLocations
(
	VehicleLocationID bigint IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	RegistrationNumber nvarchar(20) NOT NULL,
	TrackedWhen datetime2(2) NOT NULL,
	Longitude decimal(18,4) NOT NULL,
	Latitude decimal(18,4) NOT NULL
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO
 
CREATE PROCEDURE InMemory.InsertVehicleLocation
@RegistrationNumber nvarchar(20),
@TrackedWhen datetime2(2),
@Longitude decimal(18,4),
@Latitude decimal(18,4)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'English'
)

	INSERT InMemory.VehicleLocations
		(RegistrationNumber, TrackedWhen, Longitude, Latitude)
	VALUES
		(@RegistrationNumber, @TrackedWhen, @Longitude, @Latitude);
	RETURN 0;
END;
GO
