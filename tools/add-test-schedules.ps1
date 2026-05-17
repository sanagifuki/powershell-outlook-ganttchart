param(
    [string]$Category = "業務",
    [string]$TitlePrefix = "テスト予定",
    [switch]$Busy,
    [switch]$Public
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

. (Join-Path $repoRoot 'src/Domain/AppointmentInput.ps1')
. (Join-Path $repoRoot 'src/Infrastructure/OutlookClient.ps1')

$baseDate = Get-Date
$isPrivate = -not $Public
$showAsFree = -not $Busy

$samples = @(
    [PSCustomObject]@{
        Symbol = "✕"
        Label = "絶対期限"
        StartOffset = 1
        EndOffset = 1
        IsTimed = $false
        StartTime = ""
        EndTime = ""
        Memo = "テスト用の絶対期限予定です。終了日の翌日が期限として表示されます。"
    },
    [PSCustomObject]@{
        Symbol = "◆"
        Label = "推奨期限"
        StartOffset = 2
        EndOffset = 4
        IsTimed = $false
        StartTime = ""
        EndTime = ""
        Memo = "テスト用の推奨期限予定です。"
    },
    [PSCustomObject]@{
        Symbol = "◇"
        Label = "目安期限"
        StartOffset = 5
        EndOffset = 7
        IsTimed = $false
        StartTime = ""
        EndTime = ""
        Memo = "テスト用の目安期限予定です。"
    },
    [PSCustomObject]@{
        Symbol = "▶"
        Label = "予定日"
        StartOffset = 3
        EndOffset = 3
        IsTimed = $true
        StartTime = "10:00"
        EndTime = "11:00"
        Memo = "テスト用の時間指定あり予定日です。"
    },
    [PSCustomObject]@{
        Symbol = "★"
        Label = "参照用"
        StartOffset = 0
        EndOffset = 0
        IsTimed = $false
        StartTime = ""
        EndTime = ""
        Memo = "テスト用の参照用予定です。"
    }
)

foreach ($sample in $samples) {
    $title = Format-AppointmentTitle -Symbol $sample.Symbol -Category $Category -Title "$TitlePrefix $($sample.Label)"
    $startDate = $baseDate.Date.AddDays($sample.StartOffset)
    $endDate = $baseDate.Date.AddDays($sample.EndOffset)

    Add-OutlookAppointment `
        -Subject $title `
        -Body $sample.Memo `
        -StartDate $startDate `
        -EndDate $endDate `
        -IsTimed $sample.IsTimed `
        -StartTime $sample.StartTime `
        -EndTime $sample.EndTime `
        -IsPrivate $isPrivate `
        -ShowAsFree $showAsFree

    Write-Host "Added: $title ($($startDate.ToString('yyyy/MM/dd')) - $($endDate.ToString('yyyy/MM/dd')))"
}

Write-Host "Done. Run .\run-dev.ps1 and Outlook同期 to refresh schedules."
