﻿/*
Deployment script for TicketReservations

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "TicketReservations"
:setvar DefaultFilePrefix "TicketReservations"
:setvar DefaultDataPath "F:\DATA\"
:setvar DefaultLogPath "F:\DATA\"

GO
:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
PRINT N'Creating [dbo].[InsertReservationDetails]...';


GO
/*
CREATE PROCEDURE InsertReservationDetails(@TicketReservationID int, @LineCount int, @Comment NVARCHAR(1000), @FlightID int)
AS
BEGIN
	DECLARE @loop int = 0;
	WHILE (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail (TicketReservationID, Quantity, FlightID, Comment) 
			VALUES(@TicketReservationID, @loop % 8 + 1, @FlightID, @Comment);
		SET @loop += 1;
	END
END


*/
-- natively compiled version of the stored procedure:

CREATE PROCEDURE InsertReservationDetails(@TicketReservationID int, @LineCount int, @Comment NVARCHAR(1000), @FlightID int)
WITH NATIVE_COMPILATION, SCHEMABINDING
as
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')


	DECLARE @loop int = 0;
	while (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail (TicketReservationID, Quantity, FlightID, Comment) 
		    VALUES(@TicketReservationID, @loop % 8 + 1, @FlightID, @Comment);
		SET @loop += 1;
	END
END
GO
PRINT N'Update complete.';


GO