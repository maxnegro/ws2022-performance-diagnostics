Write-Host "[Collector] Inizio raccolta informazioni di rete"
# Collector per info di rete principali
function Get-NetworkInfo {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    $result = @()
    foreach ($ad in $adapters) {
        $ip = (Get-NetIPAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
        $result += [PSCustomObject]@{
            Name = $ad.Name
            InterfaceDescription = $ad.InterfaceDescription
            LinkSpeed = $ad.LinkSpeed
            IPAddress = $ip
            MacAddress = $ad.MacAddress
        }
    }
    return $result
}

# Esegui e mostra
$net = Get-NetworkInfo
$net | Format-Table -AutoSize
