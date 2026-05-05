# Questo script esporta i dati raccolti in formato CSV.

function Export-CsvData {
    param (
        [string]$FilePath,
        [array]$Data
    )

    if (-not $Data) {
        Write-Host "Nessun dato da esportare."
        return
    }

    try {
        $Data | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
        Write-Host "Dati esportati con successo in $FilePath"
    } catch {
        Write-Host "Errore durante l'esportazione dei dati: $_"
    }
}

