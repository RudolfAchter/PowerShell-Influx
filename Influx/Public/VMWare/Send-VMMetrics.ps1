﻿Function Send-VMMetrics {
    <#
        .SYNOPSIS
            Sends Virtual Machine metrics to Influx.

        .DESCRIPTION
            By default this cmdlet sends metrics for all Virtual Machines returned by Get-VM.

        .PARAMETER Measure
            The name of the measure to be updated or created.

        .PARAMETER Tags
            An array of virtual machine tags to be included. Default: 'Name','Folder','ResourcePool','PowerState','Guest','VMHost'

        .PARAMETER VMs
            One or more Virtual Machines to be queried.

        .EXAMPLE
            Send-VMMetrics -Measure 'TestVirtualMachines' -Tags Name,ResourcePool -Hosts TestVM*
            
            Description
            -----------
            This command will submit the specified tag and common VM host data to a measure called 'TestVirtualMachines' for all VMs starting with 'TestVM'
    #>  
    [cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [String]
        $Measure = 'VirtualMachine',

        [String[]]
        $Tags = ('Name','Folder','ResourcePool','PowerState','Guest','VMHost'),

        [String[]]
        $VMs = '*'
    )

    Write-Verbose 'Getting VMs..'
    $VMs = Get-VM $VMs

    Write-Verbose 'Getting VM statistics..'
    $Stats = $VMs | Get-Stat -MaxSamples 1 -Common | Where {-not $_.Instance}

    foreach ($VM in $VMs) {
        
        $TagData = @{}
        ($VM | Select $Tags).PSObject.Properties | ForEach-Object { $TagData.Add($_.Name,$_.Value) }

        $Metrics = @{}
        $Stats | Where-Object { $_.Entity.Name -eq $VM.Name } | ForEach-Object { $Metrics.Add($_.MetricId,$_.Value) }

        Write-Verbose "Sending data for $($VM.Name) to Influx.."
        Write-Verbose $TagData
        Write-Verbose $Metrics

        if ($PSCmdlet.ShouldProcess($VM.name)) {
            Write-Influx -Measure $Measure -Tags $TagData -Metrics $Metrics
        }
    }
}