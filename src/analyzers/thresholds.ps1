# Contenuto del file thresholds.ps1

# Questo file analizza i dati raccolti e confronta le metriche con le soglie predefinite per identificare eventuali problemi di performance.

function Analyze-PerformanceThresholds {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Metrics,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Thresholds
    )

    $results = @{}

    foreach ($metric in $Metrics.Keys) {
        if ($Thresholds.ContainsKey($metric)) {
            if ($Metrics[$metric] -gt $Thresholds[$metric]) {
                $results[$metric] = "Soglia superata: $($Metrics[$metric]) > $($Thresholds[$metric])"
            } else {
                $results[$metric] = "Nella norma: $($Metrics[$metric]) <= $($Thresholds[$metric])"
            }
        } else {
            $results[$metric] = "Nessuna soglia definita per $metric"
        }
    }

    return $results
}

# Esempio di utilizzo
$metrics = @{
    "CPU" = 85
    "Memoria" = 70
    "Disco" = 90
    "ContextSwitch" = 1500
}

$thresholds = @{
    "CPU" = 80
    "Memoria" = 75
    "Disco" = 85
    "ContextSwitch" = 1000
}

$performanceResults = Analyze-PerformanceThresholds -Metrics $metrics -Thresholds $thresholds

$performanceResults | ForEach-Object { Write-Host $_ }