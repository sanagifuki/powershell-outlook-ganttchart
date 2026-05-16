function Get-RecentClosedTaskUids {
    param([array]$Tasks)

    $completedUids = @($Tasks | Where-Object { $_.ステータス -eq "完了" } | Select-Object -Last 15 | ForEach-Object { $_.uid })
    $discardedUids = @($Tasks | Where-Object { $_.ステータス -eq "廃棄" } | Select-Object -Last 15 | ForEach-Object { $_.uid })

    return @($completedUids + $discardedUids)
}

function Test-GanttTaskVisible {
    param(
        $Task,
        [array]$RecentClosedTaskUids,
        [string]$UnstartedEndLimitText
    )

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
        [datetime]$BaseDate = (Get-Date)
    )

    $recentClosedTaskUids = Get-RecentClosedTaskUids -Tasks $Tasks
    $unstartedEndLimitText = $BaseDate.AddDays(44).ToString("yyyy/MM/dd")

    foreach ($task in $Tasks) {
        if (Test-GanttTaskVisible -Task $task -RecentClosedTaskUids $recentClosedTaskUids -UnstartedEndLimitText $unstartedEndLimitText) {
            $task
        }
    }
}

