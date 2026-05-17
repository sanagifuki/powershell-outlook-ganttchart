# --- Events ---
$BtnSync.Add_Click({
        Invoke-OutlookSync
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

$Form.Add_Closing({
        Save-WindowPlacement -Window $Form -Settings $AppSettings
    })

# INITIAL LOAD
Refresh-UI
$Form.ShowDialog()

