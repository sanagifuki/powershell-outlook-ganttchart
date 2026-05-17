function New-AddAppointmentWindow {
    [xml]$formXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Outlook予定追加" Width="420" SizeToContent="Height"
        TextOptions.TextRenderingMode="ClearType" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#666666"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Margin" Value="0,0,0,2"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Height" Value="28"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="DatePicker">
            <Setter Property="Height" Value="28"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="4,2"/>
            <Setter Property="BorderBrush" Value="#CCCCCC"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- 0: Type & Cat -->
            <RowDefinition Height="Auto"/> <!-- 1: Title -->
            <RowDefinition Height="Auto"/> <!-- 2: Dates -->
            <RowDefinition Height="Auto"/> <!-- 3: Times -->
            <RowDefinition Height="Auto"/> <!-- 4: Memo -->
            <RowDefinition Height="Auto"/> <!-- 5: Options -->
            <RowDefinition Height="Auto"/> <!-- 6: Buttons -->
        </Grid.RowDefinitions>

        <!-- 行0: 期限タイプ & 分類 -->
        <Grid Grid.Row="0" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="15"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="期限タイプ"/>
                <ComboBox Name="ComboType">
                    <ComboBoxItem Content="✕（絶対期限）" Tag="✕"/>
                    <ComboBoxItem Content="◆（推奨期限）" Tag="◆"/>
                    <ComboBoxItem Content="◇（目安期限）" Tag="◇"/>
                    <ComboBoxItem Content="▶（予定日）" Tag="▶"/>
                    <ComboBoxItem Content="★（参照用）" Tag="★"/>
                </ComboBox>
            </StackPanel>
            <StackPanel Grid.Column="2">
                <TextBlock Text="分類"/>
                <ComboBox Name="ComboCat">
                </ComboBox>
            </StackPanel>
        </Grid>

        <!-- 行1: タイトル -->
        <StackPanel Grid.Row="1" Margin="0,0,0,10">
            <TextBlock Text="タイトル"/>
            <TextBox Name="TxtTitle" Height="28"/>
        </StackPanel>

        <!-- 行2: 日付 -->
        <Grid Grid.Row="2" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="15"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="開始日"/>
                <DatePicker Name="DateStart"/>
            </StackPanel>
            <StackPanel Grid.Column="2" Name="ContainerEnd">
                <TextBlock Name="LabelEnd" Text="終了日"/>
                <DatePicker Name="DateEnd"/>
            </StackPanel>
        </Grid>

        <!-- 行3: 時間 (予定日の場合のみ) -->
        <Grid Name="PanelTime" Grid.Row="3" Margin="0,0,0,10" Visibility="Collapsed">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="15"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="開始時間"/>
                <TextBox Name="TimeStart" Height="28" Text="09:00" HorizontalContentAlignment="Center"/>
            </StackPanel>
            <StackPanel Grid.Column="2">
                <TextBlock Text="終了時間"/>
                <TextBox Name="TimeEnd" Height="28" Text="10:00" HorizontalContentAlignment="Center"/>
            </StackPanel>
        </Grid>

        <!-- 行4: メモ -->
        <StackPanel Grid.Row="4" VerticalAlignment="Stretch">
            <TextBlock Text="メモ"/>
            <TextBox Name="TxtMemo" MinHeight="80" MaxHeight="150" TextWrapping="Wrap" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" VerticalContentAlignment="Top" Padding="5" Background="#FFFFFF"/>
        </StackPanel>

        <!-- 行5: Outlook オプション -->
        <StackPanel Grid.Row="5" Orientation="Horizontal" Margin="0,10,0,0">
            <CheckBox Name="ChkPrivate" Content="非公開" VerticalAlignment="Center" Margin="0,0,14,0"/>
            <CheckBox Name="ChkShowAsFree" Content="空き時間として表示" VerticalAlignment="Center"/>
        </StackPanel>

        <!-- 行6: ボタン -->
        <StackPanel Grid.Row="6" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,15,0,0">
            <Button Name="BtnSave" Content="Outlookに保存" Width="130" Height="32" Background="#1A73E8" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand" Margin="0,0,10,0">
                <Button.Style>
                    <Style TargetType="Button">
                        <Style.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1557B0"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Button.Style>
            </Button>
            <Button Name="BtnCancel" Content="キャンセル" Width="90" Height="32" Background="#F5F5F5" BorderBrush="#DDDDDD" Cursor="Hand"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader $formXaml
    [Windows.Markup.XamlReader]::Load($reader)
}

function Update-AddAppointmentTypeUi {
    param(
        $ComboType,
        $PanelTime,
        $DateStart,
        $DateEnd
    )

    $selectedItem = $ComboType.SelectedItem
    $isTimed = ($null -ne $selectedItem -and $selectedItem.Tag -eq "▶")
    $isSingleDay = ($null -ne $selectedItem -and ($selectedItem.Tag -eq "▶" -or $selectedItem.Tag -eq "★"))

    if ($isTimed) {
        $PanelTime.Visibility = [System.Windows.Visibility]::Visible
    }
    else {
        $PanelTime.Visibility = [System.Windows.Visibility]::Collapsed
    }

    if ($isSingleDay) {
        $DateEnd.SelectedDate = $DateStart.SelectedDate
        $DateEnd.IsEnabled = $false
    }
    else {
        $DateEnd.IsEnabled = $true
    }
}

