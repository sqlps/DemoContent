/* This Sample Code is provided for the purpose of illustration only and is not intended
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys fees, that arise or
result from the use or distribution of the Sample Code.*/

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

