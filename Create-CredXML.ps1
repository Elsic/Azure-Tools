# Create a xml file with credentials

$userName = Read-host "<your organizational account user name>"
$password = Read-Host "Enter password" -AsSecureString
$file = Read-host "Enter filepath and name (ie: c:\script\cred.xml)"


$cred = New-Object System.Management.Automation.PSCredential($userName, $Password) | Export-Clixml $file
