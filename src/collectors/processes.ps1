# Raccoglie i top processi per CPU e memoria
function Get-TopProcesses {
    $topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, WorkingSet
    $topMem = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 Name, Id, CPU, WorkingSet
    return [PSCustomObject]@{
        TopByCPU = $topCPU | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                ProcessId = $_.Id
                CPU = $_.CPU
                WorkingSetMB = [math]::Round($_.WorkingSet/1MB,2)
            }
        }
        TopByMemory = $topMem | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                ProcessId = $_.Id
                CPU = $_.CPU
                WorkingSetMB = [math]::Round($_.WorkingSet/1MB,2)
            }
        }
    }
}
