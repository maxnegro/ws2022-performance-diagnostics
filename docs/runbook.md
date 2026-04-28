# Runbook per il Progetto di Diagnostica delle Prestazioni di Windows Server 2022

## Introduzione
Questo runbook fornisce istruzioni dettagliate su come utilizzare il progetto di diagnostica delle prestazioni per Windows Server 2022. Il progetto è progettato per raccogliere informazioni essenziali riguardanti le prestazioni del sistema, inclusi disco, processore, memoria e context switch.

## Requisiti
- Windows Server 2022
- PowerShell 5.1 o superiore
- Permessi di amministratore per l'esecuzione degli script

## Installazione
1. Clonare il repository del progetto:
   ```powershell
   git clone <URL_DEL_REPOSITORY>
   ```
2. Navigare nella cartella del progetto:
   ```powershell
   cd ws2022-performance-diagnostics
   ```
3. Assicurarsi che tutte le dipendenze siano installate. Eseguire il seguente comando per installare eventuali moduli richiesti:
   ```powershell
   Install-Module -Name <NomeModulo> -Force
   ```

## Utilizzo

### Raccolta Dati
Per raccogliere informazioni sulle prestazioni, eseguire il file principale:
```powershell
.\src\main.ps1
```
Questo script orchestrerà la raccolta dei dati utilizzando i vari collector.

Se il sistema è un host Hyper-V, verranno raccolti e salvati automaticamente anche:
- I "vitals" delle VM Hyper-V (stato, CPU, memoria, uptime, ecc.)
- I dettagli dei servizi di integrazione di ciascuna VM (Integration Services)

### Analisi Dati
Dopo la raccolta, i dati verranno analizzati automaticamente. I risultati saranno disponibili nel formato specificato (CSV, JSON, o registrati nel registro eventi).

### Esportazione Dati
I dati raccolti vengono esportati automaticamente nei seguenti file:
- `vitals-full.json` (tutti i dati aggregati)
- `hyperv-vitals.json` e `hyperv-vitals.csv` (info principali VM Hyper-V)
- `hyperv-integration-services.json` e `hyperv-integration-services.csv` (stato servizi di integrazione per VM)

Puoi anche esportare manualmente i dati usando gli exporter dedicati:
- Per CSV:
  ```powershell
  .\src\exporters\csv.ps1
  ```
- Per JSON:
  ```powershell
  .\src\exporters\json.ps1
  ```
- Per il registro eventi:
  ```powershell
  .\src\exporters\eventlog.ps1
  ```

## Test
Il progetto include test per garantire che i collector e gli analyzer funzionino correttamente. Per eseguire i test, utilizzare i seguenti comandi:
```powershell
.\tests\collectors.tests.ps1
.\tests\analyzers.tests.ps1
```

## Gestione dei Performance Counter Localizzati

Per garantire la compatibilità sia con sistemi Windows Server in italiano che in inglese, il progetto utilizza un modulo helper (`src/collectors/counter-resolver.ps1`) che risolve automaticamente i nomi dei performance counter, provando tutte le varianti note (ITA/ENG) e utilizzando un fallback locale-invariant tramite classi CIM/WMI se necessario.

### Come funziona
- Ogni collector che deve leggere un performance counter importa `counter-resolver.ps1` e usa la funzione `Get-ResolvedCounterCookedValue`, passando una lista di possibili nomi del set e del contatore (es. `@('Processor', 'Informazioni processore')`, `@('% Processor Time', '% Tempo processore')`).
- Se il counter non viene trovato, viene usato un fallback tramite classi CIM/WMI che non dipendono dalla lingua del sistema.

### Esempio di utilizzo
```powershell
. "$PSScriptRoot/counter-resolver.ps1"
$cpuUsage = Get-ResolvedCounterCookedValue `
  -CounterSetCandidates @('Processor', 'Informazioni processore') `
  -CounterCandidates @('% Processor Time', '% Tempo processore') `
  -Instance '_Total'
if ($null -eq $cpuUsage) {
  # Fallback locale-invariant
  $cpuUsage = (Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
}
```

### Collector già compatibili
- CPU, Context Switch, Memoria, Disco: tutti i collector principali usano già questa logica e sono robusti rispetto alla localizzazione.

### Come aggiungere nuovi collector
1. Importa `counter-resolver.ps1` nel tuo script.
2. Usa `Get-ResolvedCounterCookedValue` con tutte le varianti note di nome set/counter.
3. Prevedi sempre un fallback CIM/WMI se il counter non viene trovato.

In questo modo la raccolta dati non fallirà mai a causa di differenze di lingua tra installazioni Windows.

## Raccolta automatica dei vitals delle VM Hyper-V

Se il sistema rileva che l’host è un Hyper-V attivo, viene eseguita automaticamente la raccolta dei principali parametri di performance delle VM installate. I dati raccolti per ogni VM includono:

- Nome e ID VM
- Utilizzo CPU guest
- RAM assegnata, richiesta e stato
- Informazioni sui dischi virtuali collegati
- Context switch/sec (se disponibile)
- CPU wait time per dispatch (se disponibile)
- Percentuale tempo guest in esecuzione (starving/ready)

La raccolta utilizza sempre la logica localizzazione-safe per i performance counter, con fallback CIM/WMI dove necessario.

### Come viene attivata
La raccolta delle VM viene eseguita solo se il servizio Hyper-V (vmms) è attivo sull’host. In caso contrario, la sezione viene saltata automaticamente.

### Estensione
Per aggiungere nuovi parametri o personalizzare la raccolta delle VM, modificare lo script `src/collectors/hyperv-vm.ps1` seguendo il pattern già adottato per la risoluzione dei counter.

## Conclusione
Questo runbook fornisce una guida operativa per l'utilizzo del progetto di diagnostica delle prestazioni di Windows Server 2022. Seguire le istruzioni per raccogliere, analizzare ed esportare i dati delle prestazioni del sistema.