# --- Events ---
$BtnSync.Add_Click({
        Invoke-OutlookSync
    })

$GanttDatePicker.Add_SelectedDateChanged({ Refresh-UI })
$GanttDaysCombo.Add_DropDownClosed({ Refresh-UI })
$ChkSuppressWeekendHighlight.Add_Checked({ Refresh-UI })
$ChkSuppressWeekendHighlight.Add_Unchecked({ Refresh-UI })
$ChkTopmost.Add_Checked({ $Form.Topmost = $true })
$ChkTopmost.Add_Unchecked({ $Form.Topmost = $false })

$BtnComplete.Add_Click({
        try {
            Change-SelectedScheduleStatus
        }
        catch {
            Show-Toast "ステータス切替に失敗: $($_.Exception.Message)"
        }
    })

$BtnEditAppt.Add_Click({
        try {
            Edit-SelectedSchedule
        }
        catch {
            Show-Toast "編集処理に失敗: $($_.Exception.Message)"
        }
    })

$BtnHelp.Add_Click({
        Invoke-ViewForm -title "留意事項・ヘルプ" -text (Get-HelpText)
    })

$BtnResetView.Add_Click({
        Reset-AllGridLayouts
        Show-Toast "表示をリセットしました"
    })

$GridGantt.Add_MouseDoubleClick({
        Handle-GanttGridDoubleClick
    })
$GridLogs.Add_MouseDoubleClick({
        Handle-LogsGridDoubleClick
    })

$Form.Add_Closing({
        Save-WindowPlacement -Window $Form -Settings $AppSettings
    })

# INITIAL LOAD
Refresh-UI
$Form.ShowDialog()

