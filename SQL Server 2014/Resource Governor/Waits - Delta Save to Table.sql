--Step 1) Setup
Use TempDB
Go

--Create the tables
CREATE TABLE [dbo].[DeltaWaits](
	[wait_type] [nvarchar](60) NOT NULL,
	[ChangeInWait_Time_ms] [bigint] NULL,
	[Capture Time] [datetime] NOT NULL
) ON [PRIMARY]

GO
USE [tempdb]
GO

CREATE TABLE [dbo].[Snapshot1](
	[wait_type] [nvarchar](60) NOT NULL,
	[waiting_tasks_count] [bigint] NOT NULL,
	[wait_time_ms] [bigint] NOT NULL,
	[max_wait_time_ms] [bigint] NOT NULL,
	[signal_wait_time_ms] [bigint] NOT NULL
) ON [PRIMARY]

GO
USE [tempdb]
GO

CREATE TABLE [dbo].[Snapshot2](
	[Wait_type] [nvarchar](60) NOT NULL,
	[waiting_tasks_count] [bigint] NOT NULL,
	[wait_time_ms] [bigint] NOT NULL,
	[max_wait_time_ms] [bigint] NOT NULL,
	[signal_wait_time_ms] [bigint] NOT NULL
) ON [PRIMARY]

GO


-- Step 2) Log the data
Declare @Delay datetime = '00:01:00'

While 1=1
Begin
	--Capture Point in time
	Insert  Snapshot1
	Select wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
	From Sys.dm_os_wait_stats
	Where wait_type  
   NOT IN 
     ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 
   'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 
   'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT') 
    -- filter out additional irrelevant waits 

	--Wait 5 seconds check again
	WAITFOR DELAY @Delay

	--Capture Point in time again
	Insert Snapshot2 
	Select Wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
	From Sys.dm_os_wait_stats
	Where wait_type  
   NOT IN 
     ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 
   'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 
   'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT') 
    -- filter out additional irrelevant waits 


	--Compare
	Insert DeltaWaits
	Select S2.wait_type, (S2.wait_time_ms - S1.wait_time_ms) ChangeInWait_Time_ms, getdate() as 'Capture Time'
	FROM Snapshot1 S1
	inner join Snapshot2 S2 
	on S1.wait_type = S2.wait_type
	Where S2.wait_time_ms > S1.wait_time_ms
	Order by S2.wait_time_ms DESC

	Truncate table Snapshot1
	Truncate table Snapshot2
END

Select * from DeltaWaits
