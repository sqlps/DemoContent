ECHO "Press any key to start demo..."
pause

start sqlcmd -Sacr0ez0it7.database.windows.net-U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "QueryLoop.sql"

start sqlcmd -Sacr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "Different_Query_Executions.sql"

start sqlcmd -Sacr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "RecompileLoop.sql"

REM PING 1.1.1.1 -n 1 -w 60000 >NUL

start sqlcmd -Sacr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "DifferentPlanShapes.sql"

REM PING 1.1.1.1 -n 1 -w 60000 >NUL

start sqlcmd -Sacr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "SARGabilityExamples.sql"

start sqlcmd -Sacr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "Missing_Index.sql"

start sqlcmd -Sacr0ez0it7.database.windows.net -U admindba -P Vegasbaby!9 -d AdventureWorks2014 -i "AllTbls_AdvWorksDW2014_auditb"


ECHO "Press any key to stop demo..."
pause

REM Kill any sqlcmd.exe instances
taskkill /F /IM sqlcmd.exe  %NULLREDIRECT%
