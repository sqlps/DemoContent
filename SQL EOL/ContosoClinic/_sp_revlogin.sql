/* **********************************************************************
This Sample Code is provided for the purpose of illustration only and is 
not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" 
WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING 
BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the 
Sample Code and to reproduce and distribute the object code form of 
the Sample Code, provided that You agree: (i) to not use Our name, 
logo, or trademarks to market Your software product in which the 
Sample Code is embedded; (ii) to include a valid copyright notice 
on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers 
from and against any claims or lawsuits, including attorneys’ fees, 
that arise or result from the use or distribution of the Sample Code.
********************************************************************** */

/*
-- This source for script is found at http://support.microsoft.com/kb/246133

This version includes code to set:
  > Server Role Memebership
  > Default Database
for the scripted users.

*/

IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL 
DROP PROCEDURE sp_help_revlogin 
GO 

IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL 
DROP PROCEDURE sp_hexadecimal 
GO 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_hexadecimal]
    @binvalue varbinary(256),
    @hexvalue varchar(256) OUTPUT
AS
DECLARE @charvalue varchar(256)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF' 
WHILE (@i <= @length) 
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END
SELECT @hexvalue = @charvalue

GO

CREATE PROCEDURE sp_help_revlogin 

@login_name sysname = NULL, 
@include_db bit = 0, 
@include_role bit = 0 

AS 
BEGIN

    DECLARE @name           sysname 
    DECLARE @xstatus        int 
    DECLARE @binpwd         varbinary (256) 
    DECLARE @dfltdb         varchar (256) 
    DECLARE @txtpwd         sysname 
    DECLARE @tmpstr         varchar (256) 
    DECLARE @SID_varbinary  varbinary(85) 
    DECLARE @SID_string     varchar(256) 
    DECLARE @RoleName       VARCHAR(32)
    DECLARE @IsSQLLogin     BIT
    DECLARE @IsPolChk       BIT
    DECLARE @IsExpChk       BIT

    SET NOCOUNT ON


-- **********************************************************************
    SELECT  l.*
        INTO #Server_Logins
        FROM (
            SELECT  [name],
                    [principal_id],
                    [sid],
                    is_disabled,
                    default_database_name,
                    is_policy_checked,
                    is_expiration_checked,
                    password_hash,
                    CAST(1 AS BIT) AS IsSQLLogin
                FROM sys.sql_logins
              UNION
            SELECT  [name],
                    [principal_id],
                    [sid],
                    is_disabled,
                    default_database_name,
                    CAST(NULL AS BIT) AS is_policy_checked,
                    CAST(NULL AS BIT) AS is_expiration_checked,
                    CAST(NULL AS VARBINARY(256)) AS password_hash,
                    CAST(0 AS BIT) AS IsSQLLogin
                FROM sys.server_principals
                    WHERE [sid] NOT IN (SELECT [sid]
                                            FROM sys.sql_logins) ) AS l
        WHERE l.[name] != 'BUILTIN\Administrators'
         AND  l.[name] != 'NT AUTHORITY\SYSTEM'
         AND  l.[name] NOT LIKE '##%'
         AND  l.[name] NOT LIKE '%\svc%'
         AND  l.[name] != 'NT AUTHORITY\NETWORK SERVICE'
		 AND  l.name NOT LIKE ('%' + CAST(SERVERPROPERTY ('ComputerNamePhysicalNetBIOS') AS VARCHAR(128)) + '%')
         AND  (CAST([sid] AS BIGINT) > 10 OR CAST([sid] AS BIGINT) < 0)

    SELECT  rm.member_principal_id AS principal_id, 
            r.[name] AS [Role]
        INTO #RoleMembers
        FROM (
            SELECT *
                FROM sys.server_principals sp       
                WHERE sp.[Type] = 'R') AS r
            INNER JOIN sys.server_role_members rm
                ON r.[sid] = rm.role_principal_id
