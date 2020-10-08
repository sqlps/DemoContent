use master;
go
drop database imoltp;
go

create database imoltp
go


alter database imoltp add filegroup imoltp_mod2 contains MEMORY_OPTIMIZED_DATA 
alter database imoltp add file (name='imoltp_mod2',filename='d:\sqlservr\data\imoltp_mod2') to filegroup imoltp_mod2
go

use imoltp
go



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

-- run as batch
set statistics time off
set nocount on
exec usp_insertSampleCarts_reg 1, 100000
go
select count(*) from shoppingcart_reg
select top 10 * from shoppingcart_reg
truncate table shoppingcart_reg



--- Hekaton

drop procedure dbo.usp_insertSampleCarts
drop table dbo.shoppingcart
go

create table dbo.shoppingcart(
	shoppingcartId int not null primary key nonclustered hash with (bucket_count=2000000),
	userId int not null index ix_UserId nonclustered,
	CreatedDate datetime2 not null,
	TotalPrice money
	) with (memory_optimized=ON)

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

exec usp_insertSampleCarts 1, 100000
go
select count(*) from dbo.shoppingcart;
select top 10 * from dbo.shoppingcart;

--clean up
delete from dbo.shoppingcart;
go
