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

    Build-GanttColumns -startDate $startDate -days $days
    
    $todayStr = (Get-Date).ToString("yyyy/MM/dd")
    $dt = New-Object System.Data.DataTable
    [void]$dt.Columns.Add("ステータス"); [void]$dt.Columns.Add("分類"); [void]$dt.Columns.Add("スケジュール名"); [void]$dt.Columns.Add("メモ"); [void]$dt.Columns.Add("OriginalTask", [object]); [void]$dt.Columns.Add("MemoVis");
    for ($i = 0; $i -lt $days; $i++) { 
        $tdateStr = $startDate.AddDays($i).ToString("yyyy/MM/dd")
        [void]$dt.Columns.Add($tdateStr)
        [void]$dt.Columns.Add("${tdateStr}_TT")
        [void]$dt.Columns.Add("${tdateStr}_Vis", [bool])
        [void]$dt.Columns.Add("${tdateStr}_Bg")
        [void]$dt.Columns.Add("${tdateStr}_InfoVis")
    }
    
    foreach ($p in (Select-GanttVisibleTasks -Tasks $data.parsed)) {
        $row = $dt.NewRow()
        $row["ステータス"] = $p.ステータス; $row["分類"] = $p.分類; $row["スケジュール名"] = $p.タイトル; $row["メモ"] = $p.メモ; $row["OriginalTask"] = $p
        $row["MemoVis"] = if (-not [string]::IsNullOrWhiteSpace($p.メモ) -and $p.メモ -ne "") { "Visible" } else { "Collapsed" }
        
        $pLogs = @($data.logs | Where-Object { $_.uid -eq $p.uid }) 
        $lastWorkDate = ""
        if ($pLogs.Count -gt 0) {
            $lastWorkDate = ($pLogs | Sort-Object date -Descending)[0].date
        }
        
        for ($i = 0; $i -lt $days; $i++) {
            $dStr = $startDate.AddDays($i).ToString("yyyy/MM/dd")
            $cell = Get-GanttCellState -Task $p -DateText $dStr -TodayText $todayStr -TaskLogs $pLogs -LastWorkDate $lastWorkDate
            
            $row[$dStr] = $cell.Symbol
            $row["${dStr}_Bg"] = $cell.Background
            $row["${dStr}_TT"] = $cell.ToolTip
            $row["${dStr}_Vis"] = $cell.HasToolTip
            $row["${dStr}_InfoVis"] = $cell.InfoVisibility
        }
        [void]$dt.Rows.Add($row)
    }
    $GridGantt.ItemsSource = $dt.DefaultView
}

