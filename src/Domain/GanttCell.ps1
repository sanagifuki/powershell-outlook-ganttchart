function Get-GanttDeadline {
    param($Task)

    $deadline = $Task.終了日
    if ($Task.期限タイプ -eq "絶対期限" -and $Task.終了日 -ne "") {
        try {
            $deadline = ([datetime]$Task.終了日).AddDays(1).ToString("yyyy/MM/dd")
        }
        catch {
            $deadline = $Task.終了日
        }
    }

    return $deadline
}

function Test-GanttInPeriod {
    param(
        $Task,
        [string]$DateText
    )

    $inPeriod = ($Task.開始日 -ne "" -and $Task.終了日 -ne "" -and $DateText -ge $Task.開始日 -and $DateText -le $Task.終了日)
    if ($Task.開始日 -eq "" -and $Task.終了日 -ne "" -and $DateText -eq $Task.終了日) {
        $inPeriod = $true
    }

    return $inPeriod
}

function Get-GanttSymbol {
    param(
        $Task,
        [string]$DateText,
        [string]$TodayText,
        [string]$Deadline,
        [bool]$HasLog,
        [bool]$InPeriod,
        [string]$LastWorkDate
    )

    $symbol = ""

    if ($Task.期限タイプ -eq "参照用") {
        if ($InPeriod -or $DateText -eq $Deadline) {
            return "★"
        }

        return ""
    }

    if ($HasLog) {
        if ($Task.期限タイプ -ne "予定日" -and $Task.ステータス -eq "完了" -and $DateText -eq $LastWorkDate) {
            $symbol = "◉"
        }
        elseif ($Task.期限タイプ -eq "予定日" -and $DateText -eq $Deadline) {
            $symbol = "▶"
        }
        elseif ($InPeriod) {
            $symbol = "■"
        }
        else {
            $symbol = "▲"
        }
    }
    else {
        if ($Task.期限タイプ -eq "絶対期限" -and $DateText -eq $Deadline) {
            $symbol = "✕"
        }
        elseif ($Task.期限タイプ -eq "予定日" -and $DateText -eq $Deadline) {
            $symbol = "▷"
        }
        elseif ($InPeriod) {
            $symbol = "□"
        }
        elseif ($Task.ステータス -ne "完了" -and $Deadline -ne "" -and $DateText -gt $Deadline -and $DateText -lt $TodayText) {
            if ($Task.期限タイプ -ne "予定日") {
                $symbol = "・"
            }
            else {
                $symbol = "＊"
            }
        }
    }

    if ($DateText -eq $Deadline -and $symbol -ne "") {
        if ($Task.期限タイプ -eq "推奨期限") { $symbol += "‼" }
        if ($Task.期限タイプ -eq "目安期限") { $symbol += "❘" }
    }

    return $symbol
}

function Format-GanttCellToolTip {
    param(
        $Task,
        [string]$DateText,
        [string]$Deadline,
        [array]$LogsForDay
    )

    $hasLog = $LogsForDay.Count -gt 0
    $hasTimeOnDeadline = ($DateText -eq $Deadline -and ($Task.開始時間 -ne "" -or $Task.終了時間 -ne ""))
    if (-not $hasLog -and -not $hasTimeOnDeadline) {
        return ""
    }

    $timeInfo = ""
    if ($DateText -eq $Deadline) {
        if ($Task.開始時間 -ne "" -and $Task.終了時間 -ne "") { $timeInfo = "$($Task.開始時間)～$($Task.終了時間)`n`n" }
        elseif ($Task.開始時間 -eq "" -and $Task.終了時間 -ne "") { $timeInfo = "～$($Task.終了時間)`n`n" }
        elseif ($Task.終了時間 -eq "" -and $Task.開始時間 -ne "") { $timeInfo = "$($Task.開始時間)～`n`n" }
    }

    $logEntries = @()
    foreach ($log in $LogsForDay) {
        $logTime = if ($log.time) {
            if ($log.time -match '分$') { $log.time } else { "$($log.time)分" }
        }
        else {
            "0分"
        }
        $logEntries += "作業時間：$logTime`n$($log.content)"
    }

    return ($timeInfo + ($logEntries -join "`n`n")).Trim()
}

function Get-GanttCellBackground {
    param(
        $Task,
        [string]$DateText,
        [string]$TodayText,
        [string]$Symbol
    )

    $background = "Transparent"
    if ($DateText -lt $TodayText) {
        $background = $CLR_GANTT_PAST_BG
    }

    if ($Symbol -ne "") {
        if ($Task.ステータス -eq "完了") {
            $background = "Transparent"
        }
        elseif ($Symbol -match "✕") {
            $background = "#EA4335"
        }
        elseif ($Symbol -eq "★") {
            $background = $CLR_ROW_DISPLAY
        }
        elseif ($Symbol -eq "・") {
            $background = $CLR_STA_OVERDUE_BG
        }
        elseif ($Symbol -match "＊") {
            $background = $CLR_STA_OVERDUE_ABS_BG
        }
        else {
            $background = "#FF9900"
        }
    }

    return $background
}

function Get-GanttCellState {
    param(
        $Task,
        [string]$DateText,
        [string]$TodayText,
        [array]$TaskLogs,
        [string]$LastWorkDate
    )

    $logsForDay = @($TaskLogs | Where-Object { $_.date -eq $DateText })
    $hasLog = $logsForDay.Count -gt 0
    $deadline = Get-GanttDeadline -Task $Task
    $inPeriod = Test-GanttInPeriod -Task $Task -DateText $DateText
    $symbol = Get-GanttSymbol -Task $Task -DateText $DateText -TodayText $TodayText -Deadline $deadline -HasLog $hasLog -InPeriod $inPeriod -LastWorkDate $LastWorkDate
    $tooltip = Format-GanttCellToolTip -Task $Task -DateText $DateText -Deadline $deadline -LogsForDay $logsForDay
    $hasTimeOnThisDay = ($DateText -eq $deadline -and ($Task.開始時間 -ne "" -or $Task.終了時間 -ne ""))

    [PSCustomObject]@{
        Symbol = $symbol
        Background = Get-GanttCellBackground -Task $Task -DateText $DateText -TodayText $TodayText -Symbol $symbol
        ToolTip = $tooltip
        HasToolTip = ($tooltip -ne "")
        InfoVisibility = if ($hasLog -or $hasTimeOnThisDay) { "Visible" } else { "Collapsed" }
    }
}

