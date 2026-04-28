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
    foreach ($vm in $vms) {
        $vital = $vm | Select-Object Name, State, CPUUsage, MemoryAssigned, Uptime, Status, Version, ProcessorCount
        # Prova a raccogliere il valore CPUWaitTimePerDispatch per ogni VM
        $waitTime = $null
        try {
            . "$PSScriptRoot/counter-resolver.ps1"
            $counterSetCandidates = @(
                'Hyper-V Hypervisor Virtual Processor',
                'Processore virtuale Hyper-V Hypervisor'
            )
            $counterCandidates = @(
                'CPU Wait Time Per Dispatch',
                'Tempo di attesa CPU per dispatch'
            )
            $counterPath = Resolve-PerfCounterPath -CounterSetCandidates $counterSetCandidates -CounterCandidates $counterCandidates -Instance '*'
            if ($null -ne $counterPath) {
                $counters = Get-Counter -Counter $counterPath -ErrorAction SilentlyContinue
                if ($counters.CounterSamples) {
                    # Cerca la media su tutte le istanze che matchano la VM
                    $samples = $counters.CounterSamples | Where-Object { $_.InstanceName -like $vm.Name }
                    if ($samples.Count -gt 0) {
                        $waitTime = ($samples | Measure-Object -Property CookedValue -Average).Average
                    }
                }
            }
        } catch {}
        $vital | Add-Member -MemberType NoteProperty -Name CPUWaitTimePerDispatch -Value $waitTime
        $results += $vital
    }
    return $results
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
