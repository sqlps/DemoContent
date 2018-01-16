@Echo Off
ECHO Preparing the environment...

REM - Get current directory
SET SUBDIR=%~dp0

REM - Run SQL Script to prepare the database environment

iisreset > NUL
SQLCMD -E -i %SUBDIR%inMem_Setup.sql > NUL
SQLCMD -E -i %SUBDIR%OA_Setup.sql > NUL
SQLCMD -E -i %SUBDIR%OACSCall.sql > NUL

ECHO Completed!!!
pause