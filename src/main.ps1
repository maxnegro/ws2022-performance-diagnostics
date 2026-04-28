# Contenuto del file /ws2022-performance-diagnostics/ws2022-performance-diagnostics/src/main.ps1

# Punto di ingresso principale per il progetto di diagnostica delle prestazioni di Windows Server 2022

# Importa i moduli necessari
Import-Module "$PSScriptRoot\..\ws2022-performance-diagnostics.psm1"

# Funzione principale per orchestrare la raccolta, analisi ed esportazione dei dati
function Main {

    # Importa le impostazioni dal file dati
    $settings = Import-PowerShellDataFile "$PSScriptRoot/../config/settings.psd1"

    # Importa gli script necessari
    . "$PSScriptRoot/collectors/services.ps1"
    . "$PSScriptRoot/collectors/performance-advanced.ps1"
    . "$PSScriptRoot/collectors/storage-extended.ps1"
    . "$PSScriptRoot/collectors/events.ps1"
    . "$PSScriptRoot/collectors/processes.ps1"
    . "$PSScriptRoot/collectors/network.ps1"
    . "$PSScriptRoot/collectors/cpu.ps1"
    . "$PSScriptRoot/collectors/memory.ps1"
    . "$PSScriptRoot/collectors/disk.ps1"
    . "$PSScriptRoot/collectors/context-switch.ps1"
    . "$PSScriptRoot/analyzers/thresholds.ps1"
    . "$PSScriptRoot/analyzers/summary.ps1"
    . "$PSScriptRoot/exporters/csv.ps1"
    . "$PSScriptRoot/exporters/json.ps1"
    . "$PSScriptRoot/exporters/eventlog.ps1"

    # Raccogliere informazioni di sistema
    $systemInfo = Get-ComputerInfo | Select-Object CsName, WindowsVersion, WindowsBuildLabEx, OsArchitecture
    $cpuData = Get-CPUInfo
    $memoryData = Get-MemoryInfo
    $diskData = Get-DiskPerformance
    $contextSwitchData = Get-ContextSwitchMetrics

    $servicesNotRunning = Get-ServicesNotRunning
    $advancedPerf = Get-AdvancedPerformance
    $storageExt = [PSCustomObject]@{
        LogicalVolumes = (Get-LogicalVolumes)
        PhysicalDisks = (Get-PhysicalDisks)
    }
    $recentEvents = Get-RecentEvents
    $topProcesses = Get-TopProcesses
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


    # Usa le soglie dal file di configurazione
    $thresholds = @{
        "CPU" = $settings.Thresholds.CPU.Warning
        "Memoria" = $settings.Thresholds.Memory.Warning
        "Disco" = $settings.Thresholds.Disk.Warning
        "ContextSwitch" = $settings.Thresholds.ContextSwitch.Warning
    }

    # Prepara le metriche per l'analisi
    $metrics = @{
        "CPU" = $cpuData.UtilizzoCPU
        "Memoria" = $memoryData.Utilizzo_Memoria_Percento
        "Disco" = ($diskData | Measure-Object -Property PercentualeUtilizzo -Maximum).Maximum
        "ContextSwitch" = $contextSwitchData
    }

    # Analizza le performance rispetto alle soglie
    $analysisResults = Analyze-PerformanceThresholds -Metrics $metrics -Thresholds $thresholds

    # Genera un riepilogo
    $summary = Generate-Summary -CpuData $cpuData -MemoryData $memoryData -DiskData $diskData -ContextSwitchData $contextSwitchData

    # Esporta i risultati in base alle opzioni di configurazione
    if ($settings.ExportOptions.ExportToCSV) {
        Export-CsvData -FilePath "$PSScriptRoot/../performance_data.csv" -Data @($summary)
    }
    if ($settings.ExportOptions.ExportToJSON) {
        Export-PerformanceDataToJson -PerformanceData $summary -OutputPath "$PSScriptRoot/../performance_data.json"
    }
    if ($settings.ExportOptions.LogToEventLog) {
        Log-PerformanceEvent -Message "Raccolta dati di performance completata con successo."
    }
}

# Eseguire la funzione principale
Main