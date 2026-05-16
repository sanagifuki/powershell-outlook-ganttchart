function Add-GanttFixedColumns {
    $fixedCellStyle = New-GanttFixedCellStyle

    $statusColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
    $statusColumn.Header = "ステータス"
    $statusColumn.Width = $COL_WIDTH_STATUS
    $statusColumn.CellTemplate = $Form.Resources["BadgeStatusTemplate"]
    $statusColumn.CellStyle = $fixedCellStyle
    $GridGantt.Columns.Add($statusColumn)

    $categoryColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
    $categoryColumn.Header = "分類"
    $categoryColumn.Width = $COL_WIDTH_CAT
    $categoryColumn.CellTemplate = $Form.Resources["BadgeCategoryTemplate"]
    $categoryColumn.CellStyle = $fixedCellStyle
    $GridGantt.Columns.Add($categoryColumn)

    $titleColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
    $titleColumn.Header = "スケジュール名"
    $titleColumn.SortMemberPath = "スケジュール名"
    $titleColumn.Width = $COL_WIDTH_TITLE
    $titleColumn.CellStyle = $fixedCellStyle
    $titleColumn.HeaderStyle = New-GanttHeaderStyle -Background $CLR_TITLE_CELL_BG
    $titleColumn.CellTemplate = New-GanttTitleCellTemplate
    $GridGantt.Columns.Add($titleColumn)
}

function Add-GanttDateColumn {
    param(
        [datetime]$Date,
        [string]$TodayText
    )

    $dateText = $Date.ToString("yyyy/MM/dd")
    $cellBackground = Get-GanttDateCellBackground -Date $Date -TodayText $TodayText
    $headerTheme = Get-GanttDateHeaderTheme -Date $Date -TodayText $TodayText

    $column = New-Object System.Windows.Controls.DataGridTemplateColumn
    $column.Header = $Date.ToString("d`n(ddd)")
    $column.SortMemberPath = $dateText
    $column.HeaderStyle = New-GanttHeaderStyle -Background $headerTheme.Background -Foreground $headerTheme.Foreground
    $column.CellStyle = New-GanttDateCellStyle -DateText $dateText -CellBackground $cellBackground
    $column.CellTemplate = New-GanttDateCellTemplate -DateText $dateText

    $GridGantt.Columns.Add($column)
}

function Build-GanttColumns {
    param($startDate, $days)

    $GridGantt.Columns.Clear()
    Add-GanttFixedColumns

    $todayText = (Get-Date).ToString("yyyy/MM/dd")

    for ($i = 0; $i -lt $days; $i++) {
        Add-GanttDateColumn -Date ($startDate.AddDays($i)) -TodayText $todayText
    }
}

# 右クリックハンドラは廃止されました

