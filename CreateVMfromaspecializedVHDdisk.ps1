## Global
$rgName = "stpFIM"
$location = "westeurope"

## Storage
$storageName = "stpfim3413"
$storageType = "Standard_LRS"

## Network
$nicname = "stp-brfim01-nic1"
$subnet1Name = "BackEnd"
$vnetName = "vnet-stp"
$vnetAddressPrefix = "10.0.0.0/16"
$vnetSubnetAddressPrefix = "10.0.0.0/24"

## Compute
$vmName = "stp-brfim01"
$computerName = "stp-brfim01"
$vmSize = "Standard_D1"
#$osDiskName = "https://stpfim3413.blob.core.windows.net/vhds/STP-BRFIM01.vhd"
$osDiskName = "STP-BRFIM01"

$datadiskname = "https://stpfim3413.blob.core.windows.net/vhds/STP-BRFIM01-Datadisk.vhd"

#Resgrp
#New-AzureRmResourceGroup -Name $rgName -Location $location

#storage
#$storageacc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $storageName -Type $storageType -Location $location
$storageacc = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $storageName
#Network
$pip = New-AzureRmPublicIpAddress -Name $nicname -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic
$subnetconfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $vnetSubnetAddressPrefix
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnetconfig
$nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName "stpNetwork"
#$nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id
$nic = Get-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName


#Compute
## Setup local VM object
$cred = Get-Credential
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$osDiskUri = "https://stpfim3413.blob.core.windows.net/vhds/STP-BRFIM01.vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption Attach -Windows

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm -Verbose -Debug