function Get-AllData {
    $tasks = Read-JsonArray -Path $TasksFile
    $logs = Read-JsonArray -Path $LogsFile
    $status = @{} # No longer used
    
    $parsed = foreach ($t in $tasks) {
        ConvertTo-ScheduleItem -Task $t
    }
    return @{ parsed = @($parsed); logs = @($logs); status = $status }
}

