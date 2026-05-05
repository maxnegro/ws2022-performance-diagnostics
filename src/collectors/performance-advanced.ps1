
# Raccoglie metriche di performance avanzate

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