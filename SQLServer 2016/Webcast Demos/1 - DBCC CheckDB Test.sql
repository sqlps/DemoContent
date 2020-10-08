-- ====================================================
-- Step 1) Demonstration showing performance of CheckDB
-- ====================================================

use tempdb
go

set nocount on
go

if(0 <> (select count(*) from tempdb.sys.objects where name = 'tblDBCC') )
begin
drop table tblDBCC
end
go

create table tblDBCC
(
	iID		int NOT NULL IDENTITY(1,1) PRIMARY KEY CLUSTERED,
	strData nvarchar(2000) NOT NULL
)
go

-- Insert data to expand to a table that allows DOP activities
print 'Populating  Data'
go

begin tran
go

	insert into tblDBCC (strData) values ( replicate(N'X', 2000) )
	while(SCOPE_IDENTITY() < 100000)
	begin
		insert into tblDBCC (strData) values ( replicate(N'X', 2000) )
	end
go
commit tran
go


-- ===================
-- Step 2) Run CheckDB
-- ===================

declare @dtStart datetime
set @dtStart = GETUTCDATE();
dbcc checkdb(tempdb)
select datediff(ms, @dtStart, GetUTCDate()) as [Elapsed DBCC checkdb (ms)]
go
