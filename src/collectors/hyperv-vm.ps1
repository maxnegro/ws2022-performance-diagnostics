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
    $results = @()
    $hostWaitTime = $null
    $counterSamples = $null
    $vcpuWaitTimes = @()
    try {
        # Raccolta diretta di tutti i valori vCPU wait time
        $vcpuCounter = Get-Counter -Counter "\\Hyper-V Hypervisor Virtual Processor(*)\\CPU Wait Time Per Dispatch" -ErrorAction SilentlyContinue
        if ($vcpuCounter.CounterSamples) {
            $vcpuWaitTimes = $vcpuCounter.CounterSamples | ForEach-Object {
                [PSCustomObject]@{
                    InstanceName = $_.InstanceName
                    Value = $_.CookedValue
                }
            }
            # Valore _total host
            $totalSample = $vcpuCounter.CounterSamples | Where-Object { $_.InstanceName -eq '_total' } | Select-Object -First 1
            if ($null -ne $totalSample) {
                $hostWaitTime = $totalSample.CookedValue
            } else {
                Write-Warning "[HyperV] Nessun valore _total per CPUWaitTimePerDispatch trovato (host)."
            }
            $counterSamples = $vcpuCounter.CounterSamples
        } else {
            Write-Warning "[HyperV] Nessun CounterSamples trovato per Hyper-V Hypervisor Virtual Processor"
        }
    } catch {}

    foreach ($vm in $vms) {
        $vital = $vm | Select-Object Name, State, CPUUsage, MemoryAssigned, Uptime, Status, Version, ProcessorCount
        $waitTimeDetails = @()
        if ($counterSamples) {
            Write-Host "[DEBUG] Nome VM PowerShell: '$($vm.Name)'"
            Write-Host "[DEBUG] InstanceName disponibili: $($counterSamples.InstanceName -join ', ')"
            $vmNamePattern = "^" + [regex]::Escape($vm.Name) + ":hv vp (\\d+)$"
            $vmVpSamples = $counterSamples | Where-Object {
                $_.InstanceName -match $vmNamePattern
            }
            foreach ($sample in $vmVpSamples) {
                if ($sample.InstanceName -match $vmNamePattern) {
                    $vpNum = [int]$Matches[1]
                    $waitTimeDetails += [PSCustomObject]@{
                        VirtualProcessor = $vpNum
                        Value = $sample.CookedValue
                        InstanceName = $sample.InstanceName
                    }
                }
            }
            if ($waitTimeDetails.Count -eq 0) {
                Write-Warning "[HyperV] Nessun valore CPUWaitTimePerDispatch trovato per vCPU della VM $($vm.Name). Istanza disponibili: $($counterSamples.InstanceName -join ', ')"
            }
        } else {
            Write-Warning "[HyperV] Contatore CPUWaitTimePerDispatch non trovato per la VM $($vm.Name)."
        }
        $vital | Add-Member -MemberType NoteProperty -Name CPUWaitTimePerDispatchDetails -Value $waitTimeDetails
        $results += $vital
    }
    return [PSCustomObject]@{
        HostCPUWaitTimePerDispatch = $hostWaitTime
        VMs = $results
        VCPUWaitTimes = $vcpuWaitTimes
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
