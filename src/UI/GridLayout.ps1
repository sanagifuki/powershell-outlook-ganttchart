function Reset-SyncGridLayout {
    param($Grid)

    $Grid.Columns | ForEach-Object { $_.Width = [System.Windows.Controls.DataGridLength]::Auto }
    if ($Grid.Columns.Count -gt 1) { $Grid.Columns[1].Width = $COL_WIDTH_TITLE }
    if ($Grid.Columns.Count -gt 2) { $Grid.Columns[2].Width = $COL_WIDTH_STATUS }
    if ($Grid.Columns.Count -gt 3) { $Grid.Columns[3].Width = $COL_WIDTH_TYPE }
    if ($Grid.Columns.Count -gt 4) { $Grid.Columns[4].Width = $COL_WIDTH_CAT }
    if ($Grid.Columns.Count -gt 5) { $Grid.Columns[5].Width = $COL_WIDTH_DATE }
    if ($Grid.Columns.Count -gt 6) { $Grid.Columns[6].Width = $COL_WIDTH_DATE }
    if ($Grid.Columns.Count -gt 7) { $Grid.Columns[7].Width = $COL_WIDTH_TIME }
    if ($Grid.Columns.Count -gt 8) { $Grid.Columns[8].Width = $COL_WIDTH_TIME }
    if ($Grid.Columns.Count -gt 9) { $Grid.Columns[9].Width = [System.Windows.Controls.DataGridLength]::new(1, [System.Windows.Controls.DataGridLengthUnitType]::Star) }

    for ($i = 0; $i -lt $Grid.Columns.Count; $i++) {
        $Grid.Columns[$i].DisplayIndex = $i
    }
}

function Reset-LogsGridLayout {
    param($Grid)

    if ($Grid.Columns.Count -gt 0) { $Grid.Columns[0].Width = $COL_WIDTH_TITLE }
    if ($Grid.Columns.Count -gt 1) { $Grid.Columns[1].Width = [System.Windows.Controls.DataGridLength]::new(1, [System.Windows.Controls.DataGridLengthUnitType]::Star) }

    for ($i = 0; $i -lt $Grid.Columns.Count; $i++) {
        $Grid.Columns[$i].DisplayIndex = $i
    }
}

function Reset-AllGridLayouts {
    Reset-SyncGridLayout -Grid $GridSync
    Reset-LogsGridLayout -Grid $GridLogs
    Build-GanttColumns
    Refresh-UI
}
