function New-LogWindow {
    param($Task)

    [xml]$dXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="ログ入力: $($Task.タイトル -replace '&','&amp;')" Height="320" Width="350"
            Background="#F5F5F5" Foreground="#333333" FontFamily="$FONT_MAIN" FontSize="$FONT_SIZE_DIALOG"
            WindowStartupLocation="CenterOwner" ResizeMode="CanResize" MinWidth="320" MinHeight="300">
        <Grid Margin="12,8,12,12">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="作業日" Margin="0,0,0,2" FontWeight="SemiBold"/>
            <DatePicker Name="dpDate" Grid.Row="1" Height="26" Margin="0,0,0,8"/>
            
            <TextBlock Text="作業時間 (分)" Grid.Row="2" Margin="0,0,0,2" FontWeight="SemiBold"/>
            <TextBox Name="txtTime" Grid.Row="3" Height="26" Margin="0,0,0,8" Padding="4" Text="15"/>
            
            <TextBlock Text="作業内容" Grid.Row="4" Margin="0,0,0,2" FontWeight="SemiBold"/>
            <TextBox Name="txtContent" Grid.Row="5" MinHeight="60" TextWrapping="Wrap" AcceptsReturn="True"
                     Background="#FFFFFF" Foreground="#333333" BorderThickness="1" BorderBrush="#CCCCCC" Padding="4"/>
                     
            <Button Name="btnSave" Grid.Row="6" Content="保存" Height="30" Width="100" HorizontalAlignment="Right" Background="#1A73E8" Foreground="White" 
                    BorderThickness="0" Margin="0,10,0,0" FontWeight="SemiBold" Cursor="Hand"/>
        </Grid>
    </Window>
"@
    $dReader = (New-Object System.Xml.XmlNodeReader $dXaml)
    [System.Windows.Markup.XamlReader]::Load($dReader)
}

function Initialize-LogFormFields {
    param(
        $DatePicker,
        $TimeTextBox,
        $ContentTextBox,
        $DefaultDate,
        $EditLog
    )

    if ($EditLog) {
        $DatePicker.Text = $EditLog.date
        if ($EditLog.time) { $TimeTextBox.Text = ($EditLog.time -replace '分$', '') }
        $ContentTextBox.Text = $EditLog.content
    }
    elseif ($DefaultDate) {
        $DatePicker.Text = $DefaultDate
    }
    else {
        $DatePicker.Text = (Get-Date).ToString("yyyy/MM/dd")
    }
}

function Invoke-LogForm {
    param($task, $defaultDate, $editLog)
    
    $d = New-LogWindow -Task $task
    $d.Owner = $Form

    $dpDate = $d.FindName("dpDate")
    $txtTime = $d.FindName("txtTime")
    $txtContent = $d.FindName("txtContent")
    $btnSave = $d.FindName("btnSave")
    
    Initialize-LogFormFields -DatePicker $dpDate -TimeTextBox $txtTime -ContentTextBox $txtContent -DefaultDate $defaultDate -EditLog $editLog
    
    $btnSave.Add_Click({
            [array]$logs = Read-JsonArray -Path $LogsFile
            $saveDate = if ($dpDate.SelectedDate) { $dpDate.SelectedDate.ToString("yyyy/MM/dd") } else { $dpDate.Text }
        
            $newLog = New-WorkLog -Uid $task.uid -Date $saveDate -Content $txtContent.Text -Time $txtTime.Text
            $logs = Upsert-WorkLog -Logs $logs -NewLog $newLog -EditLog $editLog
            Write-JsonData -Path $LogsFile -Data $logs
        
            $d.DialogResult = $true
            $d.Close()
        })
    
    if ($d.ShowDialog() -eq $true) {
        Refresh-UI
        Show-Toast "保存しました"
    }
}

