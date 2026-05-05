# TODO — Refactoring e bugfix

## Bug

- [x] **`main.ps1` — `$cpuData.UtilizzoCPU` è sempre `$null`**  
  `main.ps1` chiama `Get-CPUInfo` (dati grezzi WMI) ma poi usa `$cpuData.UtilizzoCPU`, proprietà che non esiste su quell'oggetto. La funzione corretta è `Collect-CPUData` in `cpu.ps1`, oppure occorre chiamare separatamente `Get-CPUUsage` e costruire l'oggetto metrica in `main.ps1`.

- [x] **`hyperv-vm.ps1` — `$_.VMName` nel blocco `Select-Object` è sempre `$null`**  
  La proprietà calcolata `CPUWaitTimePerDispatchDetails` usa `$_.VMName`, ma gli oggetti restituiti da `Get-VM` espongono `Name`, non `VMName`. Risultato: `CPUWaitTimePerDispatchDetails` è sempre `$null`.

- [x] **`hyperv-vm.ps1` — `CompatibilityForMigration*` mancanti nel `Select-Object` di `Get-VMProcessor`**  
  Riga 12: `Get-VMProcessor | Select-Object` include solo `VMName, Count, MaximumCountPerNumaNode, MaximumCountPerNumaSocket, HwThreadCountPerCore`. Le proprietà `CompatibilityForMigrationEnabled` e `CompatibilityForOlderOperatingSystemsEnabled` vanno aggiunte alla selezione, altrimenti le proprietà calcolate più in basso restituiscono sempre `$null`.

---

## Ridondanze

- [x] **Context Switch raccolto due volte — rimuovere `context-switch.ps1`**  
  `context-switch.ps1` e `performance-advanced.ps1` leggono lo stesso contatore (`Sistema\Commutazioni di contesto/sec`). In `main.ps1` i dati finiscono sia in `$contextSwitchData` che in `$advancedPerf.ContextSwitchesPerSec`. Eliminare `context-switch.ps1`, rimuovere il relativo dot-source da `main.ps1` e usare `$advancedPerf.ContextSwitchesPerSec` ovunque.

- [x] **`Collect-CPUData` e `Collect-ContextSwitchData` — dead code**
  `Collect-CPUData` è ora correttamente chiamata da `main.ps1`. `Collect-ContextSwitchData` è stata rimossa insieme a `context-switch.ps1`.

---

## Inefficienze

- [x] **Cache contatori (`$script:PerfCounterListSetCache`) azzerata ad ogni dot-source**  
  Ogni collector fa dot-source di `counter-resolver.ps1`, che re-esegue `$script:PerfCounterListSetCache = $null`. `Get-Counter -ListSet *` (operazione costosa) viene quindi invocata più volte. Soluzione: caricare `counter-resolver.ps1` una sola volta da `main.ps1` prima degli altri dot-source, oppure portare la cache a scope `$global:`.

- [x] **Codice top-level nei collector eseguito al momento del dot-source**  
  Ogni collector esegue la raccolta dati e stampa l'output al livello radice dello script (es. `$diskResults = Get-DiskPerformance; $diskResults | Format-Table`). Il dot-source da `main.ps1` raccoglie i dati **due volte** e produce output non desiderato in console. Tutto il codice fuori dalle funzioni nei collector va rimosso.

- [x] **`+=` su array in loop in `hyperv-vm.ps1` e `Get-HyperVVMIntegrationServices`**  
  Il pattern `$results += ...` ricrea l'intero array ad ogni iterazione. Sostituire con `[System.Collections.Generic.List[object]]` e il metodo `.Add()`.

---

## Qualità del codice

- [x] **Sostituire `Get-WmiObject` (deprecato) con `Get-CimInstance`**  
  Usato in `cpu.ps1`, `memory.ps1`, `disk.ps1`, `hyperv-vm.ps1`. `Get-WmiObject` è deprecato da PowerShell 3.0 e rimosso in PowerShell 6+.

- [x] **Rimuovere il no-op in `disk.ps1`**  
  Il blocco `if ($null -eq $activePerc) { $activePerc = $null }` assegna `$null` a una variabile già `$null`. Va rimosso.

- [x] **Uniformare i separatori di percorso nei dot-source**  
  Alcuni script usano `\` (es. `cpu.ps1`), altri `/` (es. `memory.ps1`, `disk.ps1`). Adottare un unico stile — preferibilmente `/` per compatibilità cross-platform.

- [x] **Semplificare le proprietà calcolate ripetitive in `hyperv-vm.ps1`**  
  Le 6 proprietà ricavate da `$vmProcessors` ripetono tutte lo stesso pattern con lookup `Where-Object` e un `if ($null -eq $val) { $null } else { $val }` inutile. Precalcolare l'oggetto processore della VM in una variabile (`$proc`) prima del `Select-Object` e referenziarla direttamente nelle espressioni.

---

## Allineamento README

- [x] **Aggiornare README dopo ogni modifica strutturale**  
  Il README deve rispecchiare la struttura reale del progetto. In particolare: se `context-switch.ps1` viene rimosso, aggiornare la sezione *Struttura del Progetto*; se vengono aggiunte/rimosse funzioni esportate, aggiornare la sezione *Utilizzo*.
