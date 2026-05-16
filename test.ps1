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

. (Join-Path $repoRoot 'src/Config/Theme.ps1')
. (Join-Path $repoRoot 'src/Shared/TextUtils.ps1')
. (Join-Path $repoRoot 'src/Domain/ScheduleParser.ps1')
. (Join-Path $repoRoot 'src/Domain/AppointmentInput.ps1')
. (Join-Path $repoRoot 'src/Domain/WorkLogPresenter.ps1')
. (Join-Path $repoRoot 'src/Domain/GanttColumnTheme.ps1')
. (Join-Path $repoRoot 'src/Domain/GanttCell.ps1')
. (Join-Path $repoRoot 'src/Domain/GanttTaskFilter.ps1')
. (Join-Path $repoRoot 'src/Domain/GanttTableBuilder.ps1')
. (Join-Path $repoRoot 'src/Infrastructure/JsonStore.ps1')
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

Assert-Equal (Format-AppointmentTitle -Symbol '▶' -Category '業務' -Title '確認') '▶［業務］確認' 'Appointment title format failed.'
Assert-True (Test-TimeText -Text '09:00') 'Valid time should pass.'
Assert-True (-not (Test-TimeText -Text '9時')) 'Invalid time should fail.'

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
$headerTheme = Get-GanttDateHeaderTheme -Date ([datetime]'2026-05-20') -TodayText '2026/05/16'
Assert-Equal $headerTheme.Background $CLR_GANTT_HDR_ODD_BG 'Odd month header background failed.'

$task = [PSCustomObject]@{
    uid = '1'
    ステータス = '未着手'
    分類 = '調査'
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
Assert-Equal $row['2026/05/16'] '▶' 'Gantt row date symbol failed.'

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

