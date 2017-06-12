
function Connect-Azure($username,$password){
    

    #$userName = "<your organizational account user name>"
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($userName, $securePassword)
    Add-AzureAccount -Credential $cred 

}


$username = "ovs-cloudadmin@Skogdata.onmicrosoft.com"
$password = "Farenheit451"
Connect-Azure -username $username -password $password

Get-AzureSubscription | select SubscriptionName,SubscriptionId