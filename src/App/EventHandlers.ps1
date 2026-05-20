function Invoke-OutlookSync {
    param(
        [string]$SuccessPrefix = "同期完了"
    )

    $isMenuItem = ($BtnSync -is [System.Windows.Controls.MenuItem])
    $previousContent = if ($isMenuItem) { $BtnSync.Header } else { $BtnSync.Content }
    $BtnSync.IsEnabled = $false
    if ($isMenuItem) {
        $BtnSync.Header = "同期中..."
    }
    else {
        $BtnSync.Content = "同期中..."
    }

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
        if ($isMenuItem) {
            $BtnSync.Header = $previousContent
        }
        else {
            $BtnSync.Content = $previousContent
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

function Change-SelectedScheduleStatus {
    $result = Invoke-StatusSchedulePicker -Tasks (Get-DisplayedGanttTasks)
    if (-not $result) {
        return
    }

    $task = $result.Task
    $status = $result.Status
    Set-OutlookAppointmentStatus -EntryId $task.uid -Status $status
    $schedules = Read-JsonArray -Path $TasksFile
    $schedules = Set-CachedScheduleStatus -Schedules $schedules -Uid $task.uid -Status $status
    Write-JsonData -Path $TasksFile -Data $schedules
    Show-Toast "ステータスを変更しました: $($task.タイトル) => $status"
    Invoke-OutlookSync -SuccessPrefix "ステータス切替後の同期完了"
}

function Complete-SelectedSchedule {
    Change-SelectedScheduleStatus
}

function Edit-SelectedSchedule {
    $task = Invoke-ScheduleEditPicker -Tasks (Get-DisplayedGanttTasks)
    if (-not $task) {
        return
    }

    Invoke-EditAppointmentForm -Task $task
}
