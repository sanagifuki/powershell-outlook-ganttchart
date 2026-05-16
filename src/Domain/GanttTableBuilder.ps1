function New-GanttDataTable {
    param(
        [datetime]$StartDate,
        [int]$Days
    )

    $table = New-Object System.Data.DataTable
    [void]$table.Columns.Add("ステータス")
    [void]$table.Columns.Add("分類")
    [void]$table.Columns.Add("スケジュール名")
    [void]$table.Columns.Add("メモ")
    [void]$table.Columns.Add("OriginalTask", [object])
    [void]$table.Columns.Add("MemoVis")

    for ($i = 0; $i -lt $Days; $i++) {
        $dateText = $StartDate.AddDays($i).ToString("yyyy/MM/dd")
        [void]$table.Columns.Add($dateText)
        [void]$table.Columns.Add("${dateText}_TT")
        [void]$table.Columns.Add("${dateText}_Vis", [bool])
        [void]$table.Columns.Add("${dateText}_Bg")
        [void]$table.Columns.Add("${dateText}_InfoVis")
    }

    return ,$table
}

function Add-GanttTaskRow {
    param(
        [System.Data.DataTable]$DataTable,
        $Task,
        [array]$Logs,
        [datetime]$StartDate,
        [int]$Days,
        [string]$TodayText
    )

    $row = $DataTable.NewRow()
    $row["ステータス"] = $Task.ステータス
    $row["分類"] = $Task.分類
    $row["スケジュール名"] = $Task.タイトル
    $row["メモ"] = $Task.メモ
    $row["OriginalTask"] = $Task
    $row["MemoVis"] = if (-not [string]::IsNullOrWhiteSpace($Task.メモ) -and $Task.メモ -ne "") { "Visible" } else { "Collapsed" }

    $taskLogs = @($Logs | Where-Object { $_.uid -eq $Task.uid })
    $lastWorkDate = ""
    if ($taskLogs.Count -gt 0) {
        $lastWorkDate = ($taskLogs | Sort-Object date -Descending)[0].date
    }

    for ($i = 0; $i -lt $Days; $i++) {
        $dateText = $StartDate.AddDays($i).ToString("yyyy/MM/dd")
        $cell = Get-GanttCellState -Task $Task -DateText $dateText -TodayText $TodayText -TaskLogs $taskLogs -LastWorkDate $lastWorkDate

        $row[$dateText] = $cell.Symbol
        $row["${dateText}_Bg"] = $cell.Background
        $row["${dateText}_TT"] = $cell.ToolTip
        $row["${dateText}_Vis"] = $cell.HasToolTip
        $row["${dateText}_InfoVis"] = $cell.InfoVisibility
    }

    [void]$DataTable.Rows.Add($row)
}

function ConvertTo-GanttDataView {
    param(
        [array]$Tasks,
        [array]$Logs,
        [datetime]$StartDate,
        [int]$Days,
        [datetime]$BaseDate = (Get-Date)
    )

    $todayText = $BaseDate.ToString("yyyy/MM/dd")
    $table = New-GanttDataTable -StartDate $StartDate -Days $Days

    foreach ($task in (Select-GanttVisibleTasks -Tasks $Tasks -BaseDate $BaseDate)) {
        Add-GanttTaskRow -DataTable $table -Task $task -Logs $Logs -StartDate $StartDate -Days $Days -TodayText $todayText
    }

    return ,$table.DefaultView
}
