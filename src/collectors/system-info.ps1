
Write-Host "[Collector] Inizio raccolta informazioni di sistema"
Get-ComputerInfo | Select-Object CsName, WindowsVersion, WindowsBuildLabEx, OsArchitecture, @{Name='Memory';Expression={(Get-CimInstance -ClassName Win32_OperatingSystem).TotalVisibleMemorySize}}, @{Name='FreeMemory';Expression={(Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory}}, @{Name='Processor';Expression={(Get-CimInstance -ClassName Win32_Processor).Name}}, @{Name='Disk';Expression={(Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3").DeviceID}} | Format-Table -AutoSize

# Questo script raccoglie informazioni generali sul sistema, come nome del computer, versione del sistema operativo e altre informazioni di sistema, utilizzando le chiavi italiane.