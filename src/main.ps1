# Contenuto del file /ws2022-performance-diagnostics/ws2022-performance-diagnostics/src/main.ps1

# Punto di ingresso principale per il progetto di diagnostica delle prestazioni di Windows Server 2022

# Importa i moduli necessari
Import-Module "$PSScriptRoot\..\ws2022-performance-diagnostics.psm1"

# Funzione principale per orchestrare la raccolta, analisi ed esportazione dei dati
function Main {


    # Raccogliere informazioni di sistema
    $systemInfo = Get-SystemInfo
    $cpuData = Get-CPUInfo
    $memoryData = Get-MemoryInfo
    $diskData = Get-DiskInfo
    $contextSwitchData = Get-ContextSwitchInfo

    # Collector avanzati
    . "$PSScriptRoot/collectors/services.ps1"
    $servicesNotRunning = Get-ServicesNotRunning

    . "$PSScriptRoot/collectors/performance-advanced.ps1"
    $advancedPerf = Get-AdvancedPerformance

    . "$PSScriptRoot/collectors/storage-extended.ps1"
    $storageExt = [PSCustomObject]@{
        LogicalVolumes = (Get-LogicalVolumes)
        PhysicalDisks = (Get-PhysicalDisks)
    }

    . "$PSScriptRoot/collectors/events.ps1"
    $recentEvents = Get-RecentEvents

    . "$PSScriptRoot/collectors/processes.ps1"
    $topProcesses = Get-TopProcesses

    . "$PSScriptRoot/collectors/network.ps1"
    $networkInfo = Get-NetworkInfo

    # Raccogliere vitals delle VM Hyper-V se host Hyper-V
    $hypervService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    $hypervVMVitals = $null
    if ($null -ne $hypervService -and $hypervService.Status -eq 'Running') {
        . "$PSScriptRoot/collectors/hyperv-vm.ps1"
        $hypervVMVitals = Get-HyperVVMVitals
    }

    # Aggrega tutti i dati in un unico oggetto
    $fullVitals = [PSCustomObject]@{
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        System = $systemInfo
        CPU = $cpuData
        Memory = $memoryData
        Storage = $storageExt
        Disk = $diskData
        ContextSwitch = $contextSwitchData
        Performance = $advancedPerf
        ServicesNotRunning = $servicesNotRunning
        Events = $recentEvents
        Processes = $topProcesses
        Network = $networkInfo
        HyperV = $hypervVMVitals
    }

    # Output tabellare e serializzazione
    $fullVitals | ConvertTo-Json -Depth 6 | Out-File "$PSScriptRoot/../vitals-full.json" -Encoding UTF8
    Write-Output "\n--- Vitals raccolti e salvati in vitals-full.json ---"
    $fullVitals | Format-List

    # Analizzare i dati raccolti
    $thresholds = Get-Thresholds
    $analysisResults = Analyze-Performance -cpuData $cpuData -memoryData $memoryData -diskData $diskData -contextSwitchData $contextSwitchData -thresholds $thresholds

    # Generare un riepilogo
    $summary = Generate-Summary -analysisResults $analysisResults

    # Esportare i risultati
    Export-Results -summary $summary -format 'csv'
    Export-Results -summary $summary -format 'json'
    Export-Results -summary $summary -format 'eventlog'
}

# Eseguire la funzione principale
Main