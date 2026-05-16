function Build-GanttColumns {
    param($startDate, $days)
    
    $GridGantt.Columns.Clear()
    
    $fixedCellStyle = New-GanttFixedCellStyle
    
    # 1. ステータス
    $col1 = New-Object System.Windows.Controls.DataGridTemplateColumn
    $col1.Header = "ステータス"
    $col1.Width = $COL_WIDTH_STATUS
    $col1.CellTemplate = $Form.Resources["BadgeStatusTemplate"]
    $col1.CellStyle = $fixedCellStyle
    $GridGantt.Columns.Add($col1)
    
    # 2. 分類
    $col2 = New-Object System.Windows.Controls.DataGridTemplateColumn
    $col2.Header = "分類"
    $col2.Width = $COL_WIDTH_CAT
    $col2.CellTemplate = $Form.Resources["BadgeCategoryTemplate"]
    $col2.CellStyle = $fixedCellStyle
    $GridGantt.Columns.Add($col2)
    
    # 3. スケジュール名
    $col3 = New-Object System.Windows.Controls.DataGridTemplateColumn
    $col3.Header = "スケジュール名"
    $col3.SortMemberPath = "スケジュール名"
    $col3.Width = $COL_WIDTH_TITLE
    $col3.CellStyle = $fixedCellStyle
    # ヘッダー設定（同期タブと統一）
    $col3.HeaderStyle = New-GanttHeaderStyle -Background $CLR_TITLE_CELL_BG

    $col3.CellTemplate = New-GanttTitleCellTemplate
    $GridGantt.Columns.Add($col3)
    
    $todayStr = (Get-Date).ToString("yyyy/MM/dd")

    # 日付カラム追加
    for ($i = 0; $i -lt $days; $i++) {
        $d = $startDate.AddDays($i)
        $dStr = $d.ToString("yyyy/MM/dd")
        $cellBg = Get-GanttDateCellBackground -Date $d -TodayText $todayStr
        $headerTheme = Get-GanttDateHeaderTheme -Date $d -TodayText $todayStr
        
        $col = New-Object System.Windows.Controls.DataGridTemplateColumn
        $col.Header = $d.ToString("d`n(ddd)")
        $col.SortMemberPath = $dStr
        
        # Apply header style
        $col.HeaderStyle = New-GanttHeaderStyle -Background $headerTheme.Background -Foreground $headerTheme.Foreground
        
        $col.CellStyle = New-GanttDateCellStyle -DateText $dStr -CellBackground $cellBg
        $col.CellTemplate = New-GanttDateCellTemplate -DateText $dStr
        $GridGantt.Columns.Add($col)
    }
}

# 右クリックハンドラは廃止されました

