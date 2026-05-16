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
        
        $cellStyleXaml = @"
<Style TargetType="DataGridCell" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <!-- WPFテーマのIsSelectedトリガーによる論理プロパティ上書きを完全遮断するための独立テンプレート -->
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="DataGridCell">
                <Border Background="{TemplateBinding Background}" 
                        BorderThickness="{TemplateBinding BorderThickness}" 
                        BorderBrush="{TemplateBinding BorderBrush}" 
                        SnapsToDevicePixels="True">
                    <ContentPresenter SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}"
                                      HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
                </Border>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
    <Setter Property="Background" Value="$cellBg"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Style.Triggers>
        
        <!-- 枠線描画 -->
        <Trigger Property="IsSelected" Value="True">
            <Setter Property="BorderBrush" Value="$CLR_SELECTED_BORDER"/>
        </Trigger>
        
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="$CLR_STA_OVERDUE_BG">
            <Setter Property="Background" Value="$CLR_STA_OVERDUE_BG"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="$CLR_STA_OVERDUE_ABS_BG">
            <Setter Property="Background" Value="$CLR_STA_OVERDUE_ABS_BG"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="$CLR_GANTT_PAST_BG">
            <Setter Property="Background" Value="$CLR_GANTT_PAST_BG"/>
        </DataTrigger>
        
        <!-- 記号の背景色 -->
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="#FF9900">
            <Setter Property="Background" Value="#FF9900"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="#EA4335">
            <Setter Property="Background" Value="#EA4335"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="$CLR_ROW_DISPLAY">
            <Setter Property="Background" Value="$CLR_ROW_DISPLAY"/>
        </DataTrigger>
    </Style.Triggers>
</Style>
"@
        $col.CellStyle = [System.Windows.Markup.XamlReader]::Parse($cellStyleXaml)

        # Style definition for dynamic Gantt cells (ToolTip via DataTemplate)
        $templateXaml = @"
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Grid Background="Transparent" ToolTipService.IsEnabled="{Binding [${dStr}_Vis]}">
        <Grid.ToolTip>
            <ToolTip>
                <TextBlock Text="{Binding [${dStr}_TT]}" TextWrapping="Wrap" MaxWidth="300" />
            </ToolTip>
        </Grid.ToolTip>
        <TextBlock Text="{Binding [$dStr]}" 
                   HorizontalAlignment="Center" VerticalAlignment="Center" 
                   FontWeight="Bold" FontSize="11" Foreground="$CLR_SYMBOL_FG" FontFamily="$FONT_GANTT"/>
        <!-- Combined Info Mark (Top-Right Blue) -->
        <Polygon Points="7,0 7,7 0,0" Fill="#0078D7" HorizontalAlignment="Right" VerticalAlignment="Top" 
                 Visibility="{Binding [${dStr}_InfoVis]}"/>
    </Grid>
</DataTemplate>
"@
        # テンプレート適用
        $col.CellTemplate = [System.Windows.Markup.XamlReader]::Parse($templateXaml)
        $GridGantt.Columns.Add($col)
    }
}

# 右クリックハンドラは廃止されました

