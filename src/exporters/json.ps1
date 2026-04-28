# Questo file esporta i dati raccolti in formato JSON.

function Export-PerformanceDataToJson {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$PerformanceData,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        # Convertire i dati delle prestazioni in formato JSON
        $jsonData = $PerformanceData | ConvertTo-Json -Depth 10
        
        # Scrivere i dati JSON nel file di output
        Set-Content -Path $OutputPath -Value $jsonData -Encoding UTF8
        
        Write-Host "Dati delle prestazioni esportati con successo in $OutputPath"
    } catch {
        Write-Error "Si è verificato un errore durante l'esportazione dei dati: $_"
    }
}

# Esempio di utilizzo della funzione
# $data = @{ CPU = 75; Memory = 60; Disk = 80 }
# Export-PerformanceDataToJson -PerformanceData $data -OutputPath "C:\path\to\output.json"