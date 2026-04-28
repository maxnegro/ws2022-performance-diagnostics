# Questo script registra gli eventi di performance nel registro eventi di Windows.

function Log-PerformanceEvent {
    param (
        [string]$Message,
        [string]$Source = "WS2022PerformanceDiagnostics",
        [int]$EventId = 1000,
        [string]$EntryType = [System.Diagnostics.EventLogEntryType]::Information
    )

    # Controlla se la sorgente esiste, altrimenti la crea
    if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
        New-EventLog -LogName Application -Source $Source
    }

    # Registra l'evento
    Write-EventLog -LogName Application -Source $Source -EventId $EventId -EntryType $EntryType -Message $Message
}

# Esempio di utilizzo della funzione
Log-PerformanceEvent -Message "Raccolta dati di performance completata con successo."