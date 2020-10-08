Use IMOLTP_Demo
GO

CREATE PROCEDURE dbo.InsertRecords @RecordsToInsert int
  WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS Owner
AS 
BEGIN ATOMIC WITH 
(	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'us_english')
Declare @Counter int = 0,
		@firstname char(50),
		@lastName char(50),
		@OrderDate DateTime
		
While @Counter < @RecordsToInsert
Begin
	Declare @min int = @counter * -1
	Set @OrderDate  = dateadd(minute, @min, getdate())
	set @FirstName = 'FirstName' + Cast(@counter as varchar(10))
	set @LastName = 'LastName' + Cast(@counter as varchar(10))
	Insert  dbo.IMOLTP_Tbl1(Firstname, Lastname, Email, OrderDate)
	Values(@FirstName, @lastName, 'test.tester@live.com', @orderdate)
	set @Counter +=1
End

END
GO

Select OBJECT_ID('InsertRecords')
GO

CREATE PROCEDURE dbo.InsertRecords_Standard @RecordsToInsert int
AS
Declare @Counter int = 0,
		@firstname char(50),
		@lastName char(50),
		@OrderDate DateTime
		
While @Counter < @RecordsToInsert
Begin
	Declare @min int = @counter * -1
	Set @OrderDate  = dateadd(minute, @min, getdate())
	set @FirstName = 'FirstName' + Cast(@counter as varchar(10))
	set @LastName = 'LastName' + Cast(@counter as varchar(10))
	Insert  dbo.IMOLTP_Tbl1(Firstname, Lastname, Email, OrderDate)
	Values(@FirstName, @lastName, 'test.tester@live.com', @orderdate)
	set @Counter +=1
End
GO

Select OBJECT_ID('InsertRecords_Standard')
Go

