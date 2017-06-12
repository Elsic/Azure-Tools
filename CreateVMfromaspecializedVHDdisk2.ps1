## Global
$rgName = "stpFIM"
$location = "westeurope"

## Storage
$storageName = "stpfim3413"
$storageType = "Standard_LRS"

## Network
$nicname = "stp-dmzadlds-nic1"
$subnet1Name = "DMZ"
$vnetName = "vnet-stp"


## Compute
$vmName = "stp-dmzadlds"
$computerName = "stp-dmzadlds"
$vmSize = "Standard_D1"
$osDiskName = "STP-DMZADLDS_disk_1.vhd"


#storage
$storageacc = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $storageName
#Network

$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName "stpNetwork"
#$nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id
$nic = Get-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName


#Compute
## Setup local VM object
$cred = Get-Credential
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$osDiskUri = "https://stpfim3413.blob.core.windows.net/vhds/STP-DMZADLDS_disk_1.vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption Attach -Windows

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm -Verbose -Debug