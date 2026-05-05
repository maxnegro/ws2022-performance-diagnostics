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
        $vcpuCounterPath = $null
        $counterSetCandidates = @(
            'Hyper-V Hypervisor Virtual Processor',
            'Processore virtuale hypervisor Hyper-V'
        )
        $counterCandidates = @(
            'CPU Wait Time Per Dispatch',
            'Tempo di attesa CPU per dispatch',
            'Tempo attesa CPU per dispatch',
            'Tempo di attesa CPU per invio'
        )

        if (Get-Command Resolve-PerfCounterPath -ErrorAction SilentlyContinue) {
            $vcpuCounterPath = Resolve-PerfCounterPath -CounterSetCandidates $counterSetCandidates -CounterCandidates $counterCandidates -Instance '*'

            if ([string]::IsNullOrWhiteSpace($vcpuCounterPath) -and (Get-Command Get-PerfCounterListSetCache -ErrorAction SilentlyContinue)) {
                $sets = Get-PerfCounterListSetCache | Where-Object { $_.CounterSetName -in $counterSetCandidates }
                foreach ($set in $sets) {
                    $vcpuCounterPath = @($set.Paths) | Where-Object {
                        $_ -imatch '(wait time per dispatch|attesa.*cpu.*dispatch|attesa.*cpu.*invio)'
                    } | Select-Object -First 1

                    if (-not [string]::IsNullOrWhiteSpace($vcpuCounterPath)) {
                        break
                    }
                }
            }
        }

        if ([string]::IsNullOrWhiteSpace($vcpuCounterPath)) {
            # Fallback legacy: mantiene compatibilita con host EN dove il path e' standard.
            $vcpuCounterPath = '\Hyper-V Hypervisor Virtual Processor(*)\CPU Wait Time Per Dispatch'
        }

        # Raccolta diretta di tutti i valori vCPU wait time
        $vcpuCounter = Get-Counter -Counter $vcpuCounterPath -ErrorAction SilentlyContinue
        if (($null -eq $vcpuCounter -or $null -eq $vcpuCounter.CounterSamples -or $vcpuCounter.CounterSamples.Count -eq 0) -and (Get-Command Get-PerfCounterListSetCache -ErrorAction SilentlyContinue)) {
            $sets = Get-PerfCounterListSetCache | Where-Object { $_.CounterSetName -in $counterSetCandidates }
            foreach ($set in $sets) {
                $fallbackPath = @($set.Paths) | Where-Object {
                    $_ -imatch '(wait time per dispatch|attesa.*cpu.*dispatch|attesa.*cpu.*invio)'
                } | Select-Object -First 1

                if (-not [string]::IsNullOrWhiteSpace($fallbackPath)) {
                    $vcpuCounter = Get-Counter -Counter $fallbackPath -ErrorAction SilentlyContinue
                    if ($null -ne $vcpuCounter -and $null -ne $vcpuCounter.CounterSamples -and $vcpuCounter.CounterSamples.Count -gt 0) {
                        break
                    }
                }
            }
        }
        if ($vcpuCounter.CounterSamples) {
            $vcpuWaitTimes = $vcpuCounter.CounterSamples | ForEach-Object {
                [PSCustomObject]@{
                    InstanceName = $_.InstanceName
                    Value = $_.CookedValue
                }
            }
            # Raggruppa per VM e vCPU
            foreach ($sample in $vcpuCounter.CounterSamples) {
                if ($sample.InstanceName -match "^(.*):hv vp (\d+)$") {
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
