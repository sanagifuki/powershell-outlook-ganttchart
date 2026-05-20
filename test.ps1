param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'build.manifest.psd1')
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $ManifestPath

function Assert-Equal {
    param(
        $Actual,
        $Expected,
        [string]$Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message Expected=[$Expected] Actual=[$Actual]"
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$script:AppRoot = $repoRoot
. (Join-Path $repoRoot 'src/Config/AppConfig.ps1')
. (Join-Path $repoRoot 'src/Config/Theme.ps1')
. (Join-Path $repoRoot 'src/Infrastructure/JsonStore.ps1')
. (Join-Path $repoRoot 'src/Config/CategoryConfig.ps1')
. (Join-Path $repoRoot 'src/Config/SettingsConfig.ps1')
. (Join-Path $repoRoot 'src/Shared/TextUtils.ps1')
. (Join-Path $repoRoot 'src/Domain/ScheduleParser.ps1')
. (Join-Path $repoRoot 'src/Domain/AppointmentInput.ps1')
. (Join-Path $repoRoot 'src/Domain/ScheduleCompletion.ps1')
. (Join-Path $repoRoot 'src/Domain/WorkLogEditor.ps1')
. (Join-Path $repoRoot 'src/Domain/WorkLogPresenter.ps1')
. (Join-Path $repoRoot 'src/Domain/GanttColumnTheme.ps1')
. (Join-Path $repoRoot 'src/Domain/GanttCell.ps1')
. (Join-Path $repoRoot 'src/Domain/GanttTaskFilter.ps1')
. (Join-Path $repoRoot 'src/Domain/GanttTableBuilder.ps1')
. (Join-Path $repoRoot 'src/Infrastructure/OutlookClient.ps1')

$schedule = ConvertTo-ScheduleItem -Task ([PSCustomObject]@{
    uid = '1'
    title = '★［調査］確認する'
    start = '2026/05/16'
    end = '2026/05/16'
    startTime = ''
    endTime = ''
    memo = '<p>* test</p>'
    categories = ''
})
Assert-Equal $schedule.ステータス '表示' 'Schedule status parse failed.'
Assert-Equal $schedule.期限タイプ '参照用' 'Schedule type parse failed.'
Assert-Equal $schedule.分類 '調査' 'Schedule category parse failed.'
Assert-True (-not [string]::IsNullOrWhiteSpace($schedule.分類背景)) 'Schedule category background failed.'
Assert-True ((Get-CategoryNames).Count -gt 0) 'Default categories should be loaded.'
$settings = Get-DefaultAppSettings
Assert-Equal $settings.ganttDefaultDays 35 'Default gantt days setting failed.'
Assert-Equal $settings.addAppointmentTypeDefaultSymbol '◆' 'Default appointment type setting failed.'
Assert-Equal $settings.topmostDefault $false 'Default topmost setting failed.'
Assert-Equal @($settings.hiddenStatusesDefault).Count 0 'Default hidden status setting failed.'
Assert-Equal $settings.rememberWindowPlacement $true 'Default window placement setting failed.'
Assert-Equal $settings.windowWidth 769 'Default window width setting failed.'
Assert-Equal $settings.windowMinWidth 825 'Default window minimum width setting failed.'
Assert-Equal $settings.fontMain 'Noto Sans JP, Meiryo, Yu Gothic UI' 'Default main font setting failed.'
Assert-Equal $settings.fontGantt 'Yu Gothic' 'Default gantt font setting failed.'
Assert-Equal $settings.fontSizeMain 11 'Default main font size setting failed.'
Assert-Equal $settings.fontSizeDialog 11 'Default dialog font size setting failed.'
Assert-Equal $settings.fontSizeGantt 11 'Default gantt font size setting failed.'

Assert-Equal (Format-AppointmentTitle -Symbol '▶' -Category '業務' -Title '確認') '▶［業務］確認' 'Appointment title format failed.'
Assert-True (Test-TimeText -Text '09:00') 'Valid time should pass.'
Assert-True (-not (Test-TimeText -Text '9時')) 'Invalid time should fail.'

Assert-Equal (Add-CategoryText -Categories '' -Category '完了') '完了' 'Empty category completion failed.'
Assert-Equal (Add-CategoryText -Categories '業務' -Category '完了') '業務, 完了' 'Category append failed.'
Assert-Equal (ConvertTo-StatusCategories -Categories '業務, 完了' -Status '保留') '業務, 保留' 'Status category hold conversion failed.'
Assert-Equal (ConvertTo-StatusCategories -Categories '業務, 保留' -Status '未着手') '業務' 'Status category unstarted conversion failed.'
$completedSchedules = @(Set-CachedScheduleCompleted -Schedules @([PSCustomObject]@{
    uid = '1'
    categories = '業務'
}) -Uid '1')
Assert-True ($completedSchedules[0].categories -like '*完了*') 'Cached schedule completion failed.'
$incompleteSchedules = @(Get-IncompleteSchedules -Schedules @(
        [PSCustomObject]@{ ステータス = '完了'; 開始日 = '2026/05/16'; タイトル = 'done' },
        [PSCustomObject]@{ ステータス = '未着手'; 開始日 = '2026/05/15'; タイトル = 'todo' }
    ))
Assert-Equal $incompleteSchedules.Count 1 'Incomplete schedule filtering failed.'
Assert-Equal $incompleteSchedules[0].タイトル 'todo' 'Incomplete schedule item failed.'
$visibleStatusTasks = @(Select-GanttVisibleTasks -Tasks @(
        [PSCustomObject]@{ uid = '1'; ステータス = '保留'; 終了日 = '2026/05/15' },
        [PSCustomObject]@{ uid = '2'; ステータス = '廃棄'; 終了日 = '2026/05/15' },
        [PSCustomObject]@{ uid = '3'; ステータス = '未着手'; 終了日 = '2026/05/15' }
    ) -BaseDate ([datetime]'2026-05-16') -HiddenStatuses @('保留', '廃棄'))
Assert-Equal $visibleStatusTasks.Count 1 'Hidden status filtering failed.'
Assert-Equal $visibleStatusTasks[0].uid '3' 'Hidden status visible item failed.'
Assert-True (-not (Test-TaskStatusVisible -Task ([PSCustomObject]@{ ステータス = '保留' }) -HiddenStatuses @('保留'))) 'Hidden status predicate failed.'

$newLog = New-WorkLog -Uid '1' -Date '2026/05/16' -Content '作業' -Time '15'
Assert-Equal $newLog.uid '1' 'New work log uid failed.'
$updatedLogs = @(Upsert-WorkLog -Logs @() -NewLog $newLog -EditLog $null)
Assert-Equal $updatedLogs.Count 1 'Work log insert failed.'
$replacementLog = New-WorkLog -Uid '1' -Date '2026/05/16' -Content '更新' -Time '20'
$updatedLogs = @(Upsert-WorkLog -Logs $updatedLogs -NewLog $replacementLog -EditLog $newLog)
Assert-Equal $updatedLogs.Count 1 'Work log update should not append.'
Assert-Equal $updatedLogs[0].content '更新' 'Work log update content failed.'

$displayLogs = @(ConvertTo-DisplayWorkLogs -Logs @([PSCustomObject]@{
    uid = '1'
    date = '2026/05/16'
    time = '15'
    content = '作業'
}) -Tasks @([PSCustomObject]@{
    uid = '1'
    タイトル = '予定A'
}))
Assert-Equal $displayLogs[0].title '予定A' 'Work log title lookup failed.'
Assert-Equal $displayLogs[0].displayTime '15分' 'Work log time format failed.'

Assert-Equal (Get-GanttDateCellBackground -Date ([datetime]'2026-05-16') -TodayText '2026/05/16') $CLR_GANTT_TODAY_BG 'Today cell background failed.'
$weekendBg = Get-GanttDateCellBackground -Date ([datetime]'2026-05-17') -TodayText '2026/05/16'
Assert-Equal $weekendBg $CLR_GANTT_WE_ODD_BG 'Weekend column background failed.'
$headerTheme = Get-GanttDateHeaderTheme -Date ([datetime]'2026-05-20') -TodayText '2026/05/16'
Assert-Equal $headerTheme.Background $CLR_GANTT_HDR_ODD_BG 'Odd month header background failed.'

$task = [PSCustomObject]@{
    uid = '1'
    ステータス = '未着手'
    分類 = '調査'
    分類背景 = '#E9D5FF'
    分類文字色 = '#6B21A8'
    タイトル = '予定A'
    メモ = 'memo'
    期限タイプ = '予定日'
    開始日 = '2026/05/16'
    終了日 = '2026/05/16'
    開始時間 = '09:00'
    終了時間 = '10:00'
}
$logs = @([PSCustomObject]@{
    uid = '1'
    date = '2026/05/16'
    time = '15'
    content = '作業'
})
$cell = Get-GanttCellState -Task $task -DateText '2026/05/16' -TodayText '2026/05/16' -TaskLogs $logs -LastWorkDate '2026/05/16'
Assert-Equal $cell.Symbol '▶' 'Gantt cell symbol failed.'
Assert-True ($cell.ToolTip -match '15分') 'Gantt cell tooltip failed.'

$view = ConvertTo-GanttDataView -Tasks @($task) -Logs $logs -StartDate ([datetime]'2026-05-16') -Days 2 -BaseDate ([datetime]'2026-05-16')
Assert-Equal $view.Count 1 'Gantt view row count failed.'
$row = $view[0].Row
Assert-Equal $row['スケジュール名'] '予定A' 'Gantt row title failed.'
Assert-Equal $row['分類背景'] '#E9D5FF' 'Gantt row category background failed.'
Assert-Equal $row['分類文字色'] '#6B21A8' 'Gantt row category foreground failed.'
Assert-Equal $row['2026/05/16'] '▶' 'Gantt row date symbol failed.'
$suppressedView = ConvertTo-GanttDataView -Tasks @($task) -Logs $logs -StartDate ([datetime]'2026-05-16') -Days 1 -BaseDate ([datetime]'2026-05-16') -SuppressWeekendScheduleHighlight $true
Assert-Equal $suppressedView[0].Row['2026/05/16_Bg'] 'Transparent' 'Weekend schedule highlight suppression failed.'

$tmp = Join-Path $env:TEMP 'outlook-gantt-jsonstore-test.json'
if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force }
Assert-Equal @(Read-JsonArray -Path $tmp).Count 0 'Missing JSON should return empty array.'
Write-JsonData -Path $tmp -Data @([PSCustomObject]@{ uid = '1'; title = 'A' })
$loaded = @(Read-JsonArray -Path $tmp)
Assert-Equal $loaded[0].uid '1' 'JSON roundtrip failed.'
Remove-Item -LiteralPath $tmp -Force

$appointment = ConvertFrom-OutlookAppointment -Item ([PSCustomObject]@{
    EntryID = 'abc'
    Subject = '予定'
    Start = [datetime]'2026-05-16 09:00'
    End = [datetime]'2026-05-16 10:00'
    AllDayEvent = $false
    Body = '<p>memo</p>'
    Categories = '完了'
})
Assert-Equal $appointment.uid 'abc' 'Outlook appointment uid conversion failed.'
Assert-Equal $appointment.startTime '09:00' 'Outlook appointment start time conversion failed.'

Write-Host 'All tests passed.'
