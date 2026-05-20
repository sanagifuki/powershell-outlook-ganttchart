param(
    [string]$Category = "業務",
    [string]$TitlePrefix = "テスト予定",
    [switch]$Busy,
    [switch]$Public
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $repoRoot 'src/Domain/AppointmentInput.ps1')
. (Join-Path $repoRoot 'src/Infrastructure/JsonStore.ps1')
. (Join-Path $repoRoot 'src/Domain/WorkLogEditor.ps1')
. (Join-Path $repoRoot 'src/Infrastructure/OutlookClient.ps1')

$baseDate = Get-Date
$isPrivate = -not $Public
$showAsFree = -not $Busy
$logsFile = Join-Path $repoRoot "logs.json"
$logs = @(Read-JsonArray -Path $logsFile)

$samples = @(
    [PSCustomObject]@{
        Symbol = "✕"
        Label = "絶対期限"
        Status = ""
        StartOffset = 1
        EndOffset = 1
        IsTimed = $false
        StartTime = ""
        EndTime = ""
        Memo = "テスト用の絶対期限予定です。終了日の翌日が期限として表示されます。"
        Logs = @(
            @{ Offset = 0; Content = "要件を確認"; Time = "20" }
        )
    },
    [PSCustomObject]@{
        Symbol = "◆"
        Label = "推奨期限"
        Status = "完了"
        StartOffset = 2
        EndOffset = 4
        IsTimed = $false
        StartTime = ""
        EndTime = ""
        Memo = "テスト用の推奨期限予定です。"
        Logs = @(
            @{ Offset = 2; Content = "対応方針を整理"; Time = "30" },
            @{ Offset = 4; Content = "完了確認"; Time = "15" }
        )
    },
    [PSCustomObject]@{
        Symbol = "◇"
        Label = "目安期限"
        Status = "保留"
        StartOffset = 5
        EndOffset = 7
        IsTimed = $false
        StartTime = ""
        EndTime = ""
        Memo = "テスト用の目安期限予定です。"
        Logs = @(
            @{ Offset = 5; Content = "一旦保留としてメモ"; Time = "" }
        )
    },
    [PSCustomObject]@{
        Symbol = "▶"
        Label = "予定日"
        Status = "廃止"
        StartOffset = 3
        EndOffset = 3
        IsTimed = $true
        StartTime = "10:00"
        EndTime = "11:00"
        Memo = "テスト用の時間指定あり予定日です。"
        Logs = @(
            @{ Offset = 3; Content = "予定日に作業"; Time = "45" }
        )
    },
    [PSCustomObject]@{
        Symbol = "★"
        Label = "参照用"
        Status = ""
        StartOffset = 0
        EndOffset = 0
        IsTimed = $false
        StartTime = ""
        EndTime = ""
        Memo = "テスト用の参照用予定です。"
        Logs = @()
    }
)

foreach ($sample in $samples) {
    $title = Format-AppointmentTitle -Symbol $sample.Symbol -Category $Category -Title "$TitlePrefix $($sample.Label)"
    $startDate = $baseDate.Date.AddDays($sample.StartOffset)
    $endDate = $baseDate.Date.AddDays($sample.EndOffset)

    $entryId = Add-OutlookAppointment `
        -Subject $title `
        -Body $sample.Memo `
        -StartDate $startDate `
        -EndDate $endDate `
        -IsTimed $sample.IsTimed `
        -StartTime $sample.StartTime `
        -EndTime $sample.EndTime `
        -IsPrivate $isPrivate `
        -ShowAsFree $showAsFree `
        -Categories $sample.Status

    foreach ($log in $sample.Logs) {
        $logDate = $baseDate.Date.AddDays([int]$log.Offset).ToString("yyyy/MM/dd")
        $newLog = New-WorkLog -Uid $entryId -Date $logDate -Content $log.Content -Time $log.Time
        $logs = @(Upsert-WorkLog -Logs $logs -NewLog $newLog -EditLog $null)
    }

    $statusText = if ([string]::IsNullOrWhiteSpace($sample.Status)) { "未着手/表示" } else { $sample.Status }
    Write-Host "Added: $title [$statusText] logs=$(@($sample.Logs).Count) ($($startDate.ToString('yyyy/MM/dd')) - $($endDate.ToString('yyyy/MM/dd')))"
}

Write-JsonData -Path $logsFile -Data $logs

Write-Host "Done. Run .\run-dev.ps1 and Outlook同期 to refresh schedules."
