function Refresh-UI {
    $data = Get-AllData
    
    # === 同期シート・作業ログ ===
    $GridSync.ItemsSource = [System.Collections.ArrayList]@($data.parsed)
    
    # ログ表示用のデータを準備（最新順にソートし、タイトルを紐付け、表示時間を整形）
    $displayLogs = foreach ($l in ($data.logs | Sort-Object date -Descending)) {
        $taskEntry = $data.parsed | Where-Object { $_.uid -eq $l.uid } | Select-Object -First 1
        $title = if ($taskEntry) { $taskEntry.タイトル } else { "不明なスケジュール" }
        
        # タイトルと表示時間をプロパティとして追加
        $l | Add-Member -MemberType NoteProperty -Name "title" -Value $title -Force
        $timeStr = if ($l.time) { if ($l.time -match '分$') { $l.time } else { "$($l.time)分" } } else { "0分" }
        $l | Add-Member -MemberType NoteProperty -Name "displayTime" -Value $timeStr -Force -PassThru
    }
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
    
    # A4: フィルタリング
    $taskArray = $data.parsed
    
    # 完了・廃棄は直近15件ずつ保持する（配列として確実に取得するために @() を使用）
    $compKeep = @($taskArray | Where-Object { $_.ステータス -eq "完了" } | Select-Object -Last 15 | ForEach-Object { $_.uid })
    $discKeep = @($taskArray | Where-Object { $_.ステータス -eq "廃棄" } | Select-Object -Last 15 | ForEach-Object { $_.uid })
    $uidsToKeep = $compKeep + $discKeep
    
    foreach ($p in $taskArray) {
        # 完了・廃棄ステータスの制限（直近のみ表示）
        if (($p.ステータス -eq "完了" -or $p.ステータス -eq "廃棄") -and $uidsToKeep -notcontains $p.uid) { continue }
        
        # 未着手スケジュールのフィルタリング（期限が遠すぎるものは非表示: TODAY + 44日）
        if ($p.ステータス -eq "未着手" -and $p.終了日 -ne "") {
            $endLimitStr = (Get-Date).AddDays(44).ToString("yyyy/MM/dd")
            if ($p.終了日 -gt $endLimitStr) { continue }
        }
        
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

