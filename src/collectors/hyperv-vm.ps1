Write-Host "[Collector] Inizio raccolta Hyper-V VM vitals e Integration Services"
# Collector per raccogliere i "vitals" delle VM Hyper-V e i servizi di integrazione
# Raccoglie info principali delle VM tramite Get-VM e i servizi tramite Get-VMIntegrationService

function Get-HyperVVMVitals {
    $hypervService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if ($null -eq $hypervService -or $hypervService.Status -ne 'Running') {
        Write-Verbose "Hyper-V non rilevato o non attivo su questo host."
        return @()
    }
    $vms = Get-VM | Select-Object Name, State, CPUUsage, MemoryAssigned, Uptime, Status, Version, ProcessorCount
    return $vms
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
