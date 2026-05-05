# Riepilogo delle informazioni di performance per Windows Server 2022

# Questo script genera un riepilogo delle informazioni raccolte e analizzate
# per identificare eventuali problemi di performance legati a disco, processore, memoria e context switch.


# Funzione per generare il riepilogo
function Generate-Summary {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CpuData,
        
        [Parameter(Mandatory = $true)]
        [string]$MemoryData,
        
        [Parameter(Mandatory = $true)]
        [string]$DiskData,
        
        [Parameter(Mandatory = $true)]
        [string]$ContextSwitchData,
        
        [Parameter(Mandatory = $false)]
        [string]$Uptime,
        
        [Parameter(Mandatory = $false)]
        [string]$LastBoot,
        
        [Parameter(Mandatory = $false)]
        [string]$PerfCounterReset
    )

    # Analizza i dati della CPU
    $cpuSummary = "Riepilogo CPU:`n$CpuData"

    # Analizza i dati della memoria
    $memorySummary = "Riepilogo Memoria:`n$MemoryData"

    # Analizza i dati del disco
    $diskSummary = "Riepilogo Disco:`n$DiskData"

    # Analizza i dati dei context switch
    $contextSwitchSummary = "Riepilogo Context Switch:`n$ContextSwitchData"

    # Analizza uptime e boot
    if ($PSBoundParameters.ContainsKey('Uptime')) {
        $uptimeSummary = "Uptime sistema: $Uptime"
    } else {
        $uptimeSummary = "Uptime sistema: N/D"
    }
    if ($PSBoundParameters.ContainsKey('LastBoot')) {
        $lastBootSummary = "Ultimo avvio: $LastBoot"
    } else {
        $lastBootSummary = "Ultimo avvio: N/D"
    }

    # Combina tutti i riepiloghi
    $finalSummary = @"
Riepilogo delle Performance di Windows Server 2022

$uptimeSummary
$lastBootSummary

$cpuSummary

$memorySummary

$diskSummary

$contextSwitchSummary
"@
    $finalSummary
}