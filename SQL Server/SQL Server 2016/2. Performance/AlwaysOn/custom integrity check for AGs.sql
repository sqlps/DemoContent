
create PROCEDURE usp_GetErrorInfo
AS
print ERROR_MESSAGE() 

GO


Create procedure usp_runintegritycheck
as 
begin


declare @dbname varchar(255), @cmd varchar(max) 
declare @errors int
set @errors = 0

Declare integrity_cursor Cursor for 
select 
d.name,
'USE [' + d.name +']	DBCC CHECKDB(N''' + d.name + ''')  WITH NO_INFOMSGS' as cmd 
from sys.dm_hadr_availability_replica_states as a
join sys.availability_replicas as b 
on a.replica_id = b.replica_id
join sys.dm_hadr_database_replica_states as c
on a.group_id = c.group_id and a.replica_id = c.replica_id
join sys.databases as d 
on c.database_id = d.database_id
where a.role = 1
and b.replica_server_name = @@servername
union all
select
a.name,
'USE [' + a.name +']	DBCC CHECKDB(N''' + a.name + ''')  WITH NO_INFOMSGS' as cmd 
from sys.databases as a
where database_id not in (select database_id from sys.dm_hadr_database_replica_states)
and database_id <> 2
order by name ;


open integrity_cursor

fetch next from integrity_cursor
into @dbname, @cmd

while @@FETCH_STATUS = 0
	begin

		print '*****************************************************************************'
		print @dbname
		print @cmd
		
		begin try
			exec (@cmd)
		end try
		Begin catch
			execute master..usp_geterrorinfo
			set @errors = @errors + 1
		end catch

		fetch next from integrity_cursor
		into @dbname, @cmd
	end

Close integrity_cursor
deallocate integrity_cursor

print ' '
print ' '
print ' '
print ' '


if @errors > 0
	begin
		raiserror ('Check the maintenance plan log for more info', 16,  1);
	end


end




