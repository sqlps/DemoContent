ECHO "Press any key to start demo..."
pause

start sqlcmd -Sacr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "Missing_Index.sql"

ECHO "Press any key to stop demo..."
pause

REM Kill any sqlcmd.exe instances
taskkill /F /IM sqlcmd.exe  %NULLREDIRECT%
