# Collector per raccogliere i "vitals" delle VM Hyper-V
# Raccoglie CPU, RAM, dischi, coda IO, context switch, CPU ready/starving, ecc.

. "$PSScriptRoot/counter-resolver.ps1"

function Get-HyperVVMVitals {
    # Verifica se Hyper-V è presente
    $hypervService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if ($null -eq $hypervService -or $hypervService.Status -ne 'Running') {
        Write-Verbose "Hyper-V non rilevato o non attivo su questo host."
        return @()
    }

    $vms = Get-VM
    $results = @()

    # Versione Integration Services dell'host
    $hostISVer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ReleaseId','CurrentBuild','UBR' -ErrorAction SilentlyContinue)
    $hostISVersion = if ($hostISVer) { "$($hostISVer.ReleaseId).$($hostISVer.CurrentBuild).$($hostISVer.UBR)" } else { $null }

    foreach ($vm in $vms) {
        $vmName = $vm.Name
        $vmId = $vm.VMId.Guid

        # CPU usage (percentuale guest)
        $cpuUsage = $vm.CPUUsage
        # RAM assegnata e usata
        $ramAssigned = $vm.MemoryAssigned / 1MB
        $ramDemand = $vm.MemoryDemand / 1MB
        $ramStatus = $vm.MemoryStatus

        # Disco: utilizzo e queue length (se disponibili)
        $diskCounters = Get-VMHardDiskDrive -VMName $vmName | ForEach-Object {
            $path = $_.Path
            $controller = $_.ControllerType
            $location = $_.ControllerNumber
            [PSCustomObject]@{
                Path = $path
                Controller = $controller
                Location = $location
                # Placeholder: aggiungi qui raccolta queue length se disponibile
            }
        }

        # Context switch e altri parametri avanzati (se disponibili via performance counter)
        $contextSwitch = Get-ResolvedCounterCookedValue `
            -CounterSetCandidates @('Hyper-V Hypervisor Virtual Processor', 'Processore virtuale Hyper-V Hypervisor') `
            -CounterCandidates @('Total Context Switches/sec', 'Commutazioni contesto totali/sec') `
            -Instance $vmName

        $cpuWait = Get-ResolvedCounterCookedValue `
            -CounterSetCandidates @('Hyper-V Hypervisor Virtual Processor', 'Processore virtuale Hyper-V Hypervisor') `
            -CounterCandidates @('CPU Wait Time Per Dispatch', 'Tempo di attesa CPU per dispatch') `
            -Instance $vmName

        $cpuStarving = Get-ResolvedCounterCookedValue `
            -CounterSetCandidates @('Hyper-V Hypervisor Virtual Processor', 'Processore virtuale Hyper-V Hypervisor') `
            -CounterCandidates @('Percent Guest Run Time', 'Percentuale tempo guest in esecuzione') `
            -Instance $vmName

        # Versione Integration Services guest (se disponibile)
        $guestISVersion = $null
        try {
            $guestISVersion = ($vm | Get-VMIntegrationService | Where-Object { $_.Name -eq 'Guest Service Interface' }).Version
        } catch {}

        $isVersionMatch = $null
        if ($hostISVersion -and $guestISVersion) {
            $isVersionMatch = ($hostISVersion -eq $guestISVersion)
        }

        $results += [PSCustomObject]@{
            VMName = $vmName
            VMId = $vmId
            CPUUsage = $cpuUsage
            RAMAssignedMB = [math]::Round($ramAssigned,2)
            RAMDemandMB = [math]::Round($ramDemand,2)
            RAMStatus = $ramStatus
            DiskInfo = $diskCounters
            ContextSwitchesPerSec = $contextSwitch
            CPUWaitTimePerDispatch = $cpuWait
            PercentGuestRunTime = $cpuStarving
            GuestISVersion = $guestISVersion
            HostISVersion = $hostISVersion
            ISVersionMatch = $isVersionMatch
        }
    }
    return $results
}

# Esegui la raccolta e mostra i dati
$vmVitals = Get-HyperVVMVitals
if ($vmVitals.Count -gt 0) {
    $warnings = $vmVitals | Where-Object { $_.ISVersionMatch -eq $false -and $_.GuestISVersion -and $_.HostISVersion }
    if ($warnings.Count -gt 0) {
        Write-Warning "ATTENZIONE: Alcune VM hanno una versione degli Integration Services diversa da quella dell'host Hyper-V!"
        $warnings | ForEach-Object {
            Write-Warning ("VM: {0} - GuestIS: {1} - HostIS: {2}" -f $_.VMName, $_.GuestISVersion, $_.HostISVersion)
        }
    }
    $vmVitals | Format-Table -AutoSize
} else {
    Write-Output "Nessuna VM Hyper-V trovata o Hyper-V non attivo."
}
