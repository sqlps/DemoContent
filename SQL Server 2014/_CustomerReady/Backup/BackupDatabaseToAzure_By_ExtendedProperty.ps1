import-module sqlps -DisableNameChecking
# set the parameter values
$Server = 'SQL2014-SQL1'
$backupUrlContainer = "https://something.blob.core.windows.net/sqlbackups/"
$credentialName = "BackuptoURL"
If ($Server -notlike '*\*'){$Instancename = "$Server\DEFAULT"}ELSE{$Instancename = $Server}
$Databases = DIR "SQLServer:\SQL\$Instancename\Databases" | ? {$_.isaccessible -eq $true}
$TSQL = "Select value from sys.extended_properties where class = 0 and name = 'BackupType'"
CD "SQLServer:\SQL\$Instancename"

ForEach($Database in $Databases)
{
    $BackupType = Invoke-sqlcmd -ServerInstance $Server -Query $TSQL -Database $Database.Name -SuppressProviderContextWarning
    If($Backuptype.value -eq 'Azure' )
    {
        $backupFile = $backupUrlContainer + "$Database" +"_"+ (Get-Date).ToString("s").Replace("-","_").Replace(":", "_").Replace(" ","_").Replace("/", "_") +  ".bak"
        write-host "Backing up $Database to $backupfile" -ForegroundColor Green
        Backup-SqlDatabase -Database $Database.name -backupFile $backupFile  -SqlCredential $credentialName -CompressionOption On -BackupAction Database -CopyOnly
    }
 }   
