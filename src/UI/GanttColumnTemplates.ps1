function New-GanttFixedCellStyle {
    [System.Windows.Markup.XamlReader]::Parse(@"
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
}

function New-GanttTitleCellTemplate {
    [System.Windows.Markup.XamlReader]::Parse(@"
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
}

function New-GanttDateCellStyle {
    param(
        [string]$DateText,
        [string]$CellBackground
    )

    [System.Windows.Markup.XamlReader]::Parse(@"
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
    <Setter Property="Background" Value="$CellBackground"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Style.Triggers>
        
        <!-- 枠線描画 -->
        <Trigger Property="IsSelected" Value="True">
            <Setter Property="BorderBrush" Value="$CLR_SELECTED_BORDER"/>
        </Trigger>
        
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="$CLR_STA_OVERDUE_BG">
            <Setter Property="Background" Value="$CLR_STA_OVERDUE_BG"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="$CLR_STA_OVERDUE_ABS_BG">
            <Setter Property="Background" Value="$CLR_STA_OVERDUE_ABS_BG"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="$CLR_GANTT_PAST_BG">
            <Setter Property="Background" Value="$CLR_GANTT_PAST_BG"/>
        </DataTrigger>
        
        <!-- 記号の背景色 -->
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="#FF9900">
            <Setter Property="Background" Value="#FF9900"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="#EA4335">
            <Setter Property="Background" Value="#EA4335"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="$CLR_ROW_DISPLAY">
            <Setter Property="Background" Value="$CLR_ROW_DISPLAY"/>
        </DataTrigger>
    </Style.Triggers>
</Style>
"@)
}

function New-GanttDateCellTemplate {
    param([string]$DateText)

    [System.Windows.Markup.XamlReader]::Parse(@"
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Grid Background="Transparent" ToolTipService.IsEnabled="{Binding [${DateText}_Vis]}">
        <Grid.ToolTip>
            <ToolTip>
                <TextBlock Text="{Binding [${DateText}_TT]}" TextWrapping="Wrap" MaxWidth="300" />
            </ToolTip>
        </Grid.ToolTip>
        <TextBlock Text="{Binding [$DateText]}" 
                   HorizontalAlignment="Center" VerticalAlignment="Center" 
                   FontWeight="Bold" FontSize="11" Foreground="$CLR_SYMBOL_FG" FontFamily="$FONT_GANTT"/>
        <!-- Combined Info Mark (Top-Right Blue) -->
        <Polygon Points="7,0 7,7 0,0" Fill="#0078D7" HorizontalAlignment="Right" VerticalAlignment="Top" 
                 Visibility="{Binding [${DateText}_InfoVis]}"/>
    </Grid>
</DataTemplate>
"@)
}
