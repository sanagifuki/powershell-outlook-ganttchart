function Get-AllData {
    $tasks = if (Test-Path $TasksFile) { Get-Content $TasksFile -Raw -Encoding UTF8 | ConvertFrom-Json } else { @() }
    $logs = if (Test-Path $LogsFile) { Get-Content $LogsFile -Raw -Encoding UTF8 | ConvertFrom-Json } else { @() }
    $status = @{} # No longer used
    
    $parsed = foreach ($t in $tasks) {
        ConvertTo-ScheduleItem -Task $t
    }
    return @{ parsed = @($parsed); logs = @($logs); status = $status }
}

