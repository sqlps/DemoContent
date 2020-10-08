sp_configure 'Show Advanced Options', 1
go
reconfigure with override
go
sp_configure "max worker threads",1024
go
sp_configure "recovery interval",32767
go
ALTER server configuration set process AFFINITY CPU=AUTO --0 to 7
go
sp_configure 'default trace',0
go
sp_configure 'priority boost', 1
go
sp_configure 'lightweight pooling',0
go
reconfigure with override
go

dbcc traceoff(9801, 9802, 9803, 9804, 9806, 9807, 9808, 9821, 9826, 9827,9828, 9830, -1)
dbcc traceon(9847,8006,9997,8046,-1)
dbcc tracestatus
SELECT @@VERSION
set nocount on;
use master
go

print 'dropping old database...'
go
IF DB_ID('TicketReservations') is not null
BEGIN
	alter database TicketReservations set single_user with ROLLBACK IMMEDIATE
	alter database TicketReservations set multi_user 
	drop database TicketReservations
END
	print 'done...'
go
print 'creating new database...'
go


CREATE DATABASE TicketReservations
    ON 
    PRIMARY(NAME = [TicketReservations_data] , 
			FILENAME = 'D:\SQL\HekatonDemo\TicketReservations_data.mdf', size=5GB),
	FILEGROUP [IMOLTP_Mem] CONTAINS MEMORY_OPTIMIZED_DATA 
   (NAME = [HekatonDemo], FILENAME = N'D:\SQL\HekatonDemo\HekatonDemo_MOD_dir')

	LOG ON (name = [TicketReservations_log], Filename='D:\SQL\HekatonDemo\TicketReservations_log.ldf', size=5GB)
	COLLATE Latin1_General_100_BIN2;
go
print 'done...'
go
ALTER DATABASE TicketReservations set recovery full
go

use TicketReservations
go

print 'creating objects...'
go

if (object_id('TicketReservationSequence') is not null)
	drop sequence TicketReservationSequence
go

create sequence TicketReservationSequence
	AS int
	START WITH 1
	INCREMENT BY 1
	CACHE 50000 ;
go
	
if object_id('TicketReservationDetail') is not null
	drop table TicketReservationDetail;
go

create table TicketReservationDetail (
  iteration int not null,
  lineId	int not null, 
  col3 nvarchar(1000) not null, -- updatable column
  ThreadID int not null
  constraint sql_ts_th primary key clustered (iteration, lineId))
go

if object_id('InsertReservationDetails') is not null
     drop procedure InsertReservationDetails
go
create proc InsertReservationDetails(@Iteration int, @LineCount int, @CharDate NVARCHAR(23), @ThreadID int)
as
BEGIN
	DECLARE @loop int = 0;
	while (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail VALUES(@Iteration, @loop, @CharDate, @ThreadID);
		SET @loop += 1;
	END
END
GO


if object_id('BatchInsertReservations') is not null
     drop procedure BatchInsertReservations
go
create proc BatchInsertReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
begin 
	DECLARE @tranCount int = 0;
	DECLARE @TS Datetime2;
	DECLARE @Char_TS NVARCHAR(23);
	DECLARE @CurrentSeq int = 0;

	SET @TS = CURRENT_TIMESTAMP;
	SET @Char_TS = CAST(@TS AS NVARCHAR(23));
	WHILE (@tranCount < @ServerTransactions)	
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			SET @CurrentSeq = NEXT VALUE FOR TicketReservationSequence ;
			EXEC InsertReservationDetails  @CurrentSeq, @RowsPerTransaction, @Char_TS, @ThreadID;
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
		END CATCH
		SET @tranCount += 1;
	END
END
go

if object_id('ReadMultipleReservations') is not null
     drop procedure ReadMultipleReservations
go
create proc ReadMultipleReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
begin 
	DECLARE @tranCount int = 0;
	DECLARE @CurrentSeq int = 0;
	DECLARE @Sum int = 0;
	DECLARE @loop int = 0;
	WHILE (@tranCount < @ServerTransactions)	
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			select @CurrentSeq = convert(int, current_value) from sys.sequences where name = 'TicketReservationSequence'
			SET @loop = 0
			while (@loop < @RowsPerTransaction)
			BEGIN
				SELECT @Sum += ThreadID from dbo.TicketReservationDetail where iteration = @CurrentSeq and lineId = @loop;
				SET @loop += 1;
			END
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
		END CATCH
		SET @tranCount += 1;
	END
END
go


if object_id('Demo_Reset') is not null
	drop proc Demo_Reset
go

create proc Demo_Reset
as
TRUNCATE TABLE dbo.TicketReservationDetail;
go

print 'done...'
go