function Test-AddAppointmentInput {
    param(
        $TitleTextBox,
        $DateStart,
        [bool]$IsTimed,
        $TimeStart,
        $TimeEnd
    )

    if ([string]::IsNullOrWhiteSpace($TitleTextBox.Text)) {
        [System.Windows.MessageBox]::Show("タイトルを入力してください。", "エラー", "OK", "Error")
        return $false
    }
    if (-not $DateStart.SelectedDate) {
        [System.Windows.MessageBox]::Show("開始日を選択してください。", "エラー", "OK", "Error")
        return $false
    }
    if ($IsTimed) {
        if (-not (Test-TimeText -Text $TimeStart.Text)) {
            [System.Windows.MessageBox]::Show("開始時間の形式が正しくありません（例 09:00）", "形式エラー", "OK", "Warning")
            return $false
        }
        if (-not (Test-TimeText -Text $TimeEnd.Text)) {
            [System.Windows.MessageBox]::Show("終了時間の形式が正しくありません（例 10:00）", "形式エラー", "OK", "Warning")
            return $false
        }
    }

    return $true
}

# 予定追加フォームを表示する関数
function Invoke-AddAppointmentForm {
    $window = New-AddAppointmentWindow

    $comboType = $window.FindName("ComboType")
    $comboCat  = $window.FindName("ComboCat")
    $comboCat.ItemsSource = Get-CategoryNames
    $txtTitle  = $window.FindName("TxtTitle")
    $dateStart = $window.FindName("DateStart")
    $dateEnd   = $window.FindName("DateEnd")
    $panelTime = $window.FindName("PanelTime")
    $timeStart = $window.FindName("TimeStart")
    $timeEnd   = $window.FindName("TimeEnd")
    $txtMemo   = $window.FindName("TxtMemo")
    $chkPrivate = $window.FindName("ChkPrivate")
    $chkShowAsFree = $window.FindName("ChkShowAsFree")
    $btnSave   = $window.FindName("BtnSave")
    $btnCancel = $window.FindName("BtnCancel")

    $settings = Get-AppSettings
    Select-ComboBoxItemByTag -ComboBox $comboType -Tag $settings.addAppointmentTypeDefaultSymbol
    if ($comboType.SelectedIndex -lt 0) { Select-ComboBoxItemByTag -ComboBox $comboType -Tag "◆" }
    $comboCat.Text = [string]$settings.addAppointmentCategoryDefault
    if ([string]::IsNullOrWhiteSpace($comboCat.Text) -and $comboCat.Items.Count -gt 0) { $comboCat.SelectedIndex = 0 }
    $chkPrivate.IsChecked = [bool]$settings.addAppointmentPrivateDefault
    $chkShowAsFree.IsChecked = [bool]$settings.addAppointmentShowAsFreeDefault

    # 初期値設定
    $today = Get-Date
    $dateStart.SelectedDate = $today
    $dateEnd.SelectedDate   = $today

    $updateUIByType = {
        Update-AddAppointmentTypeUi -ComboType $comboType -PanelTime $panelTime -DateStart $dateStart -DateEnd $dateEnd
    }

    $comboType.Add_SelectionChanged({
        & $updateUIByType
    })

    # 単日扱い（予定日・参照用）の場合は終了日も同期
    $dateStart.Add_SelectedDateChanged({
        $selectedItem = $comboType.SelectedItem
        if ($null -ne $selectedItem -and ($selectedItem.Tag -eq "▶" -or $selectedItem.Tag -eq "★")) {
            $dateEnd.SelectedDate = $dateStart.SelectedDate
        }
    })

    # 初回実行
    $window.Add_Loaded({ & $updateUIByType })

    # 保存処理
    $btnSave.Add_Click({
        $selectedType = $comboType.SelectedItem
        if ($null -eq $selectedType) { return }
        $isTimed = ($selectedType.Tag -eq "▶")

        if (-not (Test-AddAppointmentInput -TitleTextBox $txtTitle -DateStart $dateStart -IsTimed $isTimed -TimeStart $timeStart -TimeEnd $timeEnd)) {
            return
        }

        try {
            $formattedTitle = Format-AppointmentTitle -Symbol $selectedType.Tag -Category $comboCat.Text -Title $txtTitle.Text

            $sDate = $dateStart.SelectedDate
            $eDate = $dateEnd.SelectedDate

            Add-OutlookAppointment -Subject $formattedTitle -Body $txtMemo.Text -StartDate $sDate -EndDate $eDate -IsTimed $isTimed -StartTime $timeStart.Text -EndTime $timeEnd.Text -IsPrivate $chkPrivate.IsChecked -ShowAsFree $chkShowAsFree.IsChecked
            Show-Toast "Outlookに予定を追加しました: $formattedTitle"
            $window.DialogResult = $true
            $window.Close()
        } catch {
            [System.Windows.MessageBox]::Show("保存に失敗しました。詳細:`n$($_.Exception.Message)", "エラー", "OK", "Error")
        }
    })

    $btnCancel.Add_Click({
            $window.DialogResult = $false
            $window.Close()
        })
    if ($window.ShowDialog() -eq $true) {
        Invoke-OutlookSync -SuccessPrefix "予定追加後の同期完了"
    }
}

