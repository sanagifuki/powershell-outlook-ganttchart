function Invoke-ViewForm {
    param($title, $text)
    [xml]$vXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="詳細" Height="500" Width="650"
            WindowStartupLocation="CenterOwner" Background="#F0F0F0" FontFamily="Noto Sans JP" FontSize="12"
            ResizeMode="CanResizeWithGrip">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="16">
            <TextBlock Name="txtView" TextWrapping="Wrap" Foreground="#333333" LineHeight="20"/>
        </ScrollViewer>
    </Window>
"@
    $vReader = (New-Object System.Xml.XmlNodeReader $vXaml)
    $v = [System.Windows.Markup.XamlReader]::Load($vReader)
    $v.Owner = $Form
    $v.Title = $title
    $v.FindName("txtView").Text = $text
    [void]$v.ShowDialog()
}

