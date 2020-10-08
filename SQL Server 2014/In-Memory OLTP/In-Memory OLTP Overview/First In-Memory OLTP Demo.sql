-- The purpose of this demo is to show the performance comparison between regular db vs. in-memory databases
use master;
go
drop database imoltp;
go

create database imoltp
go


alter database imoltp add filegroup imoltp_mod contains MEMORY_OPTIMIZED_DATA 
alter database imoltp add file (name='imoltp_mod1',filename='c:\data\imoltp_mod1') to filegroup imoltp_mod
go

use imoltp
go


create table dbo.shoppingcart(
	shoppingcartId int not null primary key nonclustered hash with (bucket_count=2000000),
	userId int not null index ix_UserId nonclustered hash with (bucket_count=1000000),
	CreatedDate datetime2 not null,
	TotalPrice money
	) with (memory_optimized=ON)

go

drop table dbo.usersession;
go

create table dbo.usersession(
	sessionId int not null primary key nonclustered hash with (bucket_count=400000),
	userId int not null,
	CreatedDate datetime2 not null,
	shoppingCartId int,
	index ix_userId nonclustered hash (userId) with (bucket_count=400000)
	) with (memory_optimized=ON, durability=schema_only)

go

INSERT dbo.UserSession VALUES (1,342,GETUTCDATE(),4) 
 INSERT dbo.UserSession VALUES (2,65,GETUTCDATE(),NULL) 
 INSERT dbo.UserSession VALUES (3,8798,GETUTCDATE(),1) 
 INSERT dbo.UserSession VALUES (4,80,GETUTCDATE(),NULL) 
 INSERT dbo.UserSession VALUES (5,4321,GETUTCDATE(),NULL) 
 INSERT dbo.UserSession VALUES (6,8578,GETUTCDATE(),NULL) 
 INSERT dbo.ShoppingCart VALUES (1,8798,GETUTCDATE(),NULL) 
 INSERT dbo.ShoppingCart VALUES (2,23,GETUTCDATE(),45.4) 
 INSERT dbo.ShoppingCart VALUES (3,80,GETUTCDATE(),NULL) 
 INSERT dbo.ShoppingCart VALUES (4,342,GETUTCDATE(),65.4) 
 GO

 select * from dbo.userSession;
 select * from dbo.shoppingcart;

 update statistics dbo.usersession with fullscan, norecompute
 update statistics dbo.shoppingcart with fullscan, norecompute


begin tran
	update dbo.usersession with (snapshot) set shoppingCartId=3 where sessionId=4;
	update dbo.shoppingcart with (snapshot) set TotalPrice=65.84 where shoppingcartId=3;
commit
go

select * from dbo.usersession u join dbo.shoppingcart s on u.shoppingCartId = s.shoppingcartId where u.sessionId = 4
go

create procedure dbo.usp_assignCart @SessionId int
with native_compilation, schemabinding, execute as owner
as
begin atomic
with (transaction isolation level = snapshot, language=N'us_english')
	Declare @userId int, @shoppingCardId int

	select @userId = userId, @shoppingCardId=shoppingCartId from dbo.usersession where sessionId=@sessionId

	If @UserId is NULL 
		Throw 51000, 'The session or shopping card does not exist',1

	Update dbo.usersession set shoppingCartId=@shoppingCardId where sessionId=@sessionId
End
Go

exec dbo.usp_assignCart 1;

drop procedure dbo.usp_insertSampleCarts;
go

create procedure dbo.usp_insertSampleCarts @startId int, @insertCount int
with native_compilation, schemabinding, execute as owner
as
begin atomic
with (transaction isolation level = snapshot, language=N'us_english')
	declare @shoppingcartId int = @startId

	while @shoppingcartId<@startId+@insertCount
		begin
			insert into dbo.shoppingcart values (@shoppingcartId, 1, '2013-01-01T00:00:00',NULL)
			set @shoppingcartId +=1
		end
end
go

--run as batch, this will run very fast because it is in-memory
declare @startid int=(select max(shoppingcartId)+1 from dbo.shoppingcart)
--select @startid
exec usp_insertSampleCarts @startId, 100000
go
select count(*) from dbo.shoppingcart;

--clean up
delete from dbo.shoppingcart;
go
INSERT dbo.ShoppingCart VALUES (2,23,GETUTCDATE(),45.4) 



----------------- non-HK table comparison

drop table dbo.shoppingcart_reg;
go

create table dbo.shoppingcart_reg(
	shoppingcartId int not null primary key,
	userId int not null,
	CreatedDate datetime2 not null,
	TotalPrice money
	) 


create nonclustered index ix_userId on dbo.shoppingcart_reg (userId asc);
go

drop procedure dbo.usp_insertSampleCarts_reg;
go

create procedure dbo.usp_insertSampleCarts_reg @startId int, @insertCount int
as
begin
	declare @shoppingcartId int = @startId

	while @shoppingcartId<@startId+@insertCount
		begin
			insert into dbo.shoppingcart_reg values (@shoppingcartId, 1, '2013-01-01T00:00:00',NULL)
			set @shoppingcartId +=1
		end
end
go

-- run as batch, this will take longer than in-memory database
set statistics time off
set nocount on
declare @startid int=(select max(shoppingcartId)+1 from dbo.shoppingcart)
--select @startid
exec usp_insertSampleCarts_reg @startId, 100000
go
select count(*) from shoppingcart_reg




