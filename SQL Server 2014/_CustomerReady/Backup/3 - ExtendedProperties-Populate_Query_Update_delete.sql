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

