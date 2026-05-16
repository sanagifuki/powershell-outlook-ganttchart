[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="スケジュール管理システム" Height="600" Width="769" MinWidth="769" MinHeight="600"
        Background="#F5F5F5" Foreground="#333333" FontFamily="$FONT_MAIN" FontSize="11"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <!-- Hide default selection background colors globally to ensure border-only selection -->
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="Transparent"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.InactiveSelectionHighlightBrushKey}" Color="Transparent"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightTextBrushKey}" Color="#333333"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.InactiveSelectionHighlightTextBrushKey}" Color="#333333"/>

        <!-- Common Styles -->
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="RowBackground" Value="#FFFFFF"/>
            <Setter Property="AlternatingRowBackground" Value="#F9F9F9"/>
            <Setter Property="Foreground" Value="#333333"/>
            <Setter Property="GridLinesVisibility" Value="All"/>
            <Setter Property="HorizontalGridLinesBrush" Value="$CLR_GRID_LINE"/>
            <Setter Property="VerticalGridLinesBrush" Value="$CLR_GRID_LINE"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="$CLR_BORDER"/>
            <Setter Property="HeadersVisibility" Value="Column"/>
            <Setter Property="MinRowHeight" Value="24"/>
            <Setter Property="CanUserAddRows" Value="False"/>
        </Style>
        <Style TargetType="DataGridCell">
            <!-- WPF標準の「選択時に背景色を強制上書き（透過）する」挙動を根絶するため、Templateごと差し替える -->
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="DataGridCell">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                SnapsToDevicePixels="True">
                            <ContentPresenter SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}" VerticalAlignment="Center" HorizontalAlignment="Stretch"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="BorderBrush" Value="$CLR_SELECTED_BORDER"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="FontFamily" Value="$FONT_MAIN"/>
            <Setter Property="Background" Value="#EAEAEA"/>
            <Setter Property="Foreground" Value="#333333"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
            <Setter Property="BorderBrush" Value="$CLR_BORDER"/>
            <Setter Property="HorizontalContentAlignment" Value="Center"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Background" Value="#EAEAEA"/>
            <Setter Property="Foreground" Value="#555555"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="$CLR_BORDER"/>
            <Setter Property="Margin" Value="0,0,0,0"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#FFFFFF"/>
                    <Setter Property="Foreground" Value="#1A73E8"/>
                    <Setter Property="BorderBrush" Value="$CLR_BORDER"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- Status Badges -->
        <Style x:Key="BadgeStatus" TargetType="Border">
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="TextBlock.FontWeight" Value="SemiBold"/>
            <Setter Property="TextBlock.FontSize" Value="10.5"/>
            <Style.Triggers>
                <DataTrigger Binding="{Binding ステータス}" Value="未着手"><Setter Property="Background" Value="$CLR_STA_UNSTARTED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_UNSTARTED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="完了"><Setter Property="Background" Value="$CLR_STA_COMPLETED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_COMPLETED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="廃棄"><Setter Property="Background" Value="$CLR_STA_DISCARDED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_DISCARDED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="表示"><Setter Property="Background" Value="$CLR_STA_DISPLAY_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_DISPLAY_FG"/></DataTrigger>
            </Style.Triggers>
        </Style>
        <!-- Type Badges -->
        <Style x:Key="BadgeType" TargetType="Border">
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="TextBlock.FontWeight" Value="SemiBold"/>
            <Setter Property="TextBlock.FontSize" Value="10.5"/>
            <Style.Triggers>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="絶対期限"><Setter Property="Background" Value="$CLR_TYP_ABSOLUTE_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_ABSOLUTE_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="推奨期限"><Setter Property="Background" Value="$CLR_TYP_RECOMMEND_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_RECOMMEND_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="予定日"><Setter Property="Background" Value="$CLR_TYP_PLAN_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_PLAN_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="目安期限"><Setter Property="Background" Value="$CLR_TYP_GUIDE_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_GUIDE_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="参照用"><Setter Property="Background" Value="$CLR_TYP_REF_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_REF_FG"/></DataTrigger>
            </Style.Triggers>
        </Style>
        <!-- Category Badges -->
        <Style x:Key="BadgeCategory" TargetType="Border">
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="TextBlock.FontWeight" Value="SemiBold"/>
            <Setter Property="TextBlock.FontSize" Value="10.5"/>
            <Style.Triggers>
                <DataTrigger Binding="{Binding 分類}" Value="重要"><Setter Property="Background" Value="$CLR_CAT_IMPORTANT_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_IMPORTANT_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="雑務"><Setter Property="Background" Value="$CLR_CAT_CHORE_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_CHORE_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="支払い"><Setter Property="Background" Value="$CLR_CAT_PAY_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_PAY_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="業務"><Setter Property="Background" Value="$CLR_CAT_PAY_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_PAY_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="手続き"><Setter Property="Background" Value="$CLR_CAT_PROC_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_PROC_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="調査"><Setter Property="Background" Value="$CLR_CAT_RES_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_RES_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="スキルアップ"><Setter Property="Background" Value="$CLR_CAT_SKILL_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_SKILL_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="会社対応"><Setter Property="Background" Value="$CLR_CAT_CORP_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_CORP_FG"/></DataTrigger>
            </Style.Triggers>
        </Style>

        <DataTemplate x:Key="BadgeStatusTemplate">
            <Border Style="{StaticResource BadgeStatus}"><TextBlock Text="{Binding ステータス}" HorizontalAlignment="Center"/></Border>
        </DataTemplate>
        <DataTemplate x:Key="BadgeCategoryTemplate">
            <Border Style="{StaticResource BadgeCategory}"><TextBlock Text="{Binding 分類}" HorizontalAlignment="Center"/></Border>
        </DataTemplate>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <Border Background="#FFFFFF" Padding="10,6" BorderThickness="0,0,0,1" BorderBrush="$CLR_BORDER">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Button Name="BtnAddAppt" Content="予定追加" Padding="12,4" Background="#34A853" Foreground="White" BorderThickness="0" Margin="0,0,10,0" FontWeight="SemiBold" Cursor="Hand"/>
                <Button Name="BtnSync" Content="Outlook同期" Padding="12,4" Background="#1A73E8" Foreground="White" BorderThickness="0" Margin="0,0,10,0" FontWeight="SemiBold" Cursor="Hand"/>
                <Button Name="BtnComplete" Content="完了" Padding="12,4" Background="#1f8d61" Foreground="White" BorderThickness="0" Margin="0,0,10,0" FontWeight="SemiBold" Cursor="Hand"/>
                <TextBlock Text="ガント開始日:" VerticalAlignment="Center" Margin="0,0,6,0" Foreground="#333333"/>
                <DatePicker Name="GanttDatePicker" Width="120" VerticalAlignment="Center" VerticalContentAlignment="Center" Margin="0,0,5,0"/>
                <TextBlock Text="表示日数:" VerticalAlignment="Center" Margin="0,0,6,0" Foreground="#333333"/>
                <ComboBox Name="GanttDaysCombo" Width="40" VerticalAlignment="Center" SelectedIndex="1">
                    <ComboBoxItem Content="14"/>
                    <ComboBoxItem Content="35"/>
                    <ComboBoxItem Content="60"/>
                    <ComboBoxItem Content="90"/>
                    <ComboBoxItem Content="120"/>
                </ComboBox>
                <Button Name="BtnResetView" Content="表示リセット" Width="90" Height="24" Margin="10,0,0,0" Background="#F5F5F5" BorderBrush="$CLR_BORDER" Cursor="Hand"/>
                <CheckBox Name="ChkLogMode" Content="作業ログ入力モード" IsChecked="True" VerticalAlignment="Center" Margin="10,0,0,0" Foreground="#333333"/>
                <CheckBox Name="ChkSuppressWeekendHighlight" Content="土日強調を抑制" IsChecked="False" VerticalAlignment="Center" Margin="10,0,0,0" Foreground="#333333"/>
                <Button Name="BtnHelp" Content="？" Width="22" Height="22" Margin="10,0,0,0" Background="#F0F0F0" Foreground="#555555" BorderBrush="$CLR_BORDER" Cursor="Hand" ToolTip="留意事項を表示します"/>
            </StackPanel>
        </Border>
        
        <TabControl Name="MainTab" Grid.Row="1" Background="Transparent" BorderThickness="1" BorderBrush="$CLR_BORDER" Margin="6" Padding="0">
            <TabItem Header="🔍 カレンダー同期">
                <DataGrid Name="GridSync" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" SelectionUnit="Cell" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled" ScrollViewer.CanContentScroll="False">
                    <DataGrid.RowStyle>
                        <Style TargetType="DataGridRow">
                            <Setter Property="Background" Value="#FFFFFF"/>
                            <Style.Triggers>
                                <DataTrigger Binding="{Binding ステータス}" Value="完了">
                                    <Setter Property="Background" Value="$CLR_ROW_COMPLETED"/>
                                </DataTrigger>
                                <DataTrigger Binding="{Binding ステータス}" Value="廃棄">
                                    <Setter Property="Background" Value="$CLR_ROW_DISCARDED"/>
                                </DataTrigger>
                            </Style.Triggers>
                        </Style>
                    </DataGrid.RowStyle>
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="UID" Binding="{Binding uid}" Visibility="Collapsed"/>
                        <DataGridTemplateColumn Header="スケジュール名" SortMemberPath="タイトル" Width="$COL_WIDTH_TITLE">
                            <DataGridTemplateColumn.HeaderStyle>
                                <Style TargetType="DataGridColumnHeader" BasedOn="{StaticResource {x:Type DataGridColumnHeader}}"><Setter Property="Background" Value="$CLR_TITLE_CELL_BG"/></Style>
                            </DataGridTemplateColumn.HeaderStyle>
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <TextBox Text="{Binding タイトル, Mode=OneWay}" IsReadOnly="True" BorderThickness="0" Background="Transparent" VerticalAlignment="Center" Margin="6,0" TextWrapping="NoWrap"/>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTemplateColumn Header="ステータス" Width="$COL_WIDTH_STATUS">
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <Border Style="{StaticResource BadgeStatus}"><TextBlock Text="{Binding ステータス}" HorizontalAlignment="Center"/></Border>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTemplateColumn Header="期限タイプ" Width="$COL_WIDTH_TYPE">
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <Border Style="{StaticResource BadgeType}"><TextBlock Text="{Binding 期限タイプ}" HorizontalAlignment="Center"/></Border>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTemplateColumn Header="分類" Width="$COL_WIDTH_CAT">
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <Border Style="{StaticResource BadgeCategory}"><TextBlock Text="{Binding 分類}" HorizontalAlignment="Center"/></Border>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTextColumn Header="開始日" Binding="{Binding 開始日}" Width="$COL_WIDTH_DATE">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="終了日" Binding="{Binding 終了日}" Width="$COL_WIDTH_DATE">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="開始" Binding="{Binding 開始時間}" Width="$COL_WIDTH_TIME">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Margin" Value="6,0"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                            <DataGridTextColumn.CellStyle>
                                <Style TargetType="DataGridCell" BasedOn="{StaticResource {x:Type DataGridCell}}">
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding 開始時間}" Value="">
                                            <Setter Property="Background" Value="$CLR_EMPTY_CELL_BG"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding 開始時間}" Value="{x:Null}">
                                            <Setter Property="Background" Value="$CLR_EMPTY_CELL_BG"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding ステータス}" Value="完了">
                                            <Setter Property="Background" Value="$CLR_ROW_COMPLETED"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding ステータス}" Value="廃棄">
                                            <Setter Property="Background" Value="$CLR_ROW_DISCARDED"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </DataGridTextColumn.CellStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="終了" Binding="{Binding 終了時間}" Width="$COL_WIDTH_TIME">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Margin" Value="6,0"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                            <DataGridTextColumn.CellStyle>
                                <Style TargetType="DataGridCell" BasedOn="{StaticResource {x:Type DataGridCell}}">
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding 終了時間}" Value="">
                                            <Setter Property="Background" Value="$CLR_EMPTY_CELL_BG"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding 終了時間}" Value="{x:Null}">
                                            <Setter Property="Background" Value="$CLR_EMPTY_CELL_BG"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding ステータス}" Value="完了">
                                            <Setter Property="Background" Value="$CLR_ROW_COMPLETED"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding ステータス}" Value="廃棄">
                                            <Setter Property="Background" Value="$CLR_ROW_DISCARDED"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </DataGridTextColumn.CellStyle>
                        </DataGridTextColumn>
                        <DataGridTemplateColumn Header="メモ" SortMemberPath="メモ" Width="*">
                            <DataGridTemplateColumn.HeaderStyle>
                                <Style TargetType="DataGridColumnHeader" BasedOn="{StaticResource {x:Type DataGridColumnHeader}}">
                                    <Setter Property="HorizontalContentAlignment" Value="Left"/>
                                    <Setter Property="Padding" Value="10,4,6,4"/>
                                </Style>
                            </DataGridTemplateColumn.HeaderStyle>
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <TextBox Text="{Binding メモ, Mode=OneWay}" IsReadOnly="True" BorderThickness="0" Background="Transparent" VerticalAlignment="Center" Margin="6,0" TextWrapping="Wrap"/>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
            <TabItem Header="📝 作業ログ">
                <DataGrid Name="GridLogs" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" SelectionUnit="Cell" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="対象スケジュール名" Binding="{Binding title}" Width="$COL_WIDTH_TITLE">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/><Setter Property="TextWrapping" Value="NoWrap"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="作業内容" Binding="{Binding content}" Width="*">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="Margin" Value="6,0"/><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="TextWrapping" Value="Wrap"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="作業日" Binding="{Binding date}" Width="$COL_WIDTH_DATE">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="作業時間" Binding="{Binding displayTime}" Width="$COL_WIDTH_LOG_TIME">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
            <TabItem Header="📊 ガントチャート">
                <DataGrid Name="GridGantt" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" SelectionUnit="Cell" EnableRowVirtualization="True" EnableColumnVirtualization="True" BorderThickness="0" GridLinesVisibility="All" Background="Transparent" AlternationCount="0">
                    <DataGrid.FrozenColumnCount>3</DataGrid.FrozenColumnCount>
                    <DataGrid.RowStyle>
                        <Style TargetType="DataGridRow">
                            <Setter Property="Background" Value="#FFFFFF"/>
                        </Style>
                    </DataGrid.RowStyle>
                    <DataGrid.Columns>
                        <!-- Columns will be injected here -->
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
        </TabControl>
        
        <StatusBar Grid.Row="2" Background="#F0F0F0" BorderThickness="0,1,0,0" BorderBrush="$CLR_BORDER" Padding="4,2">
            <StatusBarItem>
                <TextBlock Name="StatusMsg" Text="準備完了" Foreground="#555555" FontWeight="SemiBold"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

