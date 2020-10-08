ECHO "Press any key to start demo..."
pause

start sqlcmd -S acr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "NewRandom.sql"

start sqlcmd -S acr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "QueryLoop.sql"

start sqlcmd -S acr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "Different_Query_Executions.sql"

start sqlcmd -S acr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "RecompileLoop.sql"

ECHO "Press any key to stop demo..."
pause

REM Kill any sqlcmd.exe instances
taskkill /F /IM sqlcmd.exe  %NULLREDIRECT%
