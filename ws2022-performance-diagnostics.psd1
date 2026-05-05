@{
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789abc'
    Author = 'Massimiliano Masserelli'
    CompanyName = ''
    Copyright = 'Copyright © 2026'
    Description = 'Modulo per la raccolta e l\'analisi delle prestazioni di Windows Server 2022.'
    FunctionsToExport = @('Get-CPUInfo', 'Get-MemoryInfo', 'Get-DiskInfo', 'Get-ContextSwitchInfo', 'Get-SystemInfo', 'Analyze-Thresholds', 'Generate-Summary', 'Export-CSV', 'Export-JSON', 'Log-Event')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    NestedModules = @()
    RequiredModules = @()
    RequiredAssemblies = @()
    FileList = @('src/collectors/cpu.ps1', 'src/collectors/memory.ps1', 'src/collectors/disk.ps1', 'src/collectors/system-info.ps1', 'src/analyzers/thresholds.ps1', 'src/analyzers/summary.ps1', 'src/exporters/csv.ps1', 'src/exporters/json.ps1', 'src/exporters/eventlog.ps1', 'src/config/settings.psd1', 'src/main.ps1')
}