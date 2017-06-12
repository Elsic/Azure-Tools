
function Connect-OfficeOnline($mycredfile){
    
    $MyCred = Import-Clixml  $mycredfile
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $mycred -Authentication Basic -AllowRedirection
    #$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.protection.outlook.com/powershell-liveid/ -Credential $mycred -Authentication Basic -AllowRedirection
    Import-PSSession $Session -AllowClobber

}


#Connect-OfficeOnline -mycredfile "C:\Users\Ove\SkyDrive\Dokumenter\Powershell\Credentials\skogdata.xml"
#Connect-OfficeOnline -mycredfile "C:\Users\Ove\SkyDrive\Dokumenter\Powershell\Credentials\bwo.xml"
#Connect-OfficeOnline -mycredfile "C:\Users\Ove\SkyDrive\Dokumenter\Powershell\Credentials\byggma2.xml"
#Connect-OfficeOnline -mycredfile "C:\Users\Ove\SkyDrive\Dokumenter\Powershell\Credentials\bwo-goliath.xml"
#Connect-OfficeOnline -mycredfile "C:\users\Ove\SkyDrive\Dokumenter\Powershell\Credentials\frogn.xml"
Connect-OfficeOnline -mycredfile "C:\users\Ove\SkyDrive\Dokumenter\Powershell\Credentials\volmax.xml"