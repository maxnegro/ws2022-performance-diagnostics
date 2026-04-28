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