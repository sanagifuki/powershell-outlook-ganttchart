# --- Events ---
$BtnSync.Add_Click({
        $BtnSync.IsEnabled = $false
        $BtnSync.Content = "同期中..."
        try {
            $syncData = Get-OutlookScheduleSyncData -TargetEmail $TARGET_OUTLOOK_EMAIL
            Write-JsonData -Path $TasksFile -Data $syncData.Tasks
            Refresh-UI
        
            Show-Toast "同期完了 ($($syncData.Count) 件) - アカウント: $($syncData.Account)"
        }
        catch {
            $msg = $_.Exception.Message
            "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - 同期エラー: $msg" | Out-File (Join-Path $ScriptPath "error.log") -Append -Encoding UTF8
            Show-Toast "同期失敗: $msg"
        }
        finally {
            $BtnSync.IsEnabled = $true
            $BtnSync.Content = "Outlook同期"
        }
    })

$GanttDatePicker.Add_SelectedDateChanged({ Refresh-UI })
$GanttDaysCombo.Add_DropDownClosed({ Refresh-UI })
$ChkSuppressWeekendHighlight.Add_Checked({ Refresh-UI })
$ChkSuppressWeekendHighlight.Add_Unchecked({ Refresh-UI })

$BtnComplete.Add_Click({
        try {
            Complete-SelectedSchedule
        }
        catch {
            Show-Toast "完了処理に失敗: $($_.Exception.Message)"
        }
    })

$BtnHelp.Add_Click({
        Invoke-ViewForm -title "留意事項・ヘルプ" -text (Get-HelpText)
    })

$BtnResetView.Add_Click({
        Reset-AllGridLayouts
        Show-Toast "表示をリセットしました"
    })

$GridSync.Add_MouseDoubleClick({
        Handle-SyncGridDoubleClick
    })
$GridGantt.Add_MouseDoubleClick({
        Handle-GanttGridDoubleClick
    })
$GridLogs.Add_MouseDoubleClick({
        Handle-LogsGridDoubleClick
    })

# INITIAL LOAD
Refresh-UI
$Form.ShowDialog()

