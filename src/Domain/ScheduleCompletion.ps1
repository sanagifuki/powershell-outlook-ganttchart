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

function Set-CachedScheduleCompleted {
    param(
        [array]$Schedules,
        [string]$Uid
    )

    foreach ($schedule in $Schedules) {
        if ($schedule.uid -eq $Uid) {
            $schedule.categories = Add-CategoryText -Categories $schedule.categories -Category "完了"
        }
    }

    return @($Schedules)
}

function Get-IncompleteSchedules {
    param([array]$Schedules)

    @($Schedules | Where-Object { $_.ステータス -ne "完了" } | Sort-Object 開始日, タイトル)
}
