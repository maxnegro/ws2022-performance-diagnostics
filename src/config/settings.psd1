@{
    # Impostazioni di configurazione per il progetto di diagnostica delle prestazioni di Windows Server 2022

    # Soglie per le metriche di prestazione
    Thresholds = @{
        CPU = @{
            Warning = 80  # Soglia di avviso per l'utilizzo della CPU
            Critical = 90 # Soglia critica per l'utilizzo della CPU
        }
        Memory = @{
            Warning = 75  # Soglia di avviso per l'utilizzo della memoria
            Critical = 90 # Soglia critica per l'utilizzo della memoria
        }
        Disk = @{
            Warning = 80  # Soglia di avviso per l'utilizzo del disco
            Critical = 90 # Soglia critica per l'utilizzo del disco
        }
        ContextSwitch = @{
            Warning = 1000  # Soglia di avviso per i context switch
            Critical = 2000 # Soglia critica per i context switch
        }
    }

    # Opzioni di esportazione
    ExportOptions = @{
        ExportToCSV = $true   # Abilita l'esportazione in formato CSV
        ExportToJSON = $true  # Abilita l'esportazione in formato JSON
        LogToEventLog = $true # Abilita la registrazione nel registro eventi
    }

    # Impostazioni generali
    GeneralSettings = @{
        Locale = "it-IT"  # Imposta la lingua su italiano
        LogLevel = "Info" # Livello di log predefinito
    }
}