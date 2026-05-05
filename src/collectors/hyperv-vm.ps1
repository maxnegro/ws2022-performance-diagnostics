# Raccoglie vitals e integration services delle VM Hyper-V

function Get-HyperVVMVitals {
    $hypervService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if ($null -eq $hypervService -or $hypervService.Status -ne 'Running') {
        Write-Verbose "Hyper-V non rilevato o non attivo su questo host."
        return @()
    }
    $vms = Get-VM
    $vmProcessors = Get-VMProcessor -VMName * | Select-Object VMName, Count, MaximumCountPerNumaNode, MaximumCountPerNumaSocket, HwThreadCountPerCore, CompatibilityForMigrationEnabled, CompatibilityForOlderOperatingSystemsEnabled
    $vmNuma = $vms | Select-Object Name, NumaAligned
    $results = [System.Collections.Generic.List[object]]::new()
    $hostWaitTime = $null
    $vcpuWaitTimes = @()
    $vcpuWaitTimesByVM = @{}
    $hostCPUs = Get-CimInstance -ClassName Win32_Processor | Select-Object DeviceID, NumberOfCores, NumberOfLogicalProcessors, SocketDesignation
    try {
        # Raccolta diretta di tutti i valori vCPU wait time
        $vcpuCounter = Get-Counter -Counter '\Hyper-V Hypervisor Virtual Processor(*)\CPU Wait Time Per Dispatch' -ErrorAction SilentlyContinue
        if ($vcpuCounter.CounterSamples) {
            $vcpuWaitTimes = $vcpuCounter.CounterSamples | ForEach-Object {
                [PSCustomObject]@{
                    InstanceName = $_.InstanceName
                    Value = $_.CookedValue
                }
            }
            # Raggruppa per VM e vCPU
            foreach ($sample in $vcpuCounter.CounterSamples) {
                if ($sample.InstanceName -match "^(.*):hv vp (\\d+)$") {
                    $vmName = $Matches[1]
                    $vpNum = [int]$Matches[2]
                    if (-not $vcpuWaitTimesByVM.ContainsKey($vmName)) {
                        $vcpuWaitTimesByVM[$vmName] = [System.Collections.Generic.List[object]]::new()
                    }
                    $vcpuWaitTimesByVM[$vmName].Add([PSCustomObject]@{
                        VirtualProcessor = $vpNum
                        Value = $sample.CookedValue
                    })
                } elseif ($sample.InstanceName -eq '_total') {
                    $hostWaitTime = $sample.CookedValue
                }
            }
        } else {
            Write-Warning "[HyperV] Nessun CounterSamples trovato per Hyper-V Hypervisor Virtual Processor"
        }
    } catch {}

    foreach ($vm in $vms) {
        $proc = $vmProcessors | Where-Object { $_.VMName -ieq $vm.Name } | Select-Object -First 1
        $numaInfo = $vmNuma | Where-Object { $_.Name -ieq $vm.Name } | Select-Object -First 1
        $entry = $vm | Select-Object @(
            'Name', 'State', 'CPUUsage', 'MemoryAssigned', 'Uptime', 'Status', 'Version', 'ProcessorCount',
            @{Name='CPUWaitTimePerDispatchDetails';Expression={
                if ($vcpuWaitTimesByVM.ContainsKey($_.Name)) { $vcpuWaitTimesByVM[$_.Name] } else { $null }
            }},
            @{Name='VMProcessorCount';Expression={ $proc.Count }},
            @{Name='MaximumCountPerNumaNode';Expression={ $proc.MaximumCountPerNumaNode }},
            @{Name='MaximumCountPerNumaSocket';Expression={ $proc.MaximumCountPerNumaSocket }},
            @{Name='HwThreadCountPerCore';Expression={ $proc.HwThreadCountPerCore }},
            @{Name='CompatibilityForMigrationEnabled';Expression={ $proc.CompatibilityForMigrationEnabled }},
            @{Name='CompatibilityForOlderOperatingSystemsEnabled';Expression={ $proc.CompatibilityForOlderOperatingSystemsEnabled }},
            @{Name='NumaAligned';Expression={ $numaInfo.NumaAligned }}
        )
        $results.Add($entry)
    }
    return [PSCustomObject]@{
        HostCPUWaitTimePerDispatch = $hostWaitTime
        HostCPUs = $hostCPUs
        VMs = $results
        VCPUWaitTimes = $vcpuWaitTimes
        VCPUWaitTimesByVM = $vcpuWaitTimesByVM
    }
}

function Get-HyperVVMIntegrationServices {
    $hypervService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if ($null -eq $hypervService -or $hypervService.Status -ne 'Running') {
        Write-Verbose "Hyper-V non rilevato o non attivo su questo host."
        return @()
    }
    $results = [System.Collections.Generic.List[object]]::new()
    $vms = Get-VM
    foreach ($vm in $vms) {
        $services = Get-VMIntegrationService -VMName $vm.Name | Select-Object VMName, Name, Enabled, PrimaryStatusDescription, SecondaryStatusDescription
        foreach ($svc in $services) { $results.Add($svc) }
    }
    return $results
}
