function Get-RecentClosedTaskUids {
    param(
        [array]$Tasks,
        [int]$CompletedCount = 5,
        [int]$DiscardedCount = 5
    )

    $completedUids = @($Tasks | Where-Object { $_.ステータス -eq "完了" } | Sort-Object 終了日, 開始日 | Select-Object -Last $CompletedCount | ForEach-Object { $_.uid })
    $discardedUids = @($Tasks | Where-Object { $_.ステータス -eq "廃棄" } | Sort-Object 終了日, 開始日 | Select-Object -Last $DiscardedCount | ForEach-Object { $_.uid })

    return @($completedUids + $discardedUids)
}

function Test-TaskStatusVisible {
    param(
        $Task,
        [array]$HiddenStatuses = @()
    )

    return ($HiddenStatuses -notcontains $Task.ステータス)
}

function Test-GanttTaskVisible {
    param(
        $Task,
        [array]$RecentClosedTaskUids,
        [string]$UnstartedEndLimitText,
        [array]$HiddenStatuses = @()
    )

    if (-not (Test-TaskStatusVisible -Task $Task -HiddenStatuses $HiddenStatuses)) {
        return $false
    }

    if (($Task.ステータス -eq "完了" -or $Task.ステータス -eq "廃棄") -and $RecentClosedTaskUids -notcontains $Task.uid) {
        return $false
    }

    if ($Task.ステータス -eq "未着手" -and $Task.終了日 -ne "" -and $Task.終了日 -gt $UnstartedEndLimitText) {
        return $false
    }

    return $true
}

function Select-GanttVisibleTasks {
    param(
        [array]$Tasks,
        [datetime]$BaseDate = (Get-Date),
        [array]$HiddenStatuses = @(),
        [int]$CompletedCount = 5,
        [int]$DiscardedCount = 5
    )

    $recentClosedTaskUids = Get-RecentClosedTaskUids -Tasks $Tasks -CompletedCount $CompletedCount -DiscardedCount $DiscardedCount
    $unstartedEndLimitText = $BaseDate.AddDays(44).ToString("yyyy/MM/dd")

    foreach ($task in $Tasks) {
        if (Test-GanttTaskVisible -Task $task -RecentClosedTaskUids $recentClosedTaskUids -UnstartedEndLimitText $unstartedEndLimitText -HiddenStatuses $HiddenStatuses) {
            $task
        }
    }
}
