
# Raccoglie dati sulle prestazioni del disco

function Get-DiskPerformance {
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3'
    $diskPerformance = [System.Collections.Generic.List[object]]::new()

    foreach ($disk in $disks) {
        # Prova a raccogliere % tempo disco attivo (counter localizzato)
        $activePerc = Get-ResolvedCounterCookedValue `
            -CounterSetCandidates @('PhysicalDisk', 'Disco fisico') `
            -CounterCandidates @('% Disk Time', '% tempo disco') `
            -Instance $disk.DeviceID

        if ($null -ne $activePerc) {
            $activePerc = [math]::Round([double]$activePerc, 2)
        }

        $diskPerformance.Add([PSCustomObject]@{
            NomeDisco              = $disk.DeviceID
            SpazioTotaleGB         = [math]::round($disk.Size / 1GB, 2)
            SpazioLiberoGB         = [math]::round($disk.FreeSpace / 1GB, 2)
            PercentualeUtilizzo    = [math]::round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
            TipoDisco              = $disk.FileSystem
            PercentualeTempoAttivo = $activePerc
        })
    }
    return $diskPerformance
}