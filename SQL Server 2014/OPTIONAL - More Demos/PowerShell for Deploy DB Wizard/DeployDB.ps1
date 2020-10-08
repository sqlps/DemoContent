# Please find PS script below. Note: I’ve removed credentials and changed machine FQDN to the fake one. Feel free to update those to what you need.

# preparation
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

$secureWindowsPassword =  ConvertTo-SecureString "real password goes here" -asPlainText -Force;
# end of preparation
cls


Import-Module sqlps -DisableNameChecking;

$secureWindowsPassword1 =  ConvertTo-SecureString "MySuperPassword" -asPlainText -Force;

$windowsCredential = New-Object System.Management.Automation.PSCredential("demo admin username goes here", $secureWindowsPassword);

Get-SqlInstance -Credential $windowsCredential -MachineName "mydemomachine.cloudapp.net" -AcceptSelfSignedCertificate -ManagementPublicPort 11435
