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
            $hasLog = @($pLogs | Where-Object { $_.date -eq $dStr }).Count -gt 0
            $inPeriod = ($p.開始日 -ne "" -and $p.終了日 -ne "" -and $dStr -ge $p.開始日 -and $dStr -le $p.終了日)
            if ($p.開始日 -eq "" -and $p.終了日 -ne "" -and $dStr -eq $p.終了日) { $inPeriod = $true }

            $sym = ""
            $deadline = $p.終了日
            if ($p.期限タイプ -eq "絶対期限" -and $p.終了日 -ne "") { 
                try { $deadline = ([datetime]$p.終了日).AddDays(1).ToString("yyyy/MM/dd") } catch {}
            }
            
            if ($p.期限タイプ -eq "参照用") {
                if ($inPeriod -or $dStr -eq $deadline) { $sym = "★" }
            }
            else {
                if ($hasLog) {
                    if ($p.期限タイプ -ne "予定日" -and $p.ステータス -eq "完了" -and $dStr -eq $lastWorkDate) {
                        $sym = "◉"
                    }
                    elseif ($p.期限タイプ -eq "予定日" -and $dStr -eq $deadline) {
                        $sym = "▶"
                    }
                    elseif ($inPeriod) {
                        $sym = "■"
                    }
                    else {
                        $sym = "▲"
                    }
                }
                else {
                    if ($p.期限タイプ -eq "絶対期限" -and $dStr -eq $deadline) {
                        $sym = "✕"
                    }
                    elseif ($p.期限タイプ -eq "予定日" -and $dStr -eq $deadline) {
                        $sym = "▷"
                    }
                    elseif ($inPeriod) {
                        $sym = "□"
                    }
                    else {
                        if ($p.ステータス -ne "完了" -and $deadline -ne "" -and $dStr -gt $deadline -and $dStr -lt $todayStr) {
                            if ($p.期限タイプ -ne "予定日") {
                                $sym = "・"
                            }
                            else {
                                $sym = "＊"
                            }
                        }
                    }
                }
                
                if ($dStr -eq $deadline -and $sym -ne "") {
                    if ($p.期限タイプ -eq "推奨期限") { $sym += "‼" }
                    if ($p.期限タイプ -eq "目安期限") { $sym += "❘" }
                }
            }
            
            # --- ToolTip Logs + Time Info Construction ---
            $logText = ""
            if ($hasLog -or ($dStr -eq $deadline -and ($p.開始時間 -ne "" -or $p.終了時間 -ne ""))) {
                $timeInfo = ""
                if ($dStr -eq $deadline) {
                    if ($p.開始時間 -ne "" -and $p.終了時間 -ne "") { $timeInfo = "$($p.開始時間)～$($p.終了時間)`n`n" }
                    elseif ($p.開始時間 -eq "" -and $p.終了時間 -ne "") { $timeInfo = "～$($p.終了時間)`n`n" }
                    elseif ($p.終了時間 -eq "" -and $p.開始時間 -ne "") { $timeInfo = "$($p.開始時間)～`n`n" }
                }

                $logEntries = @()
                if ($hasLog) {
                    $logsForDay = $pLogs | Where-Object { $_.date -eq $dStr }
                    foreach ($l in $logsForDay) {
                        $lTime = if ($l.time) { if ($l.time -match '分$') { $l.time } else { "$($l.time)分" } } else { "0分" }
                        $logEntries += "作業時間：$lTime`n$($l.content)"
                    }
                }
                
                $logJoin = $logEntries -join "`n`n"
                $logText = $timeInfo + $logJoin
                $logText = $logText.Trim()
            }
            
            $bg = "Transparent"
            # 今日より前の日付（過去）を紫色にする
            if ($dStr -lt $todayStr) { $bg = $CLR_GANTT_PAST_BG }

            if ($sym -ne "") {
                if ($p.ステータス -eq "完了") {
                    $bg = "Transparent"
                }
                elseif ($sym -match "✕") {
                    $bg = "#EA4335" # Red
                }
                elseif ($sym -eq "★") {
                    $bg = $CLR_ROW_DISPLAY # Yellow
                }
                elseif ($sym -eq "・") {
                    $bg = $CLR_STA_OVERDUE_BG # Light Pink
                }
                elseif ($sym -match "＊") {
                    $bg = $CLR_STA_OVERDUE_ABS_BG # Light Red
                }
                else {
                    $bg = "#FF9900" # Orange
                }
            }
            
            $row[$dStr] = $sym
            $row["${dStr}_Bg"] = $bg
            $row["${dStr}_TT"] = $logText
            $row["${dStr}_Vis"] = ($logText -ne "")
            
            # 統合コーナーマーク（右上・青）：ログがある場合、または時間設定（開始・終了）がある場合（期限日）
            $hasTimeOnThisDay = ($dStr -eq $deadline -and ($p.開始時間 -ne "" -or $p.終了時間 -ne ""))
            $row["${dStr}_InfoVis"] = if ($hasLog -or $hasTimeOnThisDay) { "Visible" } else { "Collapsed" }
        }
        [void]$dt.Rows.Add($row)
    }
    $GridGantt.ItemsSource = $dt.DefaultView
}

