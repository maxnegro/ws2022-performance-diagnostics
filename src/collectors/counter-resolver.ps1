
# Utility per risolvere in modo robusto i Performance Counter su sistemi localizzati.

$script:PerfCounterListSetCache = $null

function Get-PerfCounterListSetCache {
    if ($null -eq $script:PerfCounterListSetCache) {
        $script:PerfCounterListSetCache = Get-Counter -ListSet *
    }

    return $script:PerfCounterListSetCache
}

function Resolve-PerfCounterPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CounterSetCandidates,

        [Parameter(Mandatory = $true)]
        [string[]]$CounterCandidates,

        [string]$Instance = "_Total"
    )

    $sets = Get-PerfCounterListSetCache

    foreach ($setCandidate in $CounterSetCandidates) {
        $matchedSet = $sets | Where-Object {
            $_.CounterSetName -ieq $setCandidate
        } | Select-Object -First 1

        if ($null -eq $matchedSet) {
            continue
        }

        foreach ($counterCandidate in $CounterCandidates) {
            if ($Instance -eq '*') {
                # Per wildcard, usa un path realmente presente nel set per evitare mismatch lingua.
                $wildcardPath = @($matchedSet.Paths) | Where-Object {
                    $_ -imatch "^\\\\$([regex]::Escape($matchedSet.CounterSetName))\\\(\*\\\)\\$([regex]::Escape($counterCandidate))$"
                } | Select-Object -First 1

                if ($null -ne $wildcardPath) {
                    return $wildcardPath
                }

                $fallbackWildcardPath = @($matchedSet.Paths) | Where-Object {
                    $_ -imatch "\\$([regex]::Escape($counterCandidate))$"
                } | Select-Object -First 1

                if ($null -ne $fallbackWildcardPath) {
                    return $fallbackWildcardPath
                }

                continue
            }

            $paths = @($matchedSet.PathsWithInstances + $matchedSet.Paths)

            $exactPath = $paths | Where-Object {
                $_ -imatch "^\\\\$([regex]::Escape($matchedSet.CounterSetName))\\\($([regex]::Escape($Instance))\\\)\\$([regex]::Escape($counterCandidate))$"
            } | Select-Object -First 1

            if ($null -ne $exactPath) {
                return $exactPath
            }

            $fallbackPath = $paths | Where-Object {
                $_ -imatch "\\$([regex]::Escape($counterCandidate))$"
            } | Select-Object -First 1

            if ($null -ne $fallbackPath) {
                return $fallbackPath
            }
        }
    }

    return $null
}

function Get-ResolvedCounterCookedValue {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CounterSetCandidates,

        [Parameter(Mandatory = $true)]
        [string[]]$CounterCandidates,

        [string]$Instance = "_Total"
    )

    $path = Resolve-PerfCounterPath -CounterSetCandidates $CounterSetCandidates -CounterCandidates $CounterCandidates -Instance $Instance
    if ([string]::IsNullOrWhiteSpace($path)) {
        return $null
    }

    $counter = Get-Counter -Counter $path
    if ($null -eq $counter -or $null -eq $counter.CounterSamples -or $counter.CounterSamples.Count -eq 0) {
        return $null
    }

    return $counter.CounterSamples[0].CookedValue
}
