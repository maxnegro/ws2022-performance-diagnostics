
Write-Host "[Collector] Inizio raccolta performance avanzate"
# Collector per performance avanzate
. "$PSScriptRoot/counter-resolver.ps1"

function Get-AdvancedPerformance {
    $queueLen = Get-ResolvedCounterCookedValue `
        -CounterSetCandidates @('System', 'Sistema') `
        -CounterCandidates @('Processor Queue Length', 'Lunghezza coda processore')
    $workItemShortages = Get-ResolvedCounterCookedValue `
        -CounterSetCandidates @('System', 'Sistema') `
        -CounterCandidates @('Work Item Shortages', 'Carenze elementi di lavoro')
    $contextSwitches = Get-ResolvedCounterCookedValue `
        -CounterSetCandidates @('System', 'Sistema') `
        -CounterCandidates @('Context Switches/sec', 'Commutazioni contesto/sec', 'Commutazioni di contesto/sec')
    return [PSCustomObject]@{
        ProcessorQueueLength = $queueLen
        WorkItemShortages = $workItemShortages
        ContextSwitchesPerSec = $contextSwitches
    }
}

# Esegui e mostra
$perf = Get-AdvancedPerformance
$perf | Format-Table -AutoSize
