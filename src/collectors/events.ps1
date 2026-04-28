# Collector per eventi di sistema e applicazione recenti
function Get-RecentEvents {
    $now = Get-Date
    $last24h = $now.AddHours(-24)
    $system = Get-WinEvent -LogName System -ErrorAction SilentlyContinue | Where-Object { $_.TimeCreated -ge $last24h -and $_.LevelDisplayName -in @('Errore','Warning') } | Select-Object -First 10
    $application = Get-WinEvent -LogName Application -ErrorAction SilentlyContinue | Where-Object { $_.TimeCreated -ge $last24h -and $_.LevelDisplayName -in @('Errore','Warning') } | Select-Object -First 10
    return [PSCustomObject]@{
        System = $system | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
        Application = $application | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
    }
}

# Esegui e mostra
$events = Get-RecentEvents
$events | Format-List
