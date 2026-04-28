

Write-Host "[Collector] Inizio raccolta informazioni memoria"
. "$PSScriptRoot/counter-resolver.ps1"

function Get-MemoryUsage {
	$memUsagePerc = Get-ResolvedCounterCookedValue `
		-CounterSetCandidates @('Memory', 'Memoria') `
		-CounterCandidates @('% Committed Bytes In Use', '% byte impegnati in uso')
	if ($null -ne $memUsagePerc) {
		return [math]::Round([double]$memUsagePerc, 2)
	}
	# Fallback: calcolo percentuale da WMI
	$os = Get-WmiObject Win32_OperatingSystem
	$used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
	$perc = ($used / $os.TotalVisibleMemorySize) * 100
	return [math]::Round($perc, 2)
}

function Get-MemoryInfo {
	$os = Get-WmiObject Win32_OperatingSystem
	$info = [PSCustomObject]@{
		'Memoria_Fisica_Totale_MB' = [math]::Round($os.TotalVisibleMemorySize/1KB, 2)
		'Memoria_Fisica_Disponibile_MB' = [math]::Round($os.FreePhysicalMemory/1KB, 2)
		'Utilizzo_Memoria_Percento' = Get-MemoryUsage
	}
	return $info
}

# Esegui la raccolta e mostra i dati
$memoria = Get-MemoryInfo
$memoria | Format-Table -AutoSize