function New-MainWindow {
    param([xml]$Xaml)

    $reader = (New-Object System.Xml.XmlNodeReader $Xaml)
    [System.Windows.Markup.XamlReader]::Load($reader)
}

function Initialize-MainWindowControls {
    param($Window)

    $script:BtnAddAppt = $Window.FindName("BtnAddAppt")
    $script:BtnSync = $Window.FindName("BtnSync")
    $script:BtnComplete = $Window.FindName("BtnComplete")
    $script:GanttDatePicker = $Window.FindName("GanttDatePicker")
    $script:GanttDaysCombo = $Window.FindName("GanttDaysCombo")
    $script:BtnResetView = $Window.FindName("BtnResetView")
    $script:ChkLogMode = $Window.FindName("ChkLogMode")
    $script:ChkSuppressWeekendHighlight = $Window.FindName("ChkSuppressWeekendHighlight")
    $script:BtnHelp = $Window.FindName("BtnHelp")
    $script:GridSync = $Window.FindName("GridSync")
    $script:GridGantt = $Window.FindName("GridGantt")
    $script:GridLogs = $Window.FindName("GridLogs")
    $script:StatusMsg = $Window.FindName("StatusMsg")
}

$Form = New-MainWindow -Xaml $xaml
Initialize-MainWindowControls -Window $Form

$GanttDatePicker.SelectedDate = (Get-Date).AddDays(-7)
$BtnAddAppt.Add_Click({ Invoke-AddAppointmentForm })

