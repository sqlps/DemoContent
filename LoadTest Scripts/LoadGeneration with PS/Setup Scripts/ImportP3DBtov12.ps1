#Script from http://blogs.msdn.com/b/shashankyerramilli/archive/2014/02/15/import-database-into-azure-using-azure-power-shell.aspx

#MSDN
<#
Import-AzurePublishSettingsFile 'C:\Users\pansaty\OneDrive - Microsoft\Azure\Pankaj MSDN-02-10-2015-credentials.publishsettings'
$StorageAccountName = 'pankajtspmsdn' 
$ServerName = 'pankajtspmsdn'
Select-AzureSubscription 'Windows Azure MSDN - Visual Studio Ultimate'
#>


#MSInternal
#<#
Import-AzurePublishSettingsFile 'C:\Demos\Azure\Microsoft Azure Internal Consumption-10-27-2014-credentials.publishsettings'
$StorageAccountName = 'pankajtsp' 
$ServerName= 'zbqfsz8os9' #v12
Select-AzureSubscription 'Microsoft Azure Internal Consumption'
##>

# 1) Import Azure Credential


# 2) Variables to be set
$DatabaseName = "Adventureworks2014_Premium"
$ContainerName = "sqlbackups"

#$ServerName = 'zbqfsz8os9'#v12. As of 01/27/2015 you cannot run Start-AzureSQLDatabaseImport on v12 machines. SQLConnectionContext errors
$Blobname = 'Adventureworks2014_Premium.bacpac'

# 3) Hook up storage
# fetching the Key from the storage account. this is needed to set the context.
$storageAccountKey = Get-AzureStorageKey $StorageAccountName | %{ $_.Primary }
#get storage context
$StorageCtx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey
# Create a new Server to upload the database. If you have an exisiting server skip creating new server and use servername directly in the next step.
$server = Get-AzureSqlDatabaseServer -ServerName $ServerName
# creating fully qualified servername
$fqServerName = $server.ServerName + ".database.windows.net"

# 4) Configure Firewall rules
<# to manage the database we have to add the current ip address to the list of allowed ip addresses to the list.
# using the .Net web client object to get the ip address ad adding it as firewall rule
$wc=New-Object net.webclient
$ip = $wc.downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]" 
# fetchng todays date
$todaysdatetime = Get-Date
# creating a firewall rule name with a timestamp of todays date.
$firewallRulename = "ClientIpAddress" + $todaysdatetime.Year +"-" + $todaysdatetime.Month +"-" + $todaysdatetime.Day +"-" + $todaysdatetime.Hour +"-" + $todaysdatetime.Minute +"-"+ $todaysdatetime.Second +"-" + $todaysdatetime.Millisecond 
#add the firewall rule
$server | New-AzureSqlDatabaseServerFirewallRule -RuleName $firewallRulename -StartIPAddress $ip -EndIPAddress $ip 
# making the server to allow azure services
#######$server | New-AzureSqlDatabaseServerFirewallRule -AllowAllAzureServices
#>

# 5) Create Blank DB to restore to 
# create a new datavase. which is a web edition/ you can also create database with business edition.
$ServiceObjective = Get-AzureSQLDatabaseServiceObjective $ServerName -ServiceObjectiveName 'P3'
$database = New-AzureSqlDatabase -ServerName $server.ServerName -DatabaseName $DatabaseName -Edition "Premium" -MaxSizeGB 1 -ServiceObjective $ServiceObjective


# 6) Connect to SQL Instance and import bacpac file
$credential = Get-Credential
$SqlCtx = New-AzureSqlDatabaseServerContext -ServerName $server.ServerName -Credential $credential
#get the container not variable
$Container = Get-AzureStorageContainer -Name $ContainerName -Context $StorageCtx
#import the bacpac file uploaded into the databse name mentioned.
$importRequest = Start-AzureSqlDatabaseImport -SqlConnectionContext $SqlCtx -StorageContainer $Container -DatabaseName $DatabaseName -BlobName $BlobName

# 7) Status
Do
{
    $Status = Get-AzureSqlDatabaseImportExportStatus $importRequest  
    write-host $Status.Status -ForegroundColor green
    sleep 2
} while(($status.status -ne 'Completed') -and ($Status.status -ne 'failed')   )
# 8) Cleanup
# Remove-AzureSqlDatabase -ServerName $ServerName -DatabaseName $DatabaseName