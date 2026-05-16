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

