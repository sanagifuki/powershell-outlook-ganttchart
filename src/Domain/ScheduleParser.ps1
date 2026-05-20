function Get-ScheduleStatus {
    param(
        [string]$Categories,
        [string]$Title
    )

    if ($Categories -like "*完了*") {
        return "完了"
    }
    if ($Categories -like "*保留*") {
        return "保留"
    }
    if ($Categories -like "*廃止*") {
        return "廃棄"
    }
    if ($Title -match "★") {
        return "表示"
    }

    return "未着手"
}

function Get-ScheduleType {
    param([string]$Title)

    if ($Title -match "✕") { return "絶対期限" }
    if ($Title -match "◆") { return "推奨期限" }
    if ($Title -match "★") { return "参照用" }
    if ($Title -match "◇") { return "目安期限" }
    if ($Title -match "▶") { return "予定日" }

    return ""
}

function Get-ScheduleCategory {
    param([string]$Title)

    if ($Title -match "[\[［](.+?)[\]］]") {
        return $Matches[1]
    }

    return ""
}

function Get-CleanScheduleTitle {
    param([string]$Title)

    return $Title -replace "[\[［](.+?)[\]］]", ""
}

function ConvertTo-ScheduleItem {
    param($Task)

    $rawTitle = $Task.title
    $category = Get-ScheduleCategory -Title $rawTitle
    $categoryTheme = Get-CategoryTheme -Name $category

    [PSCustomObject]@{
        uid = $Task.uid
        タイトル = Get-CleanScheduleTitle -Title $rawTitle
        ステータス = Get-ScheduleStatus -Categories $Task.categories -Title $rawTitle
        期限タイプ = Get-ScheduleType -Title $rawTitle
        分類 = $category
        分類背景 = $categoryTheme.background
        分類文字色 = $categoryTheme.foreground
        開始日 = $Task.start
        終了日 = $Task.end
        開始時間 = $Task.startTime
        終了時間 = $Task.endTime
        メモ = Format-Memo $Task.memo
    }
}
