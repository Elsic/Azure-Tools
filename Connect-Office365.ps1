
function Connect-OfficeOnline($username,$password){
    

    $secpass = ConvertTo-SecureString $password -AsPlainText -Force
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secpass

    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection

    Import-PSSession $Session
    Write-Output "Use Connect-OfficeOnline -username <username@something.onmicrosoft.com> -password <password>"

}


$username = "ovs-cloudadmin@Skogdata.onmicrosoft.com"
$password = "Farenheit451"
Connect-OfficeOnline -username $username -password $password