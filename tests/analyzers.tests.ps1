# Importa il modulo principale per accedere alle funzioni
Import-Module ../src/ws2022-performance-diagnostics.psm1

Describe "Analyzer Tests" {
    Context "Thresholds Analyzer" {
        It "Should identify performance issues correctly" {
            # Simula dati di input per il test
            $testData = @{
                "CPUUsage" = 85
                "MemoryUsage" = 75
                "DiskUsage" = 90
                "ContextSwitches" = 1500
            }

            # Chiama la funzione di analisi delle soglie
            $result = Analyze-Thresholds -Data $testData

            # Verifica che il risultato indichi un problema di performance
            $result.Should -Be "Performance issue detected"
        }
    }

    Context "Summary Analyzer" {
        It "Should generate a summary report" {
            # Simula dati di input per il test
            $summaryData = @{
                "TotalCPUUsage" = 70
                "TotalMemoryUsage" = 60
                "TotalDiskUsage" = 80
                "TotalContextSwitches" = 1200
            }

            # Chiama la funzione di generazione del riepilogo
            $summary = Generate-Summary -Data $summaryData

            # Verifica che il riepilogo contenga le informazioni corrette
            $summary.Should -Contain "CPU Usage: 70%"
            $summary.Should -Contain "Memory Usage: 60%"
            $summary.Should -Contain "Disk Usage: 80%"
            $summary.Should -Contain "Context Switches: 1200"
        }
    }
}