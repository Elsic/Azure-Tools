# Parameter

$ResourceGroup = "migrationTest"
$VMName = "MyVM2"
$Location = "West Europe"
$VMSize = "Standard_DS2_v2"

#$PremiumstorageAccountName = "sjvmstrarge247" # must all be lower letters
#$ReUsePremiumstorageAccount = 1

$JustOSDisk = 0 # 0 will migrate all Disks, 1 will migrate OS disk only (Other disks will not be attached)


cls

## #####################################################################################################################################################
## #####################################################################################################################################################
function CopyVHD(){

    Param ([string]$srcStorageAccount, [string]$srcStorageKey, [string]$srcUri , [string]$destStorageAccount, [string]$destStorageKey)


    ### Source Storage Account ###
    #$srcStorageAccount
    #$srcStorageKey
 
    ### Target Storage Account ###
    #$destStorageAccount
    #$destStorageKey
 
    ### Create the source storage account context ### 
    $srcContext = New-AzureStorageContext  –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey  
 
    ### Create the destination storage account context ### 
    $destContext = New-AzureStorageContext  –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey  
 
    ### Destination Container Name ### 
    $containerName = "vhds"
 
    ### Create the container on the destination ### 
    #New-AzureStorageContainer -Name $containerName -Context $destContext
 
    ### Start the asynchronous copy - specify the source authentication with -SrcContext ###
    [string]$destVHD = Split-Path $srcUri -leaf
    $blobCopy = Start-AzureStorageBlobCopy -AbsoluteUri $srcUri -SrcContext $srcContext -DestContainer $containerName -DestBlob $destVHD -DestContext $destContext

    AzCopy /Source:https://sourceaccount.blob.core.windows.net/mycontainer1 /Dest:https://destaccount.blob.core.windows.net/mycontainer2 /SourceKey:key1 /DestKey:key2 /Pattern:abc.txt


    ### Retrieve the current status of the copy operation ###
    #$status = $blob1 | Get-AzureStorageBlobCopyState 
 
    ### Print out status ### 
    #$status 
 
    ### Loop until complete ###                                    
    <#
    While($status.Status -eq "Pending"){
      $status = $blob1 | Get-AzureStorageBlobCopyState 
      Start-Sleep 10
      ### Print out status ###
      #$status.BytesCopied + " of " + $status.TotalBytes + "(" + ((($status.BytesCopied/$status.TotalBytes)*100)) + ")"
      $status = "Copied " + $status.BytesCopied + " Of " + $status.TotalBytes + " (" + [int](($status.BytesCopied/$status.TotalBytes)*100) + "%)"
      Write-Host $status
    }
    #>
    
    $TotalBytes = ($blobCopy | Get-AzureStorageBlobCopyState).TotalBytes
    while(($blobCopy | Get-AzureStorageBlobCopyState).Status -eq "Pending")
    {
        Start-Sleep 10
        $BytesCopied = ($blobCopy | Get-AzureStorageBlobCopyState).BytesCopied
        $PercentCopied = [math]::Round($BytesCopied/$TotalBytes * 100,2)
        Write-Progress -Activity "Copy in Progress" -Status "$PercentCopied% Complete:" -PercentComplete $PercentCopied
    }

    return (Get-AzureStorageBlob -Context $destContext -blob $destVHD -Container $containerName).ICloudBlob.uri.AbsoluteUri

}
## #####################################################################################################################################################
## #####################################################################################################################################################


$D = Get-Date
Write-host $D " -- Starting the migration ..."

#region Login to Azure
$RMContext = Get-AzureRmContext -ErrorAction SilentlyContinue
if (!$RMContext)
{
    Login-AzureRmAccount
}
#endregion

