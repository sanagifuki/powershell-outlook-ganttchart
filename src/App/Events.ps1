# --- Events ---
$BtnSync.Add_Click({
        $BtnSync.IsEnabled = $false
        $BtnSync.Content = "同期中..."
        try {
            $syncData = Get-OutlookScheduleSyncData -TargetEmail $TARGET_OUTLOOK_EMAIL
            Write-JsonData -Path $TasksFile -Data $syncData.Tasks
            Refresh-UI
        
            Show-Toast "同期完了 ($($syncData.Count) 件) - アカウント: $($syncData.Account)"
        }
        catch {
            $msg = $_.Exception.Message
            "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - 同期エラー: $msg" | Out-File (Join-Path $ScriptPath "error.log") -Append -Encoding UTF8
            Show-Toast "同期失敗: $msg"
        }
        finally {
            $BtnSync.IsEnabled = $true
            $BtnSync.Content = "Outlook同期"
        }
    })

$GanttDatePicker.Add_SelectedDateChanged({ Refresh-UI })
$GanttDaysCombo.Add_DropDownClosed({ Refresh-UI })

$BtnHelp.Add_Click({
        Invoke-ViewForm -title "留意事項・ヘルプ" -text (Get-HelpText)
    })

$BtnResetView.Add_Click({
        # GridSync のリセット
        $GridSync.Columns | ForEach-Object { $_.Width = [System.Windows.Controls.DataGridLength]::Auto }
        if ($GridSync.Columns.Count -gt 1) { $GridSync.Columns[1].Width = $COL_WIDTH_TITLE } # スケジュール名
        if ($GridSync.Columns.Count -gt 2) { $GridSync.Columns[2].Width = $COL_WIDTH_STATUS } # ステータス
        if ($GridSync.Columns.Count -gt 3) { $GridSync.Columns[3].Width = $COL_WIDTH_TYPE }   # 期限タイプ
        if ($GridSync.Columns.Count -gt 4) { $GridSync.Columns[4].Width = $COL_WIDTH_CAT }    # 分類
        if ($GridSync.Columns.Count -gt 5) { $GridSync.Columns[5].Width = $COL_WIDTH_DATE }   # 開始日
        if ($GridSync.Columns.Count -gt 6) { $GridSync.Columns[6].Width = $COL_WIDTH_DATE }   # 終了日
        if ($GridSync.Columns.Count -gt 7) { $GridSync.Columns[7].Width = $COL_WIDTH_TIME }   # 開始
        if ($GridSync.Columns.Count -gt 8) { $GridSync.Columns[8].Width = $COL_WIDTH_TIME }   # 終了
        # 最後の列（メモ）を Star にする
        if ($GridSync.Columns.Count -gt 9) { $GridSync.Columns[9].Width = $COL_WIDTH_MEMO }   # メモ
        for ($i = 0; $i -lt $GridSync.Columns.Count; $i++) { $GridSync.Columns[$i].DisplayIndex = $i }

        # GridLogs のリセット
        if ($GridLogs.Columns.Count -gt 0) { $GridLogs.Columns[0].Width = $COL_WIDTH_TITLE } # 対象スケジュール名
        if ($GridLogs.Columns.Count -gt 1) { $GridLogs.Columns[1].Width = [System.Windows.Controls.DataGridLength]::new(1, [System.Windows.Controls.DataGridLengthUnitType]::Star) } # 作業内容
        for ($i = 0; $i -lt $GridLogs.Columns.Count; $i++) { $GridLogs.Columns[$i].DisplayIndex = $i }

        # GridGantt のリセット
        Build-GanttColumns
        Refresh-UI
        Show-Toast "表示をリセットしました"
    })

$GridSync.Add_MouseDoubleClick({
        if ($GridSync.CurrentColumn -and $GridSync.CurrentColumn.Header -eq "スケジュール名") {
            if ($GridSync.CurrentItem) { Invoke-LogForm -task $GridSync.CurrentItem }
        }
    })
$GridGantt.Add_MouseDoubleClick({
        if ($GridGantt.CurrentCell.IsValid) {
            $col = $GridGantt.CurrentColumn
            $item = $GridGantt.CurrentCell.Item
            $title = $item["スケジュール名"]
            $taskObj = $item["OriginalTask"]

            if ($col.Header -eq "スケジュール名") {
                # スケジュール名列の動作切替
                if ($taskObj) {
                    if ($ChkLogMode.IsChecked) {
                        Invoke-LogForm -task $taskObj
                    }
                    else {
                        $memo = $item["メモ"]
                        if (-not [string]::IsNullOrWhiteSpace($memo)) {
                            Invoke-ViewForm -title "メモ - $title" -text $memo
                        }
                    }
                }
            }
            elseif ($col -is [System.Windows.Controls.DataGridTemplateColumn] -and $col.SortMemberPath) {
                # 日付セル（記号列）ならログ表示画面を開く（従来通り）
                $dStr = $col.SortMemberPath
                $text = $item["${dStr}_TT"]
                if (-not [string]::IsNullOrWhiteSpace($text)) {
                    Invoke-ViewForm -title "作業ログ ($dStr) - $title" -text $text
                }
            }
        }
    })
$GridLogs.Add_MouseDoubleClick({
        if ($GridLogs.CurrentItem) {
            $logObj = $GridLogs.CurrentItem
            $data = Get-AllData
            $taskObj = $data.parsed | Where-Object { $_.uid -eq $logObj.uid } | Select-Object -First 1
            if ($taskObj) { Invoke-LogForm -task $taskObj -editLog $logObj }
        }
    })

# INITIAL LOAD
Refresh-UI
$Form.ShowDialog()

