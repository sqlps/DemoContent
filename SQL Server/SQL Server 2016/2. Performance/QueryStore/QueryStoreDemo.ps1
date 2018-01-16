import-module sqlps | out-null
cls

$ServerInstance = "PankajTSP-SQL01"
$DBName = "AdventureWorks2016CTP3"
$counter = 0
Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DBName -Query "DBCC FREEPROCCACHE"
#Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DBName -Query "ALTER DATABASE [Adventureworks2016CTP3] SET QUERY_STORE = ON"ON_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 367), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 1, MAX_STORAGE_SIZE_MB = 100, QUERY_CAPTURE_MODE = ALL, SIZE_BASED_CLEANUP_MODE = OFF)"
Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DBName -Query "ALTER DATABASE $DBName SET QUERY_STORE CLEAR"

While ($Counter -lt 10)
{
    $Duration = Measure-Command {Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DBName -Query "EXECUTE Sales.GetSalesOrderByCountry 'US';"}
    Write-Host "Query ran in" $Duration.seconds "(s)" $Duration.Milliseconds "(ms)"
    sleep .5
    $counter ++
#Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DBName -Query "ALTER DATABASE [Adventureworks2016CTP3] SET QUERY_STORE (OPERATI
}
Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DBName -Query "DBCC FREEPROCCACHE"
write-host "Introducing a bad plan" -ForegroundColor Red
$Duration = Measure-Command {Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DBName -Query "EXECUTE Sales.GetSalesOrderByCountry 'TT';"}
Write-Host "Query ran in" $Duration.seconds "(s)" $Duration.Milliseconds "(ms)"
While ($Counter -lt 1000)
{
    $Duration = Measure-Command {Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DBName -Query "EXECUTE Sales.GetSalesOrderByCountry 'US';"}
    Write-Host "Query ran in" $Duration.seconds "(s)" $Duration.Milliseconds "(ms)"
    sleep .5
    $counter ++
}


