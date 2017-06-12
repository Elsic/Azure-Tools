
function Connect-AzureAD($mycredfile){
    
    $MyCred = Import-Clixml  $mycredfile
    Connect-MsolService -Credential $MyCred
}

Connect-AzureAD -mycredfile "C:\Users\Ove\SkyDrive\Dokumenter\Powershell\Credentials\bwo.xml"