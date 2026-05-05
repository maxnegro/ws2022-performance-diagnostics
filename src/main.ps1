# Contenuto del file /ws2022-performance-diagnostics/ws2022-performance-diagnostics/src/main.ps1

# Punto di ingresso principale per il progetto di diagnostica delle prestazioni di Windows Server 2022

# Importa i moduli necessari
Import-Module "$PSScriptRoot/../ws2022-performance-diagnostics.psm1"

# Funzione principale per orchestrare la raccolta, analisi ed esportazione dei dati
function Main {

    # Importa le impostazioni dal file dati
    $settings = Import-PowerShellDataFile "$PSScriptRoot/config/settings.psd1"

    # Importa gli script necessari
    . "$PSScriptRoot/collectors/counter-resolver.ps1"
    . "$PSScriptRoot/collectors/services.ps1"
    . "$PSScriptRoot/collectors/performance-advanced.ps1"
    . "$PSScriptRoot/collectors/storage-extended.ps1"
    . "$PSScriptRoot/collectors/events.ps1"
    . "$PSScriptRoot/collectors/processes.ps1"
    . "$PSScriptRoot/collectors/network.ps1"
    . "$PSScriptRoot/collectors/cpu.ps1"
    . "$PSScriptRoot/collectors/memory.ps1"
    . "$PSScriptRoot/collectors/disk.ps1"
    . "$PSScriptRoot/analyzers/thresholds.ps1"
    . "$PSScriptRoot/analyzers/summary.ps1"
    . "$PSScriptRoot/exporters/csv.ps1"
    . "$PSScriptRoot/exporters/json.ps1"
    . "$PSScriptRoot/exporters/eventlog.ps1"


    # Raccogliere informazioni di sistema
    $systemInfo = Get-ComputerInfo | Select-Object CsName, WindowsVersion, WindowsBuildLabEx, OsArchitecture
    $cpuData = Collect-CPUData
    $memoryData = Get-MemoryInfo
    $diskData = Get-DiskPerformance

    # Uptime e timestamp ultimo reset contatori
    $lastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $lastBoot

    # Prova a recuperare il contatore System Up Time in modo robusto
    $perfCounterReset = $null
    $counterNames = @(
        '\\System\\System Up Time',
        '\\Sistema\\Tempo di funzionamento sistema'
    )
    foreach ($counterName in $counterNames) {
        $perfCounter = Get-Counter $counterName -ErrorAction SilentlyContinue
        if ($perfCounter.CounterSamples -and $perfCounter.CounterSamples.Count -gt 0) {
            $perfCounterReset = $perfCounter.CounterSamples[0].TimeStamp
            break
        }
    }

    $servicesNotRunning = Get-ServicesNotRunning
    $advancedPerf = Get-AdvancedPerformance
    $storageExt = [PSCustomObject]@{
        LogicalVolumes = (Get-LogicalVolumes)
        PhysicalDisks = (Get-PhysicalDisks)
    }
    $recentEvents = Get-RecentEvents
    $topProcesses = Get-TopProcesses
    $networkInfo = Get-NetworkInfo

    # Raccogliere vitals e integration services delle VM Hyper-V se host Hyper-V
    $hypervService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    $hypervVMVitals = $null
    $hypervVMIntegrationServices = $null
    if ($null -ne $hypervService -and $hypervService.Status -eq 'Running') {
        . "$PSScriptRoot/collectors/hyperv-vm.ps1"
        $hypervVMVitals = Get-HyperVVMVitals
        $hypervVMIntegrationServices = Get-HyperVVMIntegrationServices
    }


    # Aggrega tutti i dati in un unico oggetto
    $fullVitals = [PSCustomObject]@{
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        System = $systemInfo
        CPU = $cpuData
        Memory = $memoryData
        Storage = $storageExt
        Disk = $diskData
        Performance = $advancedPerf
        ServicesNotRunning = $servicesNotRunning
        Events = $recentEvents
        Processes = $topProcesses
        Network = $networkInfo
        HyperV = [PSCustomObject]@{
            Vitals = $hypervVMVitals
            IntegrationServices = $hypervVMIntegrationServices
        }
        Uptime = $uptime.ToString()
        LastBootUpTime = $lastBoot
        PerfCounterResetTimestamp = $perfCounterReset
    }

    # Output tabellare e serializzazione
    # $fullVitals | ConvertTo-Json -Depth 10 | Out-File "$PSScriptRoot/../vitals-full.json" -Encoding UTF8
    # Write-Output "\n--- Vitals raccolti e salvati in vitals-full.json ---"
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
        "CPU" = $cpuData.'Utilizzo CPU (%)'
        "Memoria" = $memoryData.Utilizzo_Memoria_Percento
        "Disco" = ($diskData | Measure-Object -Property PercentualeUtilizzo -Maximum).Maximum
        "ContextSwitch" = $advancedPerf.ContextSwitchesPerSec
    }

    # Analizza le performance rispetto alle soglie
    $analysisResults = Analyze-PerformanceThresholds -Metrics $metrics -Thresholds $thresholds


    # Converte i dati in stringa leggibile
    $cpuDataStr = $cpuData | Out-String
    $memoryDataStr = $memoryData | Out-String
    $diskDataStr = $diskData | Out-String
    $contextSwitchDataStr = $advancedPerf.ContextSwitchesPerSec | Out-String
    $uptimeStr = $uptime.ToString()
    $lastBootStr = $lastBoot.ToString()
    if ($null -ne $perfCounterReset) {
        $perfCounterResetStr = $perfCounterReset.ToString()
    } else {
        $perfCounterResetStr = "N/D"
    }

    # Controllo dati nulli
    if (-not $cpuDataStr -or -not $memoryDataStr -or -not $diskDataStr -or -not $contextSwitchDataStr) {
        Write-Error "Uno o più dati raccolti sono null. Controlla i collector."
        return
    }

    # Genera un riepilogo
    $summary = Generate-Summary -CpuData $cpuDataStr -MemoryData $memoryDataStr -DiskData $diskDataStr -ContextSwitchData $contextSwitchDataStr -Uptime $uptimeStr -LastBoot $lastBootStr -PerfCounterReset $perfCounterResetStr

    # Esporta i risultati in base alle opzioni di configurazione
    if ($settings.ExportOptions.ExportToCSV) {
        Export-CsvData -FilePath "$PSScriptRoot/../performance_data.csv" -Data @($fullVitals)
    }
    if ($settings.ExportOptions.ExportToJSON) {
        Export-PerformanceDataToJson -PerformanceData $fullVitals -OutputPath "$PSScriptRoot/../performance_data.json"
    }
    if ($settings.ExportOptions.LogToEventLog) {
        Log-PerformanceEvent -Message "Raccolta dati di performance completata con successo."
    }
}

# Eseguire la funzione principale
Main