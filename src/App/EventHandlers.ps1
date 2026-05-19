function Invoke-OutlookSync {
    param(
        [string]$SuccessPrefix = "同期完了"
    )

    $previousContent = $BtnSync.Content
    $BtnSync.IsEnabled = $false
    $BtnSync.Content = "同期中..."

    try {
        $syncData = Get-OutlookScheduleSyncData -TargetEmail $TARGET_OUTLOOK_EMAIL
        Write-JsonData -Path $TasksFile -Data $syncData.Tasks
        Refresh-UI

        Show-Toast "$SuccessPrefix ($($syncData.Count) 件) - アカウント: $($syncData.Account)"
        return $true
    }
    catch {
        $msg = $_.Exception.Message
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - 同期エラー: $msg" | Out-File (Join-Path $ScriptPath "error.log") -Append -Encoding UTF8
        Show-Toast "同期失敗: $msg"
        return $false
    }
    finally {
        $BtnSync.IsEnabled = $true
        $BtnSync.Content = $previousContent
    }
}

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
                    Invoke-ViewForm -title "メモ - $title" -text $memo -Width 350 -Height 320
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
            Invoke-ViewForm -title "作業ログ ($dateText) - $title" -text $text -Width 350 -Height 320
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

function Get-DisplayedGanttTasks {
    $tasks = @()
    if (-not $GridGantt -or -not $GridGantt.ItemsSource) {
        return $tasks
    }

    foreach ($row in $GridGantt.ItemsSource) {
        $task = $row["OriginalTask"]
        if ($task) {
            $tasks += $task
        }
    }

    return $tasks
}

function Complete-SelectedSchedule {
    $task = Invoke-CompleteSchedulePicker -Tasks (Get-DisplayedGanttTasks)
    if (-not $task) {
        return
    }

    $setCompleted = ($task.ステータス -ne "完了")
    Set-OutlookAppointmentCompletion -EntryId $task.uid -Completed $setCompleted
    $schedules = Read-JsonArray -Path $TasksFile
    $schedules = Set-CachedScheduleCompletion -Schedules $schedules -Uid $task.uid -Completed $setCompleted
    Write-JsonData -Path $TasksFile -Data $schedules
    if ($setCompleted) {
        Show-Toast "完了にしました: $($task.タイトル)"
    }
    else {
        Show-Toast "非完了に戻しました: $($task.タイトル)"
    }
    Invoke-OutlookSync -SuccessPrefix "完了切替後の同期完了"
}

function Edit-SelectedSchedule {
    $task = Invoke-ScheduleEditPicker -Tasks (Get-DisplayedGanttTasks)
    if (-not $task) {
        return
    }

    Invoke-EditAppointmentForm -Task $task
}
