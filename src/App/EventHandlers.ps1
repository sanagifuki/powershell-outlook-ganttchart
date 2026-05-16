function Handle-SyncGridDoubleClick {
    if ($GridSync.CurrentColumn -and $GridSync.CurrentColumn.Header -eq "スケジュール名") {
        if ($GridSync.CurrentItem) {
            Invoke-LogForm -task $GridSync.CurrentItem
        }
    }
}

function Handle-GanttGridDoubleClick {
    if (-not $GridGantt.CurrentCell.IsValid) {
        return
    }

    $col = $GridGantt.CurrentColumn
    $item = $GridGantt.CurrentCell.Item
    $title = $item["スケジュール名"]
    $taskObj = $item["OriginalTask"]

    if ($col.Header -eq "スケジュール名") {
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
        $dateText = $col.SortMemberPath
        if ($ChkLogMode.IsChecked -and $taskObj) {
            Invoke-LogForm -task $taskObj -defaultDate $dateText
            return
        }

        $text = $item["${dateText}_TT"]
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            Invoke-ViewForm -title "作業ログ ($dateText) - $title" -text $text
        }
    }
}

function Handle-LogsGridDoubleClick {
    if (-not $GridLogs.CurrentItem) {
        return
    }

    $logObj = $GridLogs.CurrentItem
    $data = Get-AllData
    $taskObj = $data.parsed | Where-Object { $_.uid -eq $logObj.uid } | Select-Object -First 1
    if ($taskObj) {
        Invoke-LogForm -task $taskObj -editLog $logObj
    }
}

function Get-SelectedScheduleTask {
    if ($GridGantt.CurrentCell.IsValid -and $GridGantt.CurrentCell.Item) {
        $task = $GridGantt.CurrentCell.Item["OriginalTask"]
        if ($task) { return $task }
    }

    if ($GridSync.CurrentItem) {
        return $GridSync.CurrentItem
    }

    return $null
}

function Complete-SelectedSchedule {
    $task = Get-SelectedScheduleTask
    if (-not $task) {
        Show-Toast "完了にするスケジュールを選択してください"
        return
    }

    Set-OutlookAppointmentCompleted -EntryId $task.uid
    $schedules = Read-JsonArray -Path $TasksFile
    $schedules = Set-CachedScheduleCompleted -Schedules $schedules -Uid $task.uid
    Write-JsonData -Path $TasksFile -Data $schedules
    Refresh-UI
    Show-Toast "完了にしました: $($task.タイトル)"
}
