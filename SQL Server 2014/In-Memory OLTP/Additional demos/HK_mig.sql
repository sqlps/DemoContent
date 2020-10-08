use master;
go
/*
ALTER DATABASE imoltp_mig
     SET SINGLE_USER 
     WITH ROLLBACK IMMEDIATE
*/
drop database imoltp_mig;
go

create database imoltp_mig
go


alter database imoltp_mig add filegroup imoltp_mod_mig contains MEMORY_OPTIMIZED_DATA 
go
alter database imoltp_mig add file (name='imoltp_mod1_mig',filename='d:\sqlservr\data\imoltp_mod1_mig') to filegroup imoltp_mod_mig
go

use imoltp_mig
go

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
--	print 1
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
exec usp_insertSampleCarts_reg 1, 100
go
select count(*) from shoppingcart_reg




