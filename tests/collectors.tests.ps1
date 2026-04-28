# Test per i collector di prestazioni di Windows Server 2022

# Importa il modulo principale
Import-Module ../ws2022-performance-diagnostics.psm1

# Funzione per testare il collector della CPU
Describe "CPU Collector" {
    It "Should return CPU usage metrics" {
        $result = Get-CPUInfo
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveProperty "Utilizzo"
        $result.Utilizzo | Should -BeGreaterThan 0
    }
}

# Funzione per testare il collector della memoria
Describe "Memory Collector" {
    It "Should return memory usage metrics" {
        $result = Get-MemoryInfo
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveProperty "MemoriaFisica"
        $result.MemoriaFisica | Should -BeGreaterThan 0
    }
}

# Funzione per testare il collector del disco
Describe "Disk Collector" {
    It "Should return disk performance metrics" {
        $result = Get-DiskInfo
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveProperty "UtilizzoDisco"
        $result.UtilizzoDisco | Should -BeGreaterThan 0
    }
}

# Funzione per testare il collector dei context switch
Describe "Context Switch Collector" {
    It "Should return context switch metrics" {
        $result = Get-ContextSwitchInfo
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveProperty "CambiDiContesto"
        $result.CambiDiContesto | Should -BeGreaterThan 0
    }
}


# Funzione per testare il collector delle informazioni di sistema
Describe "System Info Collector" {
    It "Should return system information" {
        $result = Get-SystemInfo
        $result | Should -Not -BeNullOrEmpty
        $result | Should -HaveProperty "NomeComputer"
        $result.NomeComputer | Should -Not -BeNullOrEmpty
    }
}

# Test per Hyper-V VM Vitals e Integration Services (solo se Hyper-V attivo)
Describe "Hyper-V Collectors" {
    $hypervService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if ($null -ne $hypervService -and $hypervService.Status -eq 'Running') {
        . "../src/collectors/hyperv-vm.ps1"
        It "Should collect Hyper-V VM vitals" {
            $vms = Get-HyperVVMVitals
            $vms | Should -Not -BeNullOrEmpty
            $vms | Should -BeOfType System.Object[]
        }
        It "Should collect Hyper-V VM Integration Services" {
            $services = Get-HyperVVMIntegrationServices
            $services | Should -Not -BeNullOrEmpty
            $services | Should -BeOfType System.Object[]
        }
        It "Should export Hyper-V vitals and integration services files" {
            # Simula esportazione come in main.ps1
            $vms = Get-HyperVVMVitals
            $services = Get-HyperVVMIntegrationServices
            if ($vms.Count -gt 0) {
                $jsonPath = "../hyperv-vitals.json"
                $csvPath = "../hyperv-vitals.csv"
                $vms | ConvertTo-Json -Depth 6 | Out-File $jsonPath -Encoding UTF8
                $vms | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Test-Path $jsonPath | Should -BeTrue
                Test-Path $csvPath | Should -BeTrue
            }
            if ($services.Count -gt 0) {
                $jsonPath = "../hyperv-integration-services.json"
                $csvPath = "../hyperv-integration-services.csv"
                $services | ConvertTo-Json -Depth 6 | Out-File $jsonPath -Encoding UTF8
                $services | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Test-Path $jsonPath | Should -BeTrue
                Test-Path $csvPath | Should -BeTrue
            }
        }
    } else {
        It "Should skip Hyper-V tests if not present" {
            $true | Should -BeTrue
        }
    }
}