#################################################### 
 # BEGIN VARIABLE MODIFICATION FOR YOUR ENVIRONMENT #
 ####################################################>
$wait = 15
$sqlServer = 'cisdfqgav5nmnkgasrv.database.windows.net' #'e9jsqjg8kf.database.windows.net'
$sqldb = 'Adventureworks2012'
$user = 'pankaj79'
$password = 'Pa$$word1234'
$QueryFile = 'C:\Demos\General SQL\Adventureworks-LoadSales.sql'
$counter = 0

do
{
    write-host $counter
    Invoke-sqlcmd -ServerInstance $sqlServer -Database $sqldb -Username $user -Password $password -InputFile $QueryFile
    Start-Sleep -Seconds $Wait;
    $counter+= 1
}
until ($counter -eq 10000)

