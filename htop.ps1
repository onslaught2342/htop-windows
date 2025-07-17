while ($true) {
    Clear-Host

    Write-Host "=== Top Processes by CPU Usage ===" -ForegroundColor Cyan
    Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 10 Name, Id, CPU, @{Name="RAM_MB"; Expression={[math]::Round($_.WorkingSet64 / 1MB, 1)}} |
        Format-Table -AutoSize

    Write-Host "`n=== System Memory Info ===" -ForegroundColor Cyan
    Get-CimInstance -ClassName Win32_OperatingSystem | ForEach-Object {
        $total = $_.TotalVisibleMemorySize / 1MB
        $free = $_.FreePhysicalMemory / 1MB
        $used = $total - $free
        "{0:N2} GB used / {1:N2} GB total ({2:N1}% used)" -f $used, $total, ($used / $total * 100)
    }


    Write-Host "`n=== Network Usage (per Adapter) ===" -ForegroundColor Cyan
    Get-NetAdapterStatistics | ForEach-Object {
        [PSCustomObject]@{
            Name       = $_.Name
            ReceivedMB = [math]::Round($_.ReceivedBytes / 1MB, 2)
            SentMB     = [math]::Round($_.SentBytes / 1MB, 2)
        }
    } | Format-Table -AutoSize

    Start-Sleep -Seconds 3
}
