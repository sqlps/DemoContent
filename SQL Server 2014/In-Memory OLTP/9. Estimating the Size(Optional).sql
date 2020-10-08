--ENSURE YOU RAN Step 2 BEFORE PROCEEDING

--See: http://msdn.microsoft.com/en-us/library/dn282389.aspx

Use IMOLTP_Demo
Go

--Adhoc Insert of 1M rows takes about 60 seconds
/*
Declare @Counter int = 0,
		@firstname char(50),
		@lastName char(50),
		@OrderDate DateTime
		
While @Counter < 1000000
Begin
	Declare @min int = @counter * -1
	Set @OrderDate  = dateadd(minute, @min, getdate())
	set @FirstName = 'FirstName' + Cast(@counter as varchar(10))
	set @LastName = 'LastName' + Cast(@counter as varchar(10))
	Insert  dbo.IMOLTP_Tbl1(Firstname, Lastname, Email, OrderDate)
	Values(@FirstName, @lastName, 'test.tester@live.com', @orderdate)
	set @Counter +=1
End
*/

exec dbo.InsertRecords 1000000
Go

/************************************
 * Estimating the size of the table *
 ************************************/

 --Size of Datatypes: http://msdn.microsoft.com/en-us/library/ms187752.aspx 

--Timestamps: Row header/timestamps = 24 bytes.

--Index pointers: For each hash index in the table, each row has an 8-byte address pointer to the next row in the index. 
-- For the 2 indexes we will have 16 bytes

--Data:  The size of the data portion of the row is determined by summing the type size for each data column. 
--In our table we have 1 4-byte integers, two 50-byte character columns, one 100-byte character column. 
--Therefore the data portion of each row is 4 + 50 + 50 + 100 +  8 = 212 bytes.

--Total per row = 24 + 16 + 212 = 252 bytes x 10000000 rows = ~240MB for the table


/************************************
 * Estimating the size of the Index *
 ************************************/
 ----------------
 -- HASH INDEX --
 ----------------
 --Although we specify a bucket count of 1000000, it rounds up to a power of 2 or 2^20 = 1048576. 
 --Size of the index = 2^20 * 8 = 8MB

 ---------
 -- NCI --
 ---------

 --memoryForNonClusteredIndex = (pointerSize + sum(keyColumnDataTypeSizes)) * rowsWithUniqueKeys 
 -- = (8 + 8) * 1 = 16
 --Unique values in date time
Select Count(Distinct(OrderDate)) From IMOLTP_Tbl1

select * from IMOLTP_Tbl1