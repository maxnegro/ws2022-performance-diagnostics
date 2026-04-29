Write-Host "[Collector] Inizio raccolta Hyper-V VM vitals e Integration Services"
# Collector per raccogliere i "vitals" delle VM Hyper-V e i servizi di integrazione
# Raccoglie info principali delle VM tramite Get-VM e i servizi tramite Get-VMIntegrationService

function Get-HyperVVMVitals {
    $hypervService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if ($null -eq $hypervService -or $hypervService.Status -ne 'Running') {
        Write-Verbose "Hyper-V non rilevato o non attivo su questo host."
        return @()
    }
    $vms = Get-VM
    $vmProcessors = Get-VMProcessor -VMName * | Select-Object VMName, Count, MaximumCountPerNumaNode, MaximumCountPerNumaSocket, HwThreadCountPerCore
    $vmNuma = Get-VM | Select-Object Name, NumaAligned
    $results = @()
    $hostWaitTime = $null
    $vcpuWaitTimes = @()
    $vcpuWaitTimesByVM = @{}
    $hostCPUs = Get-WmiObject -Class Win32_Processor | Select-Object DeviceID, NumberOfCores, NumberOfLogicalProcessors, SocketDesignation
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
                        $vcpuWaitTimesByVM[$vmName] = @()
                    }
                    $vcpuWaitTimesByVM[$vmName] += [PSCustomObject]@{
                        VirtualProcessor = $vpNum
                        Value = $sample.CookedValue
                    }
                } elseif ($sample.InstanceName -eq '_total') {
                    $hostWaitTime = $sample.CookedValue
                }
            }
        } else {
            Write-Warning "[HyperV] Nessun CounterSamples trovato per Hyper-V Hypervisor Virtual Processor"
        }
    } catch {}

    foreach ($vm in $vms) {
        $results += $vm | Select-Object 
            Name, State, CPUUsage, MemoryAssigned, Uptime, Status, Version, ProcessorCount,
            @{Name='CPUWaitTimePerDispatchDetails';Expression={
                if ($vcpuWaitTimesByVM.ContainsKey($_.Name)) { $vcpuWaitTimesByVM[$_.Name] } else { @() }
            }},
            @{Name='VMProcessorCount';Expression={
                ($vmProcessors | Where-Object { $_.VMName -eq $_.Name } | Select-Object -ExpandProperty Count -First 1)
            }},
            @{Name='MaximumCountPerNumaNode';Expression={
                ($vmProcessors | Where-Object { $_.VMName -eq $_.Name } | Select-Object -ExpandProperty MaximumCountPerNumaNode -First 1)
            }},
            @{Name='MaximumCountPerNumaSocket';Expression={
                ($vmProcessors | Where-Object { $_.VMName -eq $_.Name } | Select-Object -ExpandProperty MaximumCountPerNumaSocket -First 1)
            }},
            @{Name='HwThreadCountPerCore';Expression={
                ($vmProcessors | Where-Object { $_.VMName -eq $_.Name } | Select-Object -ExpandProperty HwThreadCountPerCore -First 1)
            }},
            @{Name='NumaAligned';Expression={
                ($vmNuma | Where-Object { $_.Name -eq $_.Name } | Select-Object -ExpandProperty NumaAligned -First 1)
            }}
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
    $results = @()
    $vms = Get-VM
    foreach ($vm in $vms) {
        $services = Get-VMIntegrationService -VMName $vm.Name | Select-Object VMName, Name, Enabled, PrimaryStatusDescription, SecondaryStatusDescription
        $results += $services
    }
    return $results
}

# Esegui la raccolta e mostra i dati
$vmVitals = Get-HyperVVMVitals
if ($vmVitals.Count -gt 0) {
    Write-Host "--- Vitals VM Hyper-V ---"
    $vmVitals | Format-Table -AutoSize
} else {
    Write-Output "Nessuna VM Hyper-V trovata o Hyper-V non attivo."
}

$vmIntegrationServices = Get-HyperVVMIntegrationServices
if ($vmIntegrationServices.Count -gt 0) {
    Write-Host "--- Integration Services per VM ---"
    $vmIntegrationServices | Format-Table -AutoSize
} else {
    Write-Output "Nessun servizio di integrazione trovato o Hyper-V non attivo."
}
