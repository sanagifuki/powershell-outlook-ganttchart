function Show-Toast($msg) {
    if ($StatusMsg) {
        $StatusMsg.Text = $msg
        
        # UIを強制更新（DoEvents）
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [Action]( { $frame.Continue = $false } )
        ) | Out-Null
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    }
}


