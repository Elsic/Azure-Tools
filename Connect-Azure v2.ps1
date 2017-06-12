
function Connect-Azure($mycredfile){
    

    $MyCred = Import-Clixml $mycredfile

    Add-AzureAccount -Credential $mycred 

}



Connect-Azure -mycredfile "C:\Users\Ove\SkyDrive\Dokumenter\Powershell\Credentials\dms.xml"

Get-AzureSubscription | select SubscriptionName,SubscriptionId