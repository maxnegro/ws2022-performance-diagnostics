# Raccoglie informazioni principali degli adapter di rete
function Get-NetworkInfo {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    $result = [System.Collections.Generic.List[object]]::new()
    foreach ($ad in $adapters) {
        $ip = (Get-NetIPAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
        $result.Add([PSCustomObject]@{
            Name = $ad.Name
            InterfaceDescription = $ad.InterfaceDescription
            LinkSpeed = $ad.LinkSpeed
            IPAddress = $ip
            MacAddress = $ad.MacAddress
        })
    }
    return $result
}