#region Pick Subscription/TenantID
$AzureInfo = 
    (Get-AzureRmSubscription `
        -ErrorAction Stop |
     Out-GridView `
        -Title 'Select a Subscription/Tenant ID for deployment...' `
        -PassThru)

# Select Subscription
Select-AzureRmSubscription `
    -SubscriptionId $AzureInfo.SubscriptionId `
    -TenantId $AzureInfo.TenantId `
    -ErrorAction Stop| Out-Null
#endregion


## TEST
#$VM = Get-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName
#Add-AzureRmVMNetworkInterface -vm $VM -id "/subscriptions/c4fca468-9e9a-460f-bedd-227645181b42/resourceGroups/migrationTest/providers/Microsoft.Network/networkInterfaces/test1"
#Update-​Azure​Rm​VM -ResourceGroupName $ResourceGroup -VM $VM

## --------------------------------------------


######################################################################################################
$PremiumstorageAccountName = $StorageNameOS.Substring(0,15) + "prem583"
#Check if the storage Account is available and create if not exists
$check = Get-AzureRmStorageAccountNameAvailability -Name $PremiumstorageAccountName
$D = Get-Date
if(!($check.NameAvailable))
{
    Write-host $D " -- The Premium Storage Account (" $PremiumstorageAccountName ") is not available (or an account already ceated with the same name)."
    Write-host $D " -- Change the name and run the script again!"
    return
}
else
{
    $D = Get-Date
    Write-host $D " -- The Premium Storage Account (" $PremiumstorageAccountName ") is available (the name not in use)."
    Write-host $D " -- Start creating the Premium Storage Account (" $PremiumstorageAccountName ") in The Resource Group (" $ResourceGroup ")..."
    $check = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Location $Location -Name $PremiumstorageAccountName -Type "Premium_LRS"

    if((Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -AccountName $PremiumstorageAccountName))
    {
        $D = Get-Date
        Write-host $D " -- The Premium Storage Account (" $PremiumstorageAccountName ") was created in The Resource Group (" $ResourceGroup ")."
    }
    else
    {
        $D = Get-Date
        Write-host $D " -- The Premium Storage Account (" $PremiumstorageAccountName ") was NOT created in The Resource Group (" $ResourceGroup ")!"
    }
}


#Create a context to the storage account
$StorageKey = (Get-AzureRmStorageAccountKey -Name $PremiumstorageAccountName -ResourceGroupName $ResourceGroup).Value[0]
$StorageContext = new-azurestoragecontext -storageaccountname $PremiumstorageAccountName -storageaccountkey $StorageKey
$check = Get-AzureStorageContainer -Context $StorageContext | Where-Object { $_.Name -eq "vhds" }

#Create Container if not exists
if(!($check))
{
    New-AzureStorageContainer -Name "vhds" -Context $StorageContext
    $D = Get-Date
    Write-host $D " -- The Container was created."
}
else
{
    $D = Get-Date
    Write-host $D " -- The Container ( vhds) already exists in StorageAccount (" $PremiumstorageAccountName ")."
}
######################################################################################################>


$PremiumStorageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroup -AccountName $PremiumstorageAccountName).value[0]

# Read the VM
$VM = Get-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName

### Read the OSDisk and Storage Name/Key from VM
$VMOSName = $vm.StorageProfile.OsDisk.Name
$VMOSUri =  [System.Uri]$vm.StorageProfile.OsDisk.Vhd.Uri
$VMOSCaching = $VM.StorageProfile.OsDisk.Caching
$StorageNameOS = $VMOSUri | ForEach-Object { $_.host.split(".")[0] }
$VMOSUri = $VMOSUri.AbsoluteUri
$StorageKeyOS = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroup -AccountName $StorageNameOS).value[0]



$D = Get-Date
Write-host $D " -- Premium Storage Account Name (" $PremiumstorageAccountName ")."
Write-host $D " -- Premium Storage Account Key (" $PremiumStorageKey ")"

Write-host $D " -- VM Storage Account Name (" $StorageNameOS ")."
Write-host $D " -- VM Storage Account Key (" $StorageKeyOS ")"

Write-host $D " -- VM OD Disk Name (" $VMOSName ")."
Write-host $D " -- VM OD Disk Uri (" $VMOSUri ")"



### Read the Network from VM
$Int = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroup | Where-Object {$_.VirtualMachine.Id -eq $VM.Id}

$D = Get-Date
Write-host $D " -- VM Storage Network Interface Name (" $Int.Name ")."
Write-host $D " -- VM Storage Network Interface ID (" $Int.Id ")"


# check the VM status
$VMStatus = Get-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName -Status | select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | select -ExpandProperty DisplayStatus

$VMStatus
$D = Get-Date
Write-host $D " -- VM Status (" $VMStatus ")."


