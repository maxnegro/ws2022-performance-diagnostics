# Raccoglie informazioni sui context switch del sistema

. "$PSScriptRoot\counter-resolver.ps1"

# Funzione per ottenere le metriche di context switch
function Get-ContextSwitchMetrics {
    $contextSwitches = Get-ResolvedCounterCookedValue `
        -CounterSetCandidates @('System', 'Sistema') `
        -CounterCandidates @('Context Switches/sec', 'Commutazioni contesto/sec', 'Commutazioni di contesto/sec')

    if ($null -ne $contextSwitches) {
        return [math]::Round([double]$contextSwitches, 2)
    }

    # Fallback locale-invariant.
    $systemPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System
    return $systemPerf.ContextSwitchesPersec
}

# Funzione principale per raccogliere e visualizzare i dati
function Collect-ContextSwitchData {
    $contextSwitchCount = Get-ContextSwitchMetrics
    Write-Output "Context switch/sec: $contextSwitchCount"
}

# Esegui la raccolta dei dati
Collect-ContextSwitchData