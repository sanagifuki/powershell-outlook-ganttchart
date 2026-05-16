function Refresh-UI {
    $data = Get-AllData
    
    # === 同期シート・作業ログ ===
    $GridSync.ItemsSource = [System.Collections.ArrayList]@($data.parsed)
    
    $displayLogs = ConvertTo-DisplayWorkLogs -Logs $data.logs -Tasks $data.parsed
    $GridLogs.ItemsSource = [System.Collections.ArrayList]@($displayLogs)
    
    # === ガントチャート ===
    $startDate = $GanttDatePicker.SelectedDate
    if ($startDate -eq $null) { $startDate = (Get-Date).AddDays(-7) }
    $days = [int]($GanttDaysCombo.Text)
    if ($days -eq 0) { $days = 35 }

    $suppressWeekendScheduleHighlight = ($ChkSuppressWeekendHighlight -and $ChkSuppressWeekendHighlight.IsChecked)

    Build-GanttColumns -startDate $startDate -days $days
    $GridGantt.ItemsSource = ConvertTo-GanttDataView -Tasks $data.parsed -Logs $data.logs -StartDate $startDate -Days $days -SuppressWeekendScheduleHighlight $suppressWeekendScheduleHighlight
}