if($VMStatus -eq "VM running")
{
    $D = Get-Date
    Write-host $D " -- Stopping (" $VMName ") ..."
    Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName -force
    $D = Get-Date
    Write-host $D " -- The (" $VMName ") was stoped."
    $D = Get-Date
    Write-host $D " -- Removing (" $VMName ") ..."
    Remove-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName -force
    $D = Get-Date
    Write-host $D " -- The (" $VMName ") was removed."
}

if($VMStatus -eq "VM deallocated")
{
    $D = Get-Date
    Write-host $D " -- Removing (" $VMName ") ..."
    Remove-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName -force
    $D = Get-Date
    Write-host $D " -- The (" $VMName ") was removed."
}


# Copy the Os Disk
$D = Get-Date
Write-host $D " -- Copying OS Disk (" $VMOSName ") to Premium Storage Account (" $PremiumstorageAccountName ") ..."
$PremiumOSDiskUri = CopyVHD -srcStorageAccount $StorageNameOS -srcStorageKey $StorageKeyOS -srcUri $VMOSUri -destStorageAccount $PremiumstorageAccountName -destStorageKey $PremiumStorageKey
$D = Get-Date
Write-host $D " -- Done!"
Write-host $D " -- New Uri to the OS Disk on the Premium Storage Account is (" $PremiumOSDiskUri ")"

# Copy the Data Disk(s)
$VMPremiumDataDisks = @()   # empty Array
if (!($JustOSDisk))
{
    foreach($vmDisk in $vm.StorageProfile.DataDisks)
    {
        $StorageNameData = [System.Uri]$vmDisk.Vhd.Uri | ForEach-Object { $_.host.split(".")[0] }
        $DiskUri = $vmDisk.Vhd.Uri
        $DataDiskName = Split-Path $DiskUri -leaf
        $DiskCaching = $vmDisk.Caching


        #Write-host  "Storage Name " $StorageNameDisk " : Disk Info: " $vmDisk.Name " : " $DiskUri
        $D = Get-Date
        Write-host $D " -- Copying Data Disk (" $DataDiskName ") to Premium Storage Account (" $PremiumstorageAccountName ") ..."
        $PremiumDataDiskUri =  CopyVHD -srcStorageAccount $StorageNameData -srcStorageKey $StorageKeyOS -srcUri $DiskUri -destStorageAccount $PremiumstorageAccountName -destStorageKey $PremiumStorageKey
        $PremiumDataDiskName = Split-Path $PremiumDataDiskUri -leaf
        $VMPremiumDataDisks += , ($PremiumDataDiskUri,$PremiumDataDiskName,$DiskCaching)
        $D = Get-Date
        Write-host $D " -- Done!"

    }
}


#$NICObjectName = "myvm545"
#$NIC = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroup -Name $NICObjectName
$newVM=$Null
#Build a new VM with the same name and new size
$newVM = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize

$newVM = Add-AzureRmVMNetworkInterface -VM $newVM -Id $Int.Id #$NIC.Id

$PremiumOSDiskName = Split-Path $PremiumOSDiskUri -leaf
#$newVM = Set-AzureRmVMOSDisk -VhdUri $PremiumOSDiskUri -name $PremiumOSDiskName -CreateOption attach -Windows -Caching $VMOSCaching
$newVM | Set-AzureRmVMOSDisk -VhdUri $PremiumOSDiskUri -name $PremiumOSDiskName -CreateOption attach -Windows -Caching $VMOSCaching


$i=0
ForEach($VMDataDisk in $VMPremiumDataDisks){
    #$newVM = Add-AzureRmVMDataDisk -VM $newVM -VhdUri $VMDataDisk[0] -name $VMDataDisk[1] -CreateOption attach -LUN $i  -Caching $VMDataDisk[2]
    $newVM | Add-AzureRmVMDataDisk -VhdUri $VMDataDisk[0] -name $VMDataDisk[1] -CreateOption attach -LUN $i  -Caching $VMDataDisk[2]
    $i++
}

#$VirtualMachine = Add-AzureRmVMDataDisk -VM $VirtualMachine -Name "PetriMigData" -VhdUri $DataDiskUri -Lun 0 -CreateOption attach -DiskSizeInGB $null -Caching "ReadOnly"
## Deploy the new VM from the configuration
# You can comment out the next line to test the above without creating a machine, saving loads of time.
New-AzureRmVM -ResourceGroupName $ResourceGroup -Location $Location -VM $newVM -Verbose

#>