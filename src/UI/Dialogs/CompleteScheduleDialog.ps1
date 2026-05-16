function Invoke-CompleteSchedulePicker {
    param([array]$Tasks)

    $items = Get-IncompleteSchedules -Schedules $Tasks
    if ($items.Count -eq 0) {
        Show-Toast "完了にできる未完了スケジュールがありません"
        return $null
    }

    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="スケジュール完了" Height="190" Width="520"
            Background="#F5F5F5" Foreground="#333333" FontFamily="Noto Sans JP" FontSize="12"
            WindowStartupLocation="CenterOwner" ResizeMode="NoResize">
        <Grid Margin="14">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="完了にするスケジュール" FontWeight="SemiBold" Margin="0,0,0,6"/>
            <ComboBox Name="ComboSchedule" Grid.Row="1" Height="28" DisplayMemberPath="DisplayText"/>
            <TextBlock Name="TxtMemo" Grid.Row="2" TextWrapping="Wrap" Foreground="#666666" Margin="0,8,0,0"/>
            <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
                <Button Name="BtnCancel" Content="キャンセル" Width="90" Height="28" Margin="0,0,8,0"/>
                <Button Name="BtnOk" Content="完了にする" Width="100" Height="28" Background="#1f8d61" Foreground="White" BorderThickness="0"/>
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
