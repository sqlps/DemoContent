--Step 1 - Manually add Meta data to all databases where it was not create as part of MSDB
use master
Go

sp_msforeachdb 'use ?;	if db_id() > 4
						Begin
							if NOT exists (select name from sys.extended_properties where class = 0 and name in (''BackupType'')) 
								EXEC sys.sp_addextendedproperty @name=N''BackupType'', @value=N''Local'';
							if NOT exists (select name from sys.extended_properties where class = 0 and name in (''ApplicationName'')) 
								EXEC sys.sp_addextendedproperty @name=N''ApplicationName'', @value=N'''';
							if NOT exists (select name from sys.extended_properties where class = 0 and name in (''Notes'')) 
								EXEC sys.sp_addextendedproperty @name=N''Notes'', @value=N'''';
							if NOT exists (select name from sys.extended_properties where class = 0 and name in (''DBOwner'')) 
								EXEC sys.sp_addextendedproperty @name=N''DBOwner'', @value=N''Pankaj Satyaketu'';
							if NOT exists (select name from sys.extended_properties where class = 0 and name in (''Department'')) 
								EXEC sys.sp_addextendedproperty @name=N''Department'', @value=N''IT'';
							if NOT exists (select name from sys.extended_properties where class = 0 and name in (''Expires'')) 
								EXEC sys.sp_addextendedproperty @name=N''Expires'', @value=N''99/99/9999'';
							if NOT exists (select name from sys.extended_properties where class = 0 and name in (''Purpose'')) 
								EXEC sys.sp_addextendedproperty @name=N''Purpose'', @value=N'''';
							if NOT exists (select name from sys.extended_properties where class = 0 and name in (''SoxDB'')) 
								EXEC sys.sp_addextendedproperty @name=N''SoxDB'', @value=N''No'';						end'

--Step 2 - Query the metadata from all the databases
Create Table #DBMetaData (DBName  sysname, ApplicationName sql_variant, BackupType sql_variant, DBOwner sql_variant, Department sql_variant, Expires sql_variant, notes sql_variant, Purpose sql_variant)
go
sp_msforeachdb 'use	?; 
	if db_id() > 4
	Begin
		Insert #DBMetaData 
			select cast(db_name() as varchar(50))as DBName,[ApplicationName],[BackupType],[DBOwner],[Department],[Expires],[Notes],[Purpose]
			from sys.extended_properties  
			pivot	( 
						Max(value) 
						for Name in ([ApplicationName],[BackupType],[DBOwner],[Department],[Expires],[Notes],[Purpose])
					) as T
			where class = 0
	end;' 			
go
Select * from #DBMetaData
Drop table #DBMetaData

--Proc to update metadata: sp_updateextendedproperty @name=N'Purpose', @value=N's' 
--Proc to delete metadata: sp_updateextendedproperty

