# --- Events ---
$BtnSync.Add_Click({
        Invoke-OutlookSync
    })

$GanttDatePicker.Add_SelectedDateChanged({ Refresh-UI })
$GanttDaysCombo.Add_DropDownClosed({ Refresh-UI })
$ChkSuppressWeekendHighlight.Add_Checked({ Refresh-UI })
$ChkSuppressWeekendHighlight.Add_Unchecked({ Refresh-UI })
$ChkHideHold.Add_Checked({ Refresh-UI })
$ChkHideHold.Add_Unchecked({ Refresh-UI })
$ChkHideDiscarded.Add_Checked({ Refresh-UI })
$ChkHideDiscarded.Add_Unchecked({ Refresh-UI })
$ChkHideCompleted.Add_Checked({ Refresh-UI })
$ChkHideCompleted.Add_Unchecked({ Refresh-UI })
$ChkTopmost.Add_Checked({ $Form.Topmost = $true })
$ChkTopmost.Add_Unchecked({ $Form.Topmost = $false })

foreach ($item in $CompletedCountItems) {
    $item.Add_Click({ Set-ClosedScheduleDisplayCount -Status "完了" -Count ([int]$this.Tag) })
}
foreach ($item in $DiscardedCountItems) {
    $item.Add_Click({ Set-ClosedScheduleDisplayCount -Status "廃棄" -Count ([int]$this.Tag) })
}
Update-ClosedScheduleCountChecks

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

$GridSync.Add_PreviewMouseRightButtonDown({
    param($sender, $eventArgs)
    [void](Select-DataGridRowUnderMouse -Grid $GridSync -OriginalSource $eventArgs.OriginalSource)
})
Initialize-ScheduleContextMenu

$Form.Add_Closing({
        Save-WindowPlacement -Window $Form -Settings $AppSettings
    })

# INITIAL LOAD
Refresh-UI
$Form.Add_ContentRendered({
    Initialize-AllTabLayouts
})
$Form.ShowDialog()

