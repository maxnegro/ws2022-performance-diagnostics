# ws2022-performance-diagnostics

Questo progetto è progettato per raccogliere informazioni essenziali da un'installazione di Windows Server 2022 al fine di identificare problemi di performance legati a disco, processore, memoria, context switch e simili.

## Struttura del Progetto

Il progetto è organizzato nella seguente struttura:

```
ws2022-performance-diagnostics
├── src
│   ├── collectors
│   │   ├── cpu.ps1          # Raccoglie informazioni sulle prestazioni della CPU
│   │   ├── memory.ps1       # Raccoglie informazioni sull'utilizzo della memoria
│   │   ├── disk.ps1         # Raccoglie dati sulle prestazioni del disco
│   │   ├── context-switch.ps1 # Raccoglie informazioni sui context switch del sistema
│   │   └── system-info.ps1   # Raccoglie informazioni generali sul sistema
│   ├── analyzers
│   │   ├── thresholds.ps1    # Analizza i dati e confronta le metriche con le soglie
│   │   └── summary.ps1       # Genera un riepilogo delle informazioni raccolte
│   ├── exporters
│   │   ├── csv.ps1           # Esporta i dati in formato CSV
│   │   ├── json.ps1          # Esporta i dati in formato JSON
│   │   └── eventlog.ps1      # Registra gli eventi di performance nel registro eventi
│   ├── config
│   │   └── settings.psd1     # Contiene le impostazioni di configurazione del progetto
│   └── main.ps1              # Punto di ingresso principale del progetto
├── tests
│   ├── collectors.tests.ps1   # Test per i collector
│   └── analyzers.tests.ps1    # Test per gli analyzer
├── docs
│   └── runbook.md             # Guida operativa su come utilizzare il progetto
├── .gitignore                  # Specifica quali file o cartelle devono essere ignorati
├── ws2022-performance-diagnostics.psd1 # Modulo di configurazione del progetto
├── ws2022-performance-diagnostics.psm1 # Modulo principale del progetto
└── README.md                   # Documentazione del progetto
```

## Installazione

Per installare il progetto, clonare il repository e assicurarsi di avere PowerShell installato su Windows Server 2022.


## Utilizzo

Eseguire il file `main.ps1` per avviare la raccolta delle informazioni sulle prestazioni. I dati raccolti verranno analizzati e possono essere esportati nei formati desiderati.

Oltre ai dati generali di sistema, CPU, memoria, disco, rete, ecc., se il sistema è un host Hyper-V verranno raccolti anche:
- I "vitals" delle VM Hyper-V (stato, CPU, memoria, uptime, ecc.)
- I dettagli dei servizi di integrazione di ciascuna VM (Integration Services)

Questi dati vengono esportati automaticamente in:
- `hyperv-vitals.json` e `hyperv-vitals.csv` (info principali VM)
- `hyperv-integration-services.json` e `hyperv-integration-services.csv` (stato servizi di integrazione per VM)
- `vitals-full.json` (tutti i dati aggregati)

Se viene riportato un errore di policy si può provare con 

```powershell
powershell -ExecutionPolicy Bypass -File ".\src\main.ps1"
```

## Contribuire

Se desideri contribuire a questo progetto, sentiti libero di aprire una pull request o segnalare problemi.

## Licenza

Questo progetto è concesso in licenza sotto la [Licenza MIT](LICENSE).