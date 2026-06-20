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

function Get-SelectedSchedule {
    if ($MainTab.SelectedIndex -eq 0 -and $GridSync.CurrentItem) {
        return $GridSync.CurrentItem
    }
    if ($MainTab.SelectedIndex -eq 2 -and $GridGantt.SelectedItem) {
        return $GridGantt.SelectedItem["OriginalTask"]
    }
    return $null
}

function Select-DataGridRowUnderMouse {
    param(
        $Grid,
        $OriginalSource
    )

    $element = $OriginalSource
    while ($element -and $element -isnot [System.Windows.Controls.DataGridCell]) {
        $element = [System.Windows.Media.VisualTreeHelper]::GetParent($element)
    }

    if ($element -is [System.Windows.Controls.DataGridCell]) {
        $Grid.CurrentCell = New-Object System.Windows.Controls.DataGridCellInfo($element)
        $element.Focus()
        return $true
    }

    return $false
}

function Initialize-ScheduleContextMenu {
    $contextMenu = New-Object System.Windows.Controls.ContextMenu
    $editItem = New-Object System.Windows.Controls.MenuItem
    $editItem.Header = "予定編集"
    $statusItem = New-Object System.Windows.Controls.MenuItem
    $statusItem.Header = "ステータス切替"

    $editItem.Add_Click({
        try {
            Edit-SelectedSchedule
        }
        catch {
            Show-Toast "編集処理に失敗: $($_.Exception.Message)"
        }
    })
    foreach ($status in @("未着手", "完了", "保留", "廃棄")) {
        $statusChoice = New-Object System.Windows.Controls.MenuItem
        $statusChoice.Header = $status
        $statusChoice.Tag = $status
        $statusChoice.Add_Click({
            try {
                Set-SelectedScheduleStatus -Status ([string]$this.Tag)
            }
            catch {
                Show-Toast "ステータス切替に失敗: $($_.Exception.Message)"
            }
        })
        [void]$statusItem.Items.Add($statusChoice)
    }

    [void]$contextMenu.Items.Add($editItem)
    [void]$contextMenu.Items.Add($statusItem)
    $GridSync.ContextMenu = $contextMenu
}

function Set-SelectedScheduleStatus {
    param([string]$Status)

    $task = Get-SelectedSchedule
    if (-not $task) {
        Show-Toast "スケジュールを選択してください"
        return
    }

    Set-OutlookAppointmentStatus -EntryId $task.uid -Status $Status
    $schedules = Read-JsonArray -Path $TasksFile
    $schedules = Set-CachedScheduleStatus -Schedules $schedules -Uid $task.uid -Status $Status
    Write-JsonData -Path $TasksFile -Data $schedules
    Show-Toast "ステータスを変更しました: $($task.タイトル) => $Status"
    Invoke-OutlookSync -SuccessPrefix "ステータス切替後の同期完了"
}

function Change-SelectedScheduleStatus {
    $selectedTask = Get-SelectedSchedule
    $result = Invoke-StatusSchedulePicker -Tasks (Get-DisplayedGanttTasks) -InitialTask $selectedTask
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
    $task = Get-SelectedSchedule
    if (-not $task) {
        $task = Invoke-ScheduleEditPicker -Tasks (Get-DisplayedGanttTasks)
    }
    if (-not $task) {
        return
    }

    Invoke-EditAppointmentForm -Task $task
}

function Set-ClosedScheduleDisplayCount {
    param(
        [ValidateSet("完了", "廃棄")][string]$Status,
        [int]$Count
    )

    $property = if ($Status -eq "完了") { "completedScheduleDisplayCount" } else { "discardedScheduleDisplayCount" }
    Set-AppSetting -Name $property -Value $Count
    Update-ClosedScheduleCountChecks
    Refresh-UI
}

function Update-ClosedScheduleCountChecks {
    foreach ($item in $CompletedCountItems) {
        $item.IsChecked = ([int]$item.Tag -eq [int]$AppSettings.completedScheduleDisplayCount)
    }
    foreach ($item in $DiscardedCountItems) {
        $item.IsChecked = ([int]$item.Tag -eq [int]$AppSettings.discardedScheduleDisplayCount)
    }
}

function Initialize-AllTabLayouts {
    if (-not $MainTab -or $MainTab.Items.Count -le 1) {
        return
    }

    $selectedIndex = $MainTab.SelectedIndex
    $MainTab.Visibility = [System.Windows.Visibility]::Hidden

    try {
        for ($i = 0; $i -lt $MainTab.Items.Count; $i++) {
            $MainTab.SelectedIndex = $i
            $MainTab.UpdateLayout()
        }
    }
    finally {
        $MainTab.SelectedIndex = $selectedIndex
        $MainTab.UpdateLayout()
        $MainTab.Visibility = [System.Windows.Visibility]::Visible
    }
}
