# File: /ws2022-performance-diagnostics/ws2022-performance-diagnostics/src/collectors/disk.ps1

# Questo script raccoglie dati sulle prestazioni del disco in un'installazione di Windows Server 2022.
# Monitora l'utilizzo e le statistiche di accesso al disco, utilizzando chiavi italiane.

# Funzione per raccogliere informazioni sulle prestazioni del disco
. "$PSScriptRoot/counter-resolver.ps1"

function Get-DiskPerformance {
    $disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
    $diskPerformance = @()

    foreach ($disk in $disks) {
        # Prova a raccogliere % tempo disco attivo (counter localizzato)
        $activePerc = Get-ResolvedCounterCookedValue `
            -CounterSetCandidates @('PhysicalDisk', 'Disco fisico') `
            -CounterCandidates @('% Disk Time', '% tempo disco') `
            -Instance $disk.DeviceID

        if ($null -eq $activePerc) {
            $activePerc = $null  # fallback: non disponibile
        } else {
            $activePerc = [math]::Round([double]$activePerc, 2)
        }

        $performanceData = [PSCustomObject]@{
            NomeDisco         = $disk.DeviceID
            SpazioTotaleGB    = [math]::round($disk.Size / 1GB, 2)
            SpazioLiberoGB    = [math]::round($disk.FreeSpace / 1GB, 2)
            PercentualeUtilizzo = [math]::round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
            TipoDisco         = $disk.FileSystem
            PercentualeTempoAttivo = $activePerc
        }
        $diskPerformance += $performanceData
    }
    return $diskPerformance
}

# Esegui la funzione e visualizza i risultati
$diskResults = Get-DiskPerformance
$diskResults | Format-Table -AutoSize