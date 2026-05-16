function Get-GanttDateCellBackground {
    param(
        [datetime]$Date,
        [string]$TodayText
    )

    $dateText = $Date.ToString("yyyy/MM/dd")
    $isToday = ($dateText -eq $TodayText)
    $isWeekend = ($Date.DayOfWeek -eq 'Saturday' -or $Date.DayOfWeek -eq 'Sunday')
    $isOddMonth = ($Date.Month % 2 -eq 1)

    if ($isToday) {
        return $CLR_GANTT_TODAY_BG
    }
    if ($isWeekend) {
        if ($isOddMonth) { return $CLR_GANTT_WE_ODD_BG }
        return $CLR_GANTT_WE_EVEN_BG
    }
    if ($isOddMonth) {
        return $CLR_GANTT_ODD_BG
    }

    return $CLR_GANTT_EVEN_BG
}

function Get-GanttDateHeaderTheme {
    param(
        [datetime]$Date,
        [string]$TodayText
    )

    $dateText = $Date.ToString("yyyy/MM/dd")
    $background = $CLR_GANTT_HDR_DEFAULT_BG
    $foreground = $CLR_GANTT_HDR_FG

    if ($dateText -eq $TodayText) {
        $background = $CLR_GANTT_HDR_TODAY_BG
        $foreground = $CLR_GANTT_HDR_TODAY_FG
    }
    elseif ($Date.Month % 2 -eq 1) {
        $background = $CLR_GANTT_HDR_ODD_BG
    }

    [PSCustomObject]@{
        Background = $background
        Foreground = $foreground
    }
}

