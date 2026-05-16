function Build-GanttColumns {
    param($startDate, $days)
    
    $GridGantt.Columns.Clear()
    
    $fixedCellStyle = [System.Windows.Markup.XamlReader]::Parse(@"
<Style TargetType="DataGridCell" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
            <Setter Property="BorderBrush" Value="$CLR_SELECTED_BORDER"/>
        </Trigger>
        <DataTrigger Binding="{Binding ステータス}" Value="完了">
            <Setter Property="Background" Value="$CLR_ROW_COMPLETED"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding ステータス}" Value="廃棄">
            <Setter Property="Background" Value="$CLR_ROW_DISCARDED"/>
        </DataTrigger>
    </Style.Triggers>
</Style>
"@)
    
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
    $col3HeaderStyle = New-Object System.Windows.Style -ArgumentList ([System.Windows.Controls.Primitives.DataGridColumnHeader])
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BackgroundProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($CLR_TITLE_CELL_BG))))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::HorizontalContentAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::PaddingProperty, [System.Windows.Thickness]::new(6, 4, 6, 4))))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderThicknessProperty, [System.Windows.Thickness]::new(0, 0, 1, 1))))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderBrushProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($CLR_BORDER))))
    $col3.HeaderStyle = $col3HeaderStyle

    $col3.CellTemplate = [System.Windows.Markup.XamlReader]::Parse(@"
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Grid Background="Transparent">
        <TextBlock Text="{Binding スケジュール名}" VerticalAlignment="Center" Margin="6,0" TextWrapping="NoWrap">
            <TextBlock.ToolTip>
                <ToolTip>
                    <TextBlock Text="{Binding メモ}" TextWrapping="Wrap" MaxWidth="300" Foreground="#333333"/>
                </ToolTip>
            </TextBlock.ToolTip>
        </TextBlock>
        <Polygon Points="7,0 7,7 0,0" Fill="#0078D7" HorizontalAlignment="Right" VerticalAlignment="Top" 
                 Margin="0,-2,0,0" Visibility="{Binding MemoVis}"/>
    </Grid>
</DataTemplate>
"@)
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
        $headerStyle = New-Object System.Windows.Style([System.Windows.Controls.Primitives.DataGridColumnHeader])
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BackgroundProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($headerTheme.Background))))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::ForegroundProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($headerTheme.Foreground))))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::PaddingProperty, [System.Windows.Thickness]::new(6, 4, 6, 4))))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::HorizontalContentAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.TextBlock]::TextAlignmentProperty, [System.Windows.TextAlignment]::Center)))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::VerticalContentAlignmentProperty, [System.Windows.VerticalAlignment]::Center)))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderThicknessProperty, [System.Windows.Thickness]::new(0, 0, 1, 1))))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderBrushProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($CLR_BORDER))))
        $col.HeaderStyle = $headerStyle
        
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

