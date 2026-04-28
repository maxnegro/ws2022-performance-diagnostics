# Collector per dettagli storage avanzati
function Get-LogicalVolumes {
    Get-WmiObject Win32_LogicalDisk | ForEach-Object {
        [PSCustomObject]@{
            DriveLetter = $_.DeviceID
            FileSystem = $_.FileSystem
            Size = $_.Size
            SizeRemaining = $_.FreeSpace
            UsedGB = [math]::Round(($_.Size - $_.FreeSpace)/1GB,2)
            FreeGB = [math]::Round($_.FreeSpace/1GB,2)
        }
    }
}

function Get-PhysicalDisks {
    Get-WmiObject Win32_DiskDrive | ForEach-Object {
        [PSCustomObject]@{
            FriendlyName = $_.Model
            MediaType = $_.MediaType
            Size = $_.Size
            HealthStatus = $_.Status
            OperationalStatus = $_.Status
        }
    }
}

# Esegui e mostra
$volumes = Get-LogicalVolumes
$disks = Get-PhysicalDisks
[PSCustomObject]@{
    LogicalVolumes = $volumes
    PhysicalDisks = $disks
} | Format-List
