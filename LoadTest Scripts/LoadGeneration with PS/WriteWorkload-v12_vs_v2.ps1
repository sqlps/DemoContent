cls

$ErrorActionPreference = "Stop"

<#################################################### 
 # BEGIN VARIABLE MODIFICATION FOR YOUR ENVIRONMENT #
 ####################################################>
$RunTimeInMins = 2
$RefreshInterval = 5
$Loops = ($RunTimeInMins * 60)/ $RefreshInterval
$PBIModulePath = 'C:\Demos\Azure\LoadGeneration\PBIModule'
$ostressquerytimeout = 10 #seconds
$LoadTestDashboardURL = 'https://msit.powerbi.com/dashboards/9c231499-3761-4464-bb8c-c8f1bf236dd2'
# Get the authentication token using ADAL library (OAuth)
$authToken = Get-PBIAuthToken -clientId "7a7be4f7-c64d-41da-94db-7fb8200f029c"

$BaselineServer = 'zbqfsz8os9.database.windows.net' #'e9jsqjg8kf.database.windows.net'
$BaselineDB = 'Adventureworks2014'
$BaselineThreads = 10
$BaselineRuns = 10
$BaselineWorkloadName = 'RowsInserted-S1-v2'
$BaselineParams = "-Q""LoadTest.usp_InsertWorkload '$BaselineWorkloadName'"" -S""$BaselineServer"" -d$BaselineDB -U"+$cred.UserName+" -P"+$cred.GetNetworkCredential().password+" -t$ostressquerytimeout -o""$BaselineWorkloadName"" -q -n$BaselineThreads -r$BaselineRuns"

$CompareServer = 'zbqfsz8os9.database.windows.net'
$CompareDB = 'AdventureWorks2014_Premium'
$CompareThreads = 10
$CompareRuns = 10
$CompareWorkloadName = 'RowsInserted-S1-v12'
$CompareParams = "-Q""LoadTest.usp_InsertWorkload '$CompareWorkloadName'"" -S""$CompareServer"" -d$CompareDB -U"+$cred.UserName+" -P"+$cred.GetNetworkCredential().password+" -t$ostressquerytimeout -o""$CompareWorkloadName"" -q -n$CompareThreads -r$CompareRuns"

<################################################## 
 # END VARIABLE MODIFICATION FOR YOUR ENVIRONMENT #
 ##################################################>

$cred = Get-Credential

Import-Module "$PBIModulePath\PowerBIPS.psm1" -Force
Import-module SQLPS -DisableNameChecking

# Test the existence of the dataset1
if (-not (Test-PBIDataSet -authToken $authToken -dataSetName "LoadTestDataSet1"))
{
	# If cannot find the DataSet create a new one with this schema
	
	$dataSetSchema = @{
		name = "LoadTestDataSet1"	
	    ; tables = @(
			@{ 	name = "Results"
				; columns = @( 
                            @{ name = "TestScenario"; dataType = "String"}
                          , @{ name = "CollectionTime"; dataType = "DateTime"  }					
                            @{ name = "CurrentExecutionCount"; dataType = "Int64"  }
                            @{ name = "Batch_Requests_per_sec"; dataType = "Int64"  }
                            @{ name = "Connections"; dataType = "Int64"  }
                            @{ name = "dm_db_resource_stats__end_time"; dataType = "datetime"  }
                            @{ name = "Avg_cpu_percent"; dataType = "double"  }
                            @{ name = "Avg_data_io_percent"; dataType = "double"  }					
                            @{ name = "Avg_log_write_percent"; dataType = "double"  }					
                            @{ name = "Avg_memory_usage_percent"; dataType = "double"  }					                          
					) 
			})
	}	
	
	$createdDataSet = New-PBIDataSet -authToken $authToken -dataSet $dataSetSchema -Verbose
}
else
{
	# Clear all the rows of the dataset table	
	Clear-PBITableRows -authToken $authToken -dataSetName "LoadTestDataSet1" -tableName "Results" -Verbose
}

# Test the existence of the dataset2
if (-not (Test-PBIDataSet -authToken $authToken -dataSetName "LoadTestDataSet2"))
{
	# If cannot find the DataSet create a new one with this schema
	
	$dataSetSchema = @{
		name = "LoadTestDataSet2"	
	    ; tables = @(
			@{ 	name = "Results"
				; columns = @( 
                            @{ name = "TestScenario"; dataType = "String"}
                          , @{ name = "CollectionTime"; dataType = "DateTime"  }					
                            @{ name = "CurrentExecutionCount"; dataType = "Int64"  }
                            @{ name = "Batch_Requests_per_sec"; dataType = "Int64"  }
                            @{ name = "Connections"; dataType = "Int64"  }
                            @{ name = "dm_db_resource_stats__end_time"; dataType = "datetime"  }
                            @{ name = "Avg_cpu_percent"; dataType = "double"  }
                            @{ name = "Avg_data_io_percent"; dataType = "double"  }					
                            @{ name = "Avg_log_write_percent"; dataType = "double"  }					
                            @{ name = "Avg_memory_usage_percent"; dataType = "double"  }					                          
					) 
			})
	}	
	
	$createdDataSet = New-PBIDataSet -authToken $authToken -dataSet $dataSetSchema -Verbose
}
else
{
	# Clear all the rows of the dataset table	
	Clear-PBITableRows -authToken $authToken -dataSetName "LoadTestDataSet2" -tableName "Results" -Verbose
}


$Counter = 1
Invoke-Sqlcmd -ServerInstance $BaselineServer -Database $BaseLineDB -Username $cred.UserName -Password $cred.GetNetworkCredential().password -Query "exec LoadTest.usp_ResetTables" 
Invoke-Sqlcmd -ServerInstance $CompareServer -Database $CompareDB -Username $cred.UserName -Password $cred.GetNetworkCredential().password -Query "exec LoadTest.usp_ResetTables"

#Kickoff Workload
$program = "C:\Program Files\Microsoft Corporation\RMLUtils\ostress.exe"
$arguments = "$BaselineParams"
Start-Process -FilePath "$program" -ArgumentList "$arguments"

$program = "C:\Program Files\Microsoft Corporation\RMLUtils\ostress.exe"
$arguments = "$CompareParams"
Start-Process -FilePath "$program" -ArgumentList "$arguments"


#Open PowerBi Report
$ie = New-Object -ComObject InternetExplorer.Application
$ie.Navigate($LoadTestDashboardURL)
$ie.Visible = $true
#>
Do 
{
    # Read Load Test Data
    $Results1 = Invoke-Sqlcmd -ServerInstance $BaselineServer -Database $BaselineDB -Username $cred.UserName -Password $cred.GetNetworkCredential().password -Query "exec LoadTest.usp_GetPerfMetrics '$BaselineWorkloadName'"
    $Results2 = Invoke-Sqlcmd -ServerInstance $CompareServer  -Database $CompareDB -Username $cred.UserName -Password $cred.GetNetworkCredential().password -Query "exec LoadTest.usp_GetPerfMetrics '$CompareWorkloadName'"

    # Insert the sample rows in batches of 10
    $Results1 | Add-PBITableRows -authToken $authToken -dataSetName "LoadTestDataSet1" -tableName "Results" -batchSize 1000 -Verbose 
    $Results2 | Add-PBITableRows -authToken $authToken -dataSetName "LoadTestDataSet2" -tableName "Results" -batchSize 1000 -Verbose

    $Counter += 1
    sleep -Seconds $RefreshInterval

} While ($Counter -lt $Loops)