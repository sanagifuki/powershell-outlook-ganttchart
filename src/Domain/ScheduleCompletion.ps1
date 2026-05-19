function Add-CategoryText {
    param(
        [string]$Categories,
        [string]$Category
    )

    if ([string]::IsNullOrWhiteSpace($Categories)) {
        return $Category
    }
    if ($Categories -like "*$Category*") {
        return $Categories
    }

    return "$Categories, $Category"
}

function Remove-CategoryText {
    param(
        [string]$Categories,
        [string]$Category
    )

    if ([string]::IsNullOrWhiteSpace($Categories)) {
        return ""
    }

    $items = @($Categories -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne $Category })
    return ($items -join ', ')
}

function Set-CachedScheduleCompletion {
    param(
        [array]$Schedules,
        [string]$Uid,
        [bool]$Completed
    )

    foreach ($schedule in $Schedules) {
        if ($schedule.uid -eq $Uid) {
            if ($Completed) {
                $schedule.categories = Add-CategoryText -Categories $schedule.categories -Category "完了"
            }
            else {
                $schedule.categories = Remove-CategoryText -Categories $schedule.categories -Category "完了"
            }
        }
    }

    return @($Schedules)
}

function Set-CachedScheduleCompleted {
    param(
        [array]$Schedules,
        [string]$Uid
    )

    Set-CachedScheduleCompletion -Schedules $Schedules -Uid $Uid -Completed $true
}

function Get-CompletionToggleSchedules {
    param([array]$Schedules)

    @($Schedules)
}

function Get-IncompleteSchedules {
    param([array]$Schedules)

    @($Schedules | Where-Object { $_.ステータス -ne "完了" } | Sort-Object 開始日, タイトル)
}
