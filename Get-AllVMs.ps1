############################################################################
###                           Get-AllVMs.ps1                             ###
###   Gets all objects (VMs) being backed up by all Veeam Backup Jobs    ###
### Cross Reference with vCenter List to see what is not being backed up ###
###                   Created by: RJ Hari on 2/22/2018                   ###
############################################################################
Import-Module VMware.VimAutomation.Core
Add-PSSnapin VeeamPSSnapin

## User Inputs - MUST ENTER INFORMATION BEFORE RUNNING SCRIPT##
$vcenter = ""
$veeam = ""

## Connect to Servers ##
Connect-VIServer $vcenter
Connect-VBRServer -Server $veeam

## Create VM List ##
$vmlist = @()

## Get List of VMs from vCenter ##
$vcentervms = Get-VM

## Get all Veeam VMs from Backup ##
$jobs = Get-VBRJob | Where-Object {$_.JobType -eq "Backup"} ## Select All Non-Copy Jobs
$jobs | ForEach-Object {
    $job= $_
    $backups = Get-VBRBackup -Name $_.name
    $backups | ForEach-Object {
        $backup = $_
        $objects = $backup.GetObjects()
        $objects | ForEach-Object {
            $object = $_
            $vmlist  += New-Object -TypeName psobject -Property @{VM=$object.Name;
                Job=$job.Name;
             }
        }
    }
}

## Check if vCenter VM is in a Veeam Backup ##
$vcentervms | ForEach-Object {
    $vm = $_
    If ($vm.name -inotin $vmlist.vm) {
        $vmlist += New-Object -TypeName psobject -Property @{VM=$vm.name;
            Job="Not in a Veeam Backup!"
        }
    }    
}

## Display Results ##
$vmlist | Out-GridView

## Disconnect from Veeam Server ##
Disconnect-VBRServer
