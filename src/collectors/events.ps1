# Raccoglie eventi recenti di errore e warning dai log System e Application
function Get-RecentEvents {
    $now = Get-Date
    $last24h = $now.AddHours(-24)
    $system = Get-WinEvent -LogName System -ErrorAction SilentlyContinue | Where-Object { $_.TimeCreated -ge $last24h -and $_.Level -in @(1, 2, 3) } | Select-Object -First 10
    $application = Get-WinEvent -LogName Application -ErrorAction SilentlyContinue | Where-Object { $_.TimeCreated -ge $last24h -and $_.Level -in @(1, 2, 3) } | Select-Object -First 10
    return [PSCustomObject]@{
        System = $system | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
        Application = $application | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
    }
}
