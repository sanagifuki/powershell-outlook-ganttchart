function Get-HiddenStatusesFromControls {
    $statuses = @()

    if ($ChkHideHold -and $ChkHideHold.IsChecked) { $statuses += "保留" }
    if ($ChkHideDiscarded -and $ChkHideDiscarded.IsChecked) { $statuses += "廃棄" }
    if ($ChkHideCompleted -and $ChkHideCompleted.IsChecked) { $statuses += "完了" }

    return $statuses
}

function Refresh-UI {
    $data = Get-AllData
    $hiddenStatuses = Get-HiddenStatusesFromControls
    $syncTasks = @($data.parsed | Where-Object { Test-TaskStatusVisible -Task $_ -HiddenStatuses $hiddenStatuses })
    
    # === 同期シート・作業ログ ===
    $GridSync.ItemsSource = [System.Collections.ArrayList]@($syncTasks)
    
    $displayLogs = ConvertTo-DisplayWorkLogs -Logs $data.logs -Tasks $data.parsed
    $GridLogs.ItemsSource = [System.Collections.ArrayList]@($displayLogs)
    
    # === ガントチャート ===
    $startDate = $GanttDatePicker.SelectedDate
    if ($startDate -eq $null) { $startDate = (Get-Date).AddDays(-7) }
    $days = [int]($GanttDaysCombo.Text)
    if ($days -eq 0) { $days = 35 }

    $suppressWeekendScheduleHighlight = ($ChkSuppressWeekendHighlight -and $ChkSuppressWeekendHighlight.IsChecked)

    Build-GanttColumns -startDate $startDate -days $days
    $GridGantt.ItemsSource = ConvertTo-GanttDataView -Tasks $data.parsed -Logs $data.logs -StartDate $startDate -Days $days -SuppressWeekendScheduleHighlight $suppressWeekendScheduleHighlight -HiddenStatuses $hiddenStatuses
}
