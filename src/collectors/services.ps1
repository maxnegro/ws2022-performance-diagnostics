# Collector per servizi non in esecuzione
function Get-ServicesNotRunning {
    $services = Get-Service | Where-Object { $_.Status -ne 'Running' }
    $result = @()
    foreach ($svc in $services) {
        $svcWmi = Get-WmiObject -Class Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue
        $result += [PSCustomObject]@{
            Name = $svc.Name
            DisplayName = $svc.DisplayName
            Status = [int]$svc.Status.value__
            StartType = if ($svcWmi) { [int]$svcWmi.StartMode.value__ } else { $null }
        }
    }
    return $result
}

# Esegui e mostra
$notRunning = Get-ServicesNotRunning
$notRunning | Format-Table -AutoSize
