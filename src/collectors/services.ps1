# Raccoglie i servizi non in esecuzione
function Get-ServicesNotRunning {
    $services = Get-Service | Where-Object { $_.Status -ne 'Running' }
    $result = [System.Collections.Generic.List[object]]::new()
    foreach ($svc in $services) {
        $svcCim = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue
        $result.Add([PSCustomObject]@{
            Name = $svc.Name
            DisplayName = $svc.DisplayName
            Status = [int]$svc.Status.value__
            StartType = if ($svcCim) { $svcCim.StartMode } else { $null }
        })
    }
    return $result
}
