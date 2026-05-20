function Invoke-StatusSchedulePicker {
    param([array]$Tasks)

    $items = Get-CompletionToggleSchedules -Schedules $Tasks
    if ($items.Count -eq 0) {
        Show-Toast "ステータスを変更できるスケジュールがありません"
        return $null
    }

    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="ステータス切替" Height="220" Width="520"
            Background="#F5F5F5" Foreground="#333333" FontFamily="$FONT_MAIN" FontSize="$FONT_SIZE_DIALOG"
            TextOptions.TextRenderingMode="ClearType" WindowStartupLocation="CenterOwner" ResizeMode="NoResize">
        <Grid Margin="14">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="ステータスを変更するスケジュール" FontWeight="SemiBold" Margin="0,0,0,6"/>
            <ComboBox Name="ComboSchedule" Grid.Row="1" Height="28" DisplayMemberPath="DisplayText"/>
            <StackPanel Grid.Row="2" Margin="0,8,0,0">
                <TextBlock Text="変更後ステータス" Foreground="#666666" Margin="0,0,0,2"/>
                <ComboBox Name="ComboStatus" Height="28">
                    <ComboBoxItem Content="未着手"/>
                    <ComboBoxItem Content="完了"/>
                    <ComboBoxItem Content="保留"/>
                    <ComboBoxItem Content="廃棄"/>
                </ComboBox>
            </StackPanel>
            <TextBlock Name="TxtMemo" Grid.Row="3" TextWrapping="Wrap" Foreground="#666666" Margin="0,8,0,0"/>
            <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
                <Button Name="BtnCancel" Content="キャンセル" Width="90" Height="28" Margin="0,0,8,0"/>
                <Button Name="BtnOk" Content="変更する" Width="100" Height="28" Background="#1A73E8" Foreground="White" BorderThickness="0"/>
            </StackPanel>
        </Grid>
    </Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    $window.Owner = $Form

    $combo = $window.FindName("ComboSchedule")
    $comboStatus = $window.FindName("ComboStatus")
    $memo = $window.FindName("TxtMemo")
    $btnOk = $window.FindName("BtnOk")
    $btnCancel = $window.FindName("BtnCancel")

    $comboItems = @($items | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name DisplayText -Value "$($_.開始日) [$($_.ステータス)] $($_.タイトル)" -Force
            $_
        })
    $combo.ItemsSource = $comboItems
    $combo.SelectedIndex = 0

    $selectStatus = {
        if ($combo.SelectedItem) {
            $status = [string]$combo.SelectedItem.ステータス
            if ($status -eq "表示") { $status = "未着手" }
            for ($i = 0; $i -lt $comboStatus.Items.Count; $i++) {
                if ([string]$comboStatus.Items[$i].Content -eq $status) {
                    $comboStatus.SelectedIndex = $i
                    break
                }
            }
        }
    }
    $updatePreview = {
        if ($combo.SelectedItem -and $comboStatus.SelectedItem) {
            $memo.Text = "現在: $($combo.SelectedItem.ステータス) / 変更後: $($comboStatus.SelectedItem.Content)"
        }
    }

    $combo.Add_SelectionChanged({
            & $selectStatus
            & $updatePreview
        })
    $comboStatus.Add_SelectionChanged({ & $updatePreview })
    & $selectStatus
    & $updatePreview

    $btnCancel.Add_Click({
            $window.DialogResult = $false
            $window.Close()
        })
    $btnOk.Add_Click({
            if (-not $combo.SelectedItem) {
                Show-Toast "スケジュールを選択してください"
                return
            }
            $window.DialogResult = $true
            $window.Close()
        })

    if ($window.ShowDialog() -eq $true) {
        return [PSCustomObject]@{
            Task = $combo.SelectedItem
            Status = [string]$comboStatus.SelectedItem.Content
        }
    }

    return $null
}

function Invoke-CompleteSchedulePicker {
    param([array]$Tasks)

    $result = Invoke-StatusSchedulePicker -Tasks $Tasks
    if (-not $result) { return $null }

    return $result.Task
}

function Invoke-ScheduleEditPicker {
    param([array]$Tasks)

    $items = @($Tasks)
    if ($items.Count -eq 0) {
        Show-Toast "編集できるスケジュールがありません"
        return $null
    }

    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="スケジュール編集" Height="190" Width="520"
            Background="#F5F5F5" Foreground="#333333" FontFamily="$FONT_MAIN" FontSize="$FONT_SIZE_DIALOG"
            TextOptions.TextRenderingMode="ClearType" WindowStartupLocation="CenterOwner" ResizeMode="NoResize">
        <Grid Margin="14">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="編集するスケジュール" FontWeight="SemiBold" Margin="0,0,0,6"/>
            <ComboBox Name="ComboSchedule" Grid.Row="1" Height="28" DisplayMemberPath="DisplayText"/>
            <TextBlock Name="TxtMemo" Grid.Row="2" TextWrapping="Wrap" Foreground="#666666" Margin="0,8,0,0"/>
            <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
                <Button Name="BtnCancel" Content="キャンセル" Width="90" Height="28" Margin="0,0,8,0"/>
                <Button Name="BtnOk" Content="編集する" Width="100" Height="28" Background="#1A73E8" Foreground="White" BorderThickness="0"/>
            </StackPanel>
        </Grid>
    </Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    $window.Owner = $Form

    $combo = $window.FindName("ComboSchedule")
    $memo = $window.FindName("TxtMemo")
    $btnOk = $window.FindName("BtnOk")
    $btnCancel = $window.FindName("BtnCancel")

    $comboItems = @($items | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name DisplayText -Value "$($_.開始日) $($_.タイトル)" -Force
            $_
        })
    $combo.ItemsSource = $comboItems
    $combo.SelectedIndex = 0

    $combo.Add_SelectionChanged({
            if ($combo.SelectedItem) {
                $memo.Text = "分類: $($combo.SelectedItem.分類) / 期限タイプ: $($combo.SelectedItem.期限タイプ)"
            }
        })
    if ($combo.SelectedItem) {
        $memo.Text = "分類: $($combo.SelectedItem.分類) / 期限タイプ: $($combo.SelectedItem.期限タイプ)"
    }

    $btnCancel.Add_Click({
            $window.DialogResult = $false
            $window.Close()
        })
    $btnOk.Add_Click({
            if (-not $combo.SelectedItem) {
                Show-Toast "スケジュールを選択してください"
                return
            }
            $window.DialogResult = $true
            $window.Close()
        })

    if ($window.ShowDialog() -eq $true) {
        return $combo.SelectedItem
    }

    return $null
}
