while ($true) {
    # Gather all data first
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time'
    $cpuCores = Get-Counter '\Processor(*)\% Processor Time' |
        Select-Object -ExpandProperty CounterSamples |
        Where-Object { $_.InstanceName -match '^\d+$' } |
        Sort-Object InstanceName
    $uptimeSpan = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $mem = Get-CimInstance -ClassName Win32_OperatingSystem
    $totalMem = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
    $freeMem = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
    $usedMem = [math]::Round($totalMem - $freeMem, 2)
    $memPct = [math]::Round(($usedMem / $totalMem) * 100, 1)

    $topProcesses = Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 10 Name, Id,
            @{Name="CPU_Time";Expression={"{0:N2}" -f $_.CPU}},
            @{Name="RAM_MB"; Expression={"{0:N1}" -f ($_.WorkingSet64 / 1MB)}}

    try {
        $netStats = Get-NetAdapterStatistics | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                ReceivedMB = [math]::Round($_.ReceivedBytes / 1MB, 2)
                SentMB     = [math]::Round($_.SentBytes / 1MB, 2)
            }
        }
    } catch {
        $netStats = $null
    }

    # Clear screen and display data
    Clear-Host

    Write-Host "=== System Uptime: $($uptimeSpan.Days)d $($uptimeSpan.Hours)h $($uptimeSpan.Minutes)m $($uptimeSpan.Seconds)s ===" -ForegroundColor Yellow

    Write-Host "`n=== CPU Usage ===" -ForegroundColor Cyan
    Write-Host ("Total CPU Usage: {0:N0}%" -f $cpu.CounterSamples[0].CookedValue)
    foreach ($core in $cpuCores) {
        $coreNum = $core.InstanceName
        $usage = "{0:N1}" -f $core.CookedValue
        Write-Host ("Core ${coreNum}: ${usage}%") -ForegroundColor DarkCyan
    }

    Write-Host "`n=== Memory Usage ===" -ForegroundColor Cyan
    Write-Host ("{0} GB used / {1} GB total ({2}% used)" -f $usedMem, $totalMem, $memPct)

    Write-Host "`n=== Top Processes by CPU % ===" -ForegroundColor Cyan
    if ($topProcesses) {
        $topProcesses | Format-Table -AutoSize
    } else {
        Write-Host "Unable to fetch CPU data for processes." -ForegroundColor Red
    }

    Write-Host "`n=== Network Usage (Since Boot) ===" -ForegroundColor Cyan
    if ($netStats) {
        $netStats | Format-Table -AutoSize
    } else {
        Write-Host "Network stats unavailable." -ForegroundColor Red
    }

    Start-Sleep -Seconds 2
}
