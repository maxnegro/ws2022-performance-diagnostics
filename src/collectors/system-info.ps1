
# Raccoglie informazioni generali sul sistema.
function Get-SystemInfo {
    $os  = Get-CimInstance -ClassName Win32_OperatingSystem
    $cs  = Get-CimInstance -ClassName Win32_ComputerSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    return [PSCustomObject]@{
        ComputerName       = $env:COMPUTERNAME
        Domain             = $cs.Domain
        Manufacturer       = $cs.Manufacturer
        Model              = $cs.Model
        OSName             = $os.Caption
        OSVersion          = $os.Version
        OSBuildNumber      = $os.BuildNumber
        OSArchitecture     = $os.OSArchitecture
        ProcessorName      = $cpu.Name
        ProcessorCores     = $cpu.NumberOfCores
        ProcessorLogical   = $cpu.NumberOfLogicalProcessors
        TotalPhysicalMemGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    }
}