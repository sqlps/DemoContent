ECHO "Press any key to start demo..."
pause

start sqlcmd -S -U admindba -P admindba -d AdventureWorks2014 -i "QueryLoop.sql"

start sqlcmd -SSQL201601-ctp32 -U admindba -P admindba -d AdventureWorks2014 -i "Different_Query_Executions.sql"

start sqlcmd -SSQL201601-ctp32 -U admindba -P admindba -d AdventureWorks2014 -i "RecompileLoop.sql"

ECHO "Press any key to stop demo..."
pause

REM Kill any sqlcmd.exe instances
taskkill /F /IM sqlcmd.exe  %NULLREDIRECT%