-- **********************************************************************

    DECLARE login_curs CURSOR STATIC FOR 
        SELECT  [sid], 
                [name], 
                password_hash, 
                COALESCE(default_database_name, 'master'), 
                IsSQLLogin,
                is_policy_checked,
                is_expiration_checked
            FROM #Server_Logins 
            WHERE [name] = @login_name OR
                  @login_name IS NULL
            ORDER BY [name]

    OPEN login_curs 
    FETCH NEXT 
        FROM login_curs 
        INTO @SID_varbinary, @name, @binpwd, @dfltdb, @IsSQLLogin, @IsPolChk, @IsExpChk

    IF (@@fetch_status = -1) 
        BEGIN 
            PRINT 'No login(s) found.' 
            CLOSE login_curs 
            DEALLOCATE login_curs 
            RETURN -1 
        END 

    SET @tmpstr = '/* sp_help_revlogin script ' 
    PRINT @tmpstr 
    SET @tmpstr = '** Generated ' + CONVERT (VARCHAR(32), GETDATE()) + ' on ' + CAST(SERVERPROPERTY ('ServerName') AS VARCHAR(64)) + ' */' 
    PRINT @tmpstr 
    PRINT '' 
    PRINT '' 
    PRINT '' 
    PRINT '/***** CREATE LOGINS *****/' 

    WHILE @@fetch_status = 0 
        BEGIN 
            PRINT '' 
            SET @tmpstr = '-- Login: ' + @name 
            PRINT @tmpstr 

            IF @IsSQLLogin = 0
                BEGIN
                    SET @tmpstr = 'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE [name] = ''' + @name + ''')' 
                    PRINT @tmpstr 
                    SET @tmpstr = CHAR(9) + 'CREATE LOGIN [' + @name + '] FROM WINDOWS' 
                    PRINT @tmpstr 
                END 
            ELSE 
                BEGIN -- SQL Server authentication 
                    EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT 

                    IF (@binpwd IS NOT NULL) 
                        BEGIN -- Non-null password 
                            EXEC sp_hexadecimal @binpwd, @txtpwd OUT 
                            SET @tmpstr = 'CREATE LOGIN [' + @name + '] WITH PASSWORD=' + @txtpwd + ' HASHED' 
                        END 
                    ELSE 
                        BEGIN -- Null password 
                            SET @tmpstr = 'CREATE LOGIN [' + @name + '] WITH PASSWORD=''''' 
                        END 

                    IF @IsPolChk = 1
                        BEGIN
                            SELECT @tmpstr = @tmpstr + ', CHECK_POLICY=ON'
                        END
                    ELSE
                        BEGIN
                            SELECT @tmpstr = @tmpstr + ', CHECK_POLICY=OFF'
                        END

                    IF @IsExpChk = 1
                        BEGIN
                            SELECT @tmpstr = @tmpstr + ', CHECK_EXPIRATION=ON'
                        END
                    ELSE
                        BEGIN
                            SELECT @tmpstr = @tmpstr + ', CHECK_EXPIRATION=OFF'
                        END

                    SET @tmpstr = @tmpstr + ', SID=' + @SID_string 
                    PRINT @tmpstr 
                END 

            FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @binpwd, @dfltdb, @IsSQLLogin, @IsPolChk, @IsExpChk
        END 

        IF @include_db = 1 
            BEGIN 
                PRINT '' 
                PRINT '' 
                PRINT '' 
                PRINT '/***** SET DEFAULT DATABASES *****/' 

                FETCH FIRST FROM login_curs INTO @SID_varbinary, @name, @binpwd, @dfltdb, @IsSQLLogin, @IsPolChk, @IsExpChk

                WHILE @@fetch_status = 0 
                    BEGIN 
                        PRINT '' 
                        SET @tmpstr = '-- Login: ' + @name 
                        PRINT @tmpstr 

                        SET @tmpstr = 'ALTER LOGIN [' + @name + '] WITH DEFAULT_DATABASE=[' + @dfltdb + ']' 
                        PRINT @tmpstr 

                        FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @binpwd, @dfltdb, @IsSQLLogin, @IsPolChk, @IsExpChk
                    END 
            END 

        IF @include_role = 1 
            BEGIN 
                PRINT '' 
                PRINT '' 
                PRINT '' 
                PRINT '/***** SET SERVER ROLES *****/' 

                FETCH FIRST FROM login_curs INTO @SID_varbinary, @name, @binpwd, @dfltdb, @IsSQLLogin, @IsPolChk, @IsExpChk

                WHILE @@fetch_status = 0 
                    BEGIN 
                        PRINT '' 
                        SET @tmpstr = '-- Login: ' + @name 
                        PRINT @tmpstr 

                        SELECT @RoleName = 'sysadmin'
                        IF EXISTS ( SELECT  * 
                                        FROM #Server_Logins sl
                                            INNER JOIN #RoleMembers rm
                                                ON sl.principal_id = rm.principal_id
                                        WHERE sl.[name] = @name
                                         AND  rm.[Role] = @RoleName)
                            BEGIN 
                                SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @RoleName + ''' ' 
                                PRINT @tmpstr 
                            END 

                        SELECT @RoleName = 'securityadmin'
                        IF EXISTS ( SELECT  * 
                                        FROM #Server_Logins sl
                                            INNER JOIN #RoleMembers rm
                                                ON sl.principal_id = rm.principal_id
                                        WHERE sl.[name] = @name
                                         AND  rm.[Role] = @RoleName)
                            BEGIN 
                                SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @RoleName + ''' ' 
                                PRINT @tmpstr 
                            END 

                        SELECT @RoleName = 'serveradmin'
                        IF EXISTS ( SELECT  * 
                                        FROM #Server_Logins sl
                                            INNER JOIN #RoleMembers rm
                                                ON sl.principal_id = rm.principal_id
                                        WHERE sl.[name] = @name
                                         AND  rm.[Role] = @RoleName)
                            BEGIN 
                                SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @RoleName + ''' ' 
                                PRINT @tmpstr 
                            END 

                        SELECT @RoleName = 'setupadmin'
                        IF EXISTS ( SELECT  * 
                                        FROM #Server_Logins sl
                                            INNER JOIN #RoleMembers rm
                                                ON sl.principal_id = rm.principal_id
                                        WHERE sl.[name] = @name
                                         AND  rm.[Role] = @RoleName)
                            BEGIN 
                                SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @RoleName + ''' ' 
                                PRINT @tmpstr 
                            END 

                        SELECT @RoleName = 'processadmin'
                        IF EXISTS ( SELECT  * 
                                        FROM #Server_Logins sl
                                            INNER JOIN #RoleMembers rm
                                                ON sl.principal_id = rm.principal_id
                                        WHERE sl.[name] = @name
                                         AND  rm.[Role] = @RoleName)
                            BEGIN 
                                SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @RoleName + ''' ' 
                                PRINT @tmpstr 
                            END 

                        SELECT @RoleName = 'diskadmin'
                        IF EXISTS ( SELECT  * 
                                        FROM #Server_Logins sl
                                            INNER JOIN #RoleMembers rm
                                                ON sl.principal_id = rm.principal_id
                                        WHERE sl.[name] = @name
                                         AND  rm.[Role] = @RoleName)
                            BEGIN 
                                SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @RoleName + ''' ' 
                                PRINT @tmpstr 
                            END 

                        SELECT @RoleName = 'dbcreator'
                        IF EXISTS ( SELECT  * 
                                        FROM #Server_Logins sl
                                            INNER JOIN #RoleMembers rm
                                                ON sl.principal_id = rm.principal_id
                                        WHERE sl.[name] = @name
                                         AND  rm.[Role] = @RoleName)
                            BEGIN 
                                SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @RoleName + ''' ' 
                                PRINT @tmpstr 
                            END 

                        SELECT @RoleName = 'bulkadmin'
                        IF EXISTS ( SELECT  * 
                                        FROM #Server_Logins sl
                                            INNER JOIN #RoleMembers rm
                                                ON sl.principal_id = rm.principal_id
                                        WHERE sl.[name] = @name
                                         AND  rm.[Role] = @RoleName)
                            BEGIN 
                                SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @RoleName + ''' ' 
                                PRINT @tmpstr 
                            END 

                        FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @binpwd, @dfltdb, @IsSQLLogin, @IsPolChk, @IsExpChk
                    END 
            END 

    CLOSE login_curs 
    DEALLOCATE login_curs 
    RETURN 0 

END
GO
EXEC sp_help_revlogin 
    @include_db = 1, 
    @include_role = 1
GO

IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL 
DROP PROCEDURE sp_help_revlogin 
GO 

IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL 
DROP PROCEDURE sp_hexadecimal 
GO 
