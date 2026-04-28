# Raccoglie informazioni sulle prestazioni della CPU

. "$PSScriptRoot\counter-resolver.ps1"

# Funzione per ottenere l'utilizzo della CPU
function Get-CPUUsage {
    $cpuUsage = Get-ResolvedCounterCookedValue `
        -CounterSetCandidates @('Processor', 'Informazioni processore') `
        -CounterCandidates @('% Processor Time', '% Tempo processore') `
        -Instance '_Total'

    if ($null -ne $cpuUsage) {
        return [math]::Round([double]$cpuUsage, 2)
    }

    # Fallback locale-invariant in caso di contatori mancanti/non registrati.
    $fallback = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'"
    return $fallback.PercentProcessorTime
}

# Funzione per ottenere informazioni dettagliate sulla CPU
function Get-CPUInfo {
    $cpuInfo = Get-WmiObject Win32_Processor
    return $cpuInfo | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
}

# Funzione principale per raccogliere e visualizzare le informazioni sulla CPU
function Collect-CPUData {
    $cpuUsage = Get-CPUUsage
    $cpuInfo = Get-CPUInfo

    # Creazione di un oggetto per contenere i dati
    $cpuData = [PSCustomObject]@{
        'Utilizzo CPU (%)' = $cpuUsage
        'Nome CPU' = $cpuInfo.Name
        'Nuclei' = $cpuInfo.NumberOfCores
        'Processori Logici' = $cpuInfo.NumberOfLogicalProcessors
        'Velocità Massima (MHz)' = $cpuInfo.MaxClockSpeed
    }

    return $cpuData
}

# Esecuzione della raccolta dei dati
$cpuData = Collect-CPUData
$cpuData | Format-Table -AutoSize