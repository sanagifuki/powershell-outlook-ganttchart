# Auto-generated from src/*.ps1 by build.ps1.
# Edit files under src/ instead of this generated file.
# Source commit: 67f3f8e

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$ScriptPath = if ($script:AppRoot) { $script:AppRoot } else { $PSScriptRoot }
$TasksFile = Join-Path $ScriptPath "schedules.json"
$LogsFile = Join-Path $ScriptPath "logs.json"

# ========================
# Outlook設定
# ========================
# 同期したいメールアドレスを指定します。
# ※空欄("")にすると、Outlookの既定(メイン)アカウントが同期されます。
$TARGET_OUTLOOK_EMAIL = ""

# ========================
# 汎用関数
# ========================
function Format-Memo($m) {
    if ($null -eq $m -or [string]::IsNullOrWhiteSpace($m)) { return "" }
    # GAS版 convertHtmlToPlainText の移植: HTMLタグ由来の改行を正規化
    $m = $m -replace '<br\s*/?>', "`n"
    $m = $m -replace '</p>|</div>', "`n"
    $m = $m -replace '<li>', "・"
    $m = $m -replace '</li>', "`n"
    $m = $m -replace '<[^>]+>', ""
    # 特殊な制御文字や連続スペースを整形
    $m = $m -replace "\t| +", " "
    # 改行コードの統一 (`n) と過剰な連続改行の抑制
    $m = $m -replace "`r`n|`r", "`n"
    $m = $m -replace "`n{3,}", "`n`n"
    # 箇条書き記号直後の不自然な改行（* \n 等）を抑制
    $m = $m -replace '([\*・])\s*\n', '$1 '
    # 箇条書き記号の統一 (* -> ・)
    $m = $m -replace '(?m)^\*\s*', "・"
    return $m.Trim()
}

# ========================
# カラー設定（ここで色を一括管理）
# ========================
# ガントチャート - セル背景
$CLR_GANTT_TODAY_BG = "#FCE5CD"   # 今日の列: 薄い黄色
$CLR_GANTT_WE_ODD_BG = "#B8C6C9"   # 土日（奇数月）: 薄い緑
$CLR_GANTT_WE_EVEN_BG = "#bbd5eb"   # 土日（偶数月）: 薄い青
$CLR_GANTT_ODD_BG = "#e2e2e2"   # 奇数月（平日）: 薄いグレー
$CLR_GANTT_EVEN_BG = "Transparent" # 偶数月（平日）: 透過

$CLR_STA_OVERDUE_BG = "#C27BA0"       # 遅延(・): 薄ピンク
$CLR_STA_OVERDUE_ABS_BG = "#E06666"   # 遅延(＊): 薄赤
$CLR_GANTT_PAST_BG = "#b4aacc"    # 過去の日付: 薄紫色

# ガントチャート - ヘッダー背景
$CLR_GANTT_HDR_DEFAULT_BG = "#EAEAEA"   # 通常ヘッダー
$CLR_GANTT_HDR_TODAY_BG = "#0000FF"   # 今日ヘッダー
$CLR_GANTT_HDR_TODAY_FG = "#FFFFFF"   # 今日ヘッダー文字: 青

$CLR_GANTT_HDR_ODD_BG = "#d6d6d6"   # 奇数月ヘッダー: 濃いグレー
$CLR_GANTT_HDR_FG = "#333333"   # ヘッダー文字（通常）

# ガントチャート - ステータス行色
$CLR_ROW_COMPLETED = "#B7E1CD"   # 完了行: 薄緑
$CLR_ROW_DISPLAY = "#FFE282"   # 表示行: 薄黄
$CLR_ROW_DISCARDED = "#999999"   # 廃棄行: グレー

# セル選択色
$CLR_SELECTED_BORDER = "#0058af"   # 選択セル枠

# テーブル設定
$COL_WIDTH_TITLE  = 200         # 「スケジュール名」列の初期幅
$COL_WIDTH_STATUS = 72          # 「ステータス」列の幅
$COL_WIDTH_TYPE   = 72          # 「期限タイプ」列の幅
$COL_WIDTH_CAT    = 80          # 「分類」列の幅
$COL_WIDTH_DATE   = 72          # 「日付」列の幅
$COL_WIDTH_TIME   = 42          # 「時間」列の幅
$COL_WIDTH_LOG_TIME = 60        # 「作業時間」(ログ)列の幅
$COL_WIDTH_MEMO   = 400         # 「メモ」列の幅
$FONT_MAIN = "Noto Sans JP, Meiryo, Yu Gothic UI" # 全体のメインフォント
$FONT_GANTT = "Yu Gothic"                          # ガントチャート箇所のフォント
$FONT_SIZE_MAIN = 11
$FONT_SIZE_DIALOG = 11
$FONT_SIZE_GANTT = 11
$CLR_EMPTY_CELL_BG = "#BDBDBD"     # 空欄セルの背景色（カレンダー同期など）
$CLR_GRID_LINE = "#b1b1b1"     # セル間の枠線色
$CLR_BORDER = "#b1b1b1"        # テーブル外枠・ヘッダー枠線色

# 記号色
$CLR_SYMBOL_FG = "#333333"   # 記号文字色: 黒
$CLR_TITLE_CELL_BG = "#bad1e4" # スケジュール名列の背景色: 薄い水色

# ステータス別バッジ色
$CLR_STA_UNSTARTED_BG = "#dddfe2"; $CLR_STA_UNSTARTED_FG = "#363636" # 未着手
$CLR_STA_COMPLETED_BG = "#1f8d61"; $CLR_STA_COMPLETED_FG = "#dae9d9" # 完了
$CLR_STA_DISCARDED_BG = "#3D3D3D"; $CLR_STA_DISCARDED_FG = "#ffffff" # 廃棄
$CLR_STA_DISPLAY_BG = "#FFD156"; $CLR_STA_DISPLAY_FG = "#363636" # 表示

# 期限タイプ別バッジ色
$CLR_TYP_ABSOLUTE_BG = "#B10202"; $CLR_TYP_ABSOLUTE_FG = "#f3cac8" # 絶対期限
$CLR_TYP_RECOMMEND_BG = "#0A53A8"; $CLR_TYP_RECOMMEND_FG = "#BFE0F6" # 推奨期限
$CLR_TYP_PLAN_BG = "#5A3286"; $CLR_TYP_PLAN_FG = "#E5CFF2" # 予定日
$CLR_TYP_GUIDE_BG = "#215A6C"; $CLR_TYP_GUIDE_FG = "#C6DBE1" # 目安期限
$CLR_TYP_REF_BG = "#FFD156"; $CLR_TYP_REF_FG = "#363636" # 参照用

# 分類別バッジ色（随時追加可能）
# 【追加方法】
# 1. 以下の変数セクションに、新しい分類用の背景色(_BG)と文字色(_FG)を追加する
# 2. XAML内の <Style x:Key="BadgeCategory" ...> セクション（200行目前後）に、
#    この変数を使用する <DataTrigger> を1行追加する
$CLR_CAT_IMPORTANT_BG = "#FECACA"; $CLR_CAT_IMPORTANT_FG = "#991B1B" # 重要
$CLR_CAT_CHORE_BG = "#FEF08A"; $CLR_CAT_CHORE_FG = "#854D0E" # 雑務
$CLR_CAT_PAY_BG = "#BAE6FD"; $CLR_CAT_PAY_FG = "#0369A1" # 業務
$CLR_CAT_PROC_BG = "#D1FAE5"; $CLR_CAT_PROC_FG = "#065F46" # 手続き
$CLR_CAT_RES_BG = "#E9D5FF"; $CLR_CAT_RES_FG = "#6B21A8" # 調査
$CLR_CAT_SKILL_BG = "#FED7AA"; $CLR_CAT_SKILL_FG = "#9A3412" # スキルアップ
$CLR_CAT_CORP_BG = "#E0E7FF"; $CLR_CAT_CORP_FG = "#3730A3" # 会社対応

function Read-JsonArray {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @()
    }

    $json = Get-Content $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($json)) {
        return @()
    }

    return @(ConvertFrom-Json $json)
}

function Write-JsonData {
    param(
        [string]$Path,
        $Data
    )

    $Data | ConvertTo-Json | Out-File $Path -Encoding UTF8
}

$CategoryConfigRoot = if ($ScriptPath) { $ScriptPath } elseif ($script:AppRoot) { $script:AppRoot } else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$CategoriesFile = Join-Path $CategoryConfigRoot "categories.json"

function Get-DefaultCategories {
    @(
        [PSCustomObject]@{ name = "業務"; background = $CLR_CAT_PAY_BG; foreground = $CLR_CAT_PAY_FG }
        [PSCustomObject]@{ name = "重要"; background = $CLR_CAT_IMPORTANT_BG; foreground = $CLR_CAT_IMPORTANT_FG }
        [PSCustomObject]@{ name = "調査"; background = $CLR_CAT_RES_BG; foreground = $CLR_CAT_RES_FG }
        [PSCustomObject]@{ name = "雑務"; background = $CLR_CAT_CHORE_BG; foreground = $CLR_CAT_CHORE_FG }
        [PSCustomObject]@{ name = "手続き"; background = $CLR_CAT_PROC_BG; foreground = $CLR_CAT_PROC_FG }
        [PSCustomObject]@{ name = "スキルアップ"; background = $CLR_CAT_SKILL_BG; foreground = $CLR_CAT_SKILL_FG }
        [PSCustomObject]@{ name = "会社対応"; background = $CLR_CAT_CORP_BG; foreground = $CLR_CAT_CORP_FG }
        [PSCustomObject]@{ name = "支払い"; background = $CLR_CAT_PAY_BG; foreground = $CLR_CAT_PAY_FG }
    )
}

function Get-Categories {
    if (-not (Test-Path $CategoriesFile)) {
        Write-JsonData -Path $CategoriesFile -Data (Get-DefaultCategories)
    }

    $categories = Read-JsonArray -Path $CategoriesFile

    foreach ($category in $categories) {
        if (-not $category.background) { $category | Add-Member -MemberType NoteProperty -Name background -Value "#E5E7EB" -Force }
        if (-not $category.foreground) { $category | Add-Member -MemberType NoteProperty -Name foreground -Value "#333333" -Force }
        $category
    }
}

function Get-CategoryNames {
    @(Get-Categories | ForEach-Object { $_.name })
}

function Get-CategoryTheme {
    param([string]$Name)

    $category = Get-Categories | Where-Object { $_.name -eq $Name } | Select-Object -First 1
    if ($category) {
        return $category
    }

    [PSCustomObject]@{
        name = $Name
        background = "#E5E7EB"
        foreground = "#333333"
    }
}
$SettingsConfigRoot = if ($ScriptPath) { $ScriptPath } elseif ($script:AppRoot) { $script:AppRoot } else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$SettingsFile = Join-Path $SettingsConfigRoot "settings.json"

function Get-DefaultAppSettings {
    [PSCustomObject]@{
        ganttDefaultDays = 35
        ganttStartOffsetDays = -7
        logInputModeDefault = $true
        suppressWeekendScheduleHighlightDefault = $false
        topmostDefault = $false
        addAppointmentPrivateDefault = $true
        addAppointmentShowAsFreeDefault = $true
        addAppointmentTypeDefaultSymbol = "◆"
        addAppointmentCategoryDefault = "業務"
        rememberWindowPlacement = $true
        windowWidth = 769
        windowHeight = 600
        windowMinWidth = 825
        windowMinHeight = 420
        windowLeft = $null
        windowTop = $null
        fontMain = "Noto Sans JP, Meiryo, Yu Gothic UI"
        fontGantt = "Yu Gothic"
        fontSizeMain = 11
        fontSizeDialog = 11
        fontSizeGantt = 11
    }
}

function Add-MissingSetting {
    param(
        $Settings,
        [string]$Name,
        $Value
    )

    if ($null -eq $Settings.PSObject.Properties[$Name]) {
        $Settings | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
    }
}

function Get-AppSettings {
    if (-not (Test-Path $SettingsFile)) {
        Write-JsonData -Path $SettingsFile -Data (Get-DefaultAppSettings)
    }

    $settings = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $defaults = Get-DefaultAppSettings
    foreach ($property in $defaults.PSObject.Properties) {
        Add-MissingSetting -Settings $settings -Name $property.Name -Value $property.Value
    }

    return $settings
}

function Save-AppSettings {
    param($Settings)

    Write-JsonData -Path $SettingsFile -Data $Settings
}

function Test-WindowPlacementOnScreen {
    param(
        [double]$Left,
        [double]$Top,
        [double]$Width,
        [double]$Height
    )

    $screenLeft = [System.Windows.SystemParameters]::VirtualScreenLeft
    $screenTop = [System.Windows.SystemParameters]::VirtualScreenTop
    $screenRight = $screenLeft + [System.Windows.SystemParameters]::VirtualScreenWidth
    $screenBottom = $screenTop + [System.Windows.SystemParameters]::VirtualScreenHeight

    return (
        $Left -lt $screenRight -and
        ($Left + [Math]::Min($Width, 120)) -gt $screenLeft -and
        $Top -lt $screenBottom -and
        ($Top + [Math]::Min($Height, 80)) -gt $screenTop
    )
}

function Restore-WindowPlacement {
    param(
        $Window,
        $Settings
    )

    if ($Settings.windowMinWidth -and [double]$Settings.windowMinWidth -gt 0) {
        $Window.MinWidth = [double]$Settings.windowMinWidth
    }
    if ($Settings.windowMinHeight -and [double]$Settings.windowMinHeight -gt 0) {
        $Window.MinHeight = [double]$Settings.windowMinHeight
    }

    if ($Settings.windowWidth -and [double]$Settings.windowWidth -ge $Window.MinWidth) {
        $Window.Width = [double]$Settings.windowWidth
    }
    if ($Settings.windowHeight -and [double]$Settings.windowHeight -ge $Window.MinHeight) {
        $Window.Height = [double]$Settings.windowHeight
    }

    if ($Settings.rememberWindowPlacement -and $null -ne $Settings.windowLeft -and $null -ne $Settings.windowTop) {
        $left = [double]$Settings.windowLeft
        $top = [double]$Settings.windowTop
        if (Test-WindowPlacementOnScreen -Left $left -Top $top -Width $Window.Width -Height $Window.Height) {
            $Window.WindowStartupLocation = "Manual"
            $Window.Left = $left
            $Window.Top = $top
        }
    }
}

function Save-WindowPlacement {
    param(
        $Window,
        $Settings
    )

    if (-not $Settings.rememberWindowPlacement) { return }
    if ($Window.WindowState -eq "Minimized") { return }

    $Settings.windowWidth = [int][Math]::Round($Window.RestoreBounds.Width)
    $Settings.windowHeight = [int][Math]::Round($Window.RestoreBounds.Height)
    $Settings.windowLeft = [int][Math]::Round($Window.RestoreBounds.Left)
    $Settings.windowTop = [int][Math]::Round($Window.RestoreBounds.Top)
    Save-AppSettings -Settings $Settings
}

function Apply-AppFontSettings {
    param($Settings)

    if (-not [string]::IsNullOrWhiteSpace($Settings.fontMain)) {
        $script:FONT_MAIN = [string]$Settings.fontMain
    }
    if (-not [string]::IsNullOrWhiteSpace($Settings.fontGantt)) {
        $script:FONT_GANTT = [string]$Settings.fontGantt
    }
    if ($Settings.fontSizeMain -and [double]$Settings.fontSizeMain -gt 0) {
        $script:FONT_SIZE_MAIN = [double]$Settings.fontSizeMain
    }
    if ($Settings.fontSizeDialog -and [double]$Settings.fontSizeDialog -gt 0) {
        $script:FONT_SIZE_DIALOG = [double]$Settings.fontSizeDialog
    }
    if ($Settings.fontSizeGantt -and [double]$Settings.fontSizeGantt -gt 0) {
        $script:FONT_SIZE_GANTT = [double]$Settings.fontSizeGantt
    }
}

function Select-ComboBoxItemByContent {
    param(
        $ComboBox,
        [string]$Content
    )

    for ($i = 0; $i -lt $ComboBox.Items.Count; $i++) {
        if ([string]$ComboBox.Items[$i].Content -eq $Content) {
            $ComboBox.SelectedIndex = $i
            return
        }
    }
}

function Select-ComboBoxItemByTag {
    param(
        $ComboBox,
        [string]$Tag
    )

    for ($i = 0; $i -lt $ComboBox.Items.Count; $i++) {
        if ([string]$ComboBox.Items[$i].Tag -eq $Tag) {
            $ComboBox.SelectedIndex = $i
            return
        }
    }
}
function Get-HelpText {
    @"
【ガントチャート使用時の留意事項・詳細リファレンス】
■ Outlook同期の手順・要件
・デスクトップ版 Outlook（Classic版）がインストールされ、アカウントがセットアップされている必要があります。
・Outlookにログインした状態であれば、本ツールの「Outlook同期」ボタンを押すだけで同期が始まります。
・Web版やスマホ版での変更がすぐに反映されない場合は、デスクトップ版Outlook側で一度「すべて送信/受信」を実行して最新の状態に更新してください。

■ Outlook同期とステータス
・同期範囲：前後36ヶ月分（3年間）を同期します。
・優先順位：Outlookの「カテゴリー」が最優先されます。
　- 「完了」カテゴリー ⇒ ステータス「完了」
　- 「廃止」カテゴリー ⇒ ステータス「廃棄」
　- 指定なし ⇒ 「未着手」（タイトルに★があれば「表示」）
・タイトル記号：タイトル内に「★」=参照用、「✕」=絶対期限、「◆」=推奨期限、「◇」=目安期限、「▶」=予定日として扱われます。
・絶対期限の仕様: 終了日の次の日が絶対期限日として扱う。（当日は作業できない前提）
・メモの整形：OutlookのHTML形式メモは、タグを除去してプレーンテキストとして表示します。

■ フィルタリングの仕様
・未着手フィルタ：ステータスが「未着手」かつ期限（終了日）が【今日 + 44日】より先の予定は、一覧をスッキリさせるため非表示になります。
・完了/廃棄表示：それぞれ最新の【直近15件】のみが表示されます。

■ 記号とカラーのルール
・塗りつぶし（▶■▲）：その日に「作業ログ」が存在することを示します。
・白抜き（▷□△）：作業ログがない「予定のみ」の状態を示します。
・特殊記号：
　- ✕：期間の【翌日】に表示されます。
　- ◉：完了ステータスの際、最後に作業ログを入力した日に表示されます。
　- ‼/❘：タイトルの記号に応じた推奨/目安期限の補助記号です。
・コーナーマーク（右上の青三角）：
　- スケジュール名列：メモが存在する場合に表示。
　- ガントセル：作業ログがある、または期限日に時間設定がある場合に表示。

■ 便利機能・操作
・ダブルクリック：
　- スケジュール名：作業ログ入力（ログモードON時）またはメモ表示。
　- ガントセル：その日の作業ログ詳細を表示。
・表示リセット：列の幅やスクロールを初期状態に戻します。

■ 設定ファイルによるカスタマイズ
・settings.json：画面や予定追加の初期値を管理します。ファイルがない場合は初回読み込み時に自動生成されます。
　- ganttDefaultDays：ガントチャートの初期表示日数。候補は 14 / 35 / 60 / 90 / 120。
　- ganttStartOffsetDays：ガント開始日の初期値。-7 なら今日の7日前、0 なら今日、7 なら今日の7日後。
　- logInputModeDefault：作業ログ入力モードを初期ONにするか。
　- suppressWeekendScheduleHighlightDefault：土日の予定セルのオレンジ色を初期状態で抑制するか。
　- topmostDefault：ウィンドウを最前面表示で起動するか。
　- addAppointmentPrivateDefault：予定追加時、「非公開」を初期ONにするか。
　- addAppointmentShowAsFreeDefault：予定追加時、「空き時間として表示」を初期ONにするか。
　- addAppointmentTypeDefaultSymbol：予定追加時の期限タイプ初期値。✕ / ◆ / ◇ / ▶ のいずれか。
　- addAppointmentCategoryDefault：予定追加時の分類初期値。
　- rememberWindowPlacement：終了時のウィンドウサイズ/位置を保存し、次回起動時に復元するか。
　- windowWidth / windowHeight：ウィンドウ幅/高さ。
　- windowMinWidth / windowMinHeight：ウィンドウを小さくできる最小幅/高さ。
　- windowLeft / windowTop：ウィンドウ位置。画面外になりそうな場合は中央表示に戻ります。
　- fontMain：画面全体で使うメインフォント。
　- fontGantt：ガントチャートの日付セル記号で使うフォント。
　- fontSizeMain：メイン画面の基本フォントサイズ。
　- fontSizeDialog：ヘルプや入力ダイアログの基本フォントサイズ。
　- fontSizeGantt：ガントチャートの日付セル記号のフォントサイズ。
・categories.json：分類名と分類バッジ色を管理します。ファイルがない場合は初回読み込み時に自動生成されます。
　- name：分類名。
　- background：分類バッジの背景色。
　- foreground：分類バッジの文字色。

■ データ管理
・schedules.json：Outlook同期データ（キャッシュ）。
・logs.json：入力した作業ログ。
・settings.json：ユーザー設定。
・categories.json：分類設定。
※バックアップ時は上記4ファイルを保存してください。
"@
}
function Get-ScheduleStatus {
    param(
        [string]$Categories,
        [string]$Title
    )

    if ($Categories -like "*完了*") {
        return "完了"
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
function Format-AppointmentTitle {
    param(
        [string]$Symbol,
        [string]$Category,
        [string]$Title
    )

    return "$Symbol［$Category］$Title"
}

function Test-TimeText {
    param([string]$Text)

    return ($Text -match '^\d{1,2}:\d{2}$')
}

function Add-CategoryText {
    param(
        [string]$Categories,
        [string]$Category
    )

    if ([string]::IsNullOrWhiteSpace($Categories)) {
        return $Category
    }
    if ($Categories -like "*$Category*") {
        return $Categories
    }

    return "$Categories, $Category"
}

function Remove-CategoryText {
    param(
        [string]$Categories,
        [string]$Category
    )

    if ([string]::IsNullOrWhiteSpace($Categories)) {
        return ""
    }

    $items = @($Categories -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne $Category })
    return ($items -join ', ')
}

function Set-CachedScheduleCompletion {
    param(
        [array]$Schedules,
        [string]$Uid,
        [bool]$Completed
    )

    foreach ($schedule in $Schedules) {
        if ($schedule.uid -eq $Uid) {
            if ($Completed) {
                $schedule.categories = Add-CategoryText -Categories $schedule.categories -Category "完了"
            }
            else {
                $schedule.categories = Remove-CategoryText -Categories $schedule.categories -Category "完了"
            }
        }
    }

    return @($Schedules)
}

function Set-CachedScheduleCompleted {
    param(
        [array]$Schedules,
        [string]$Uid
    )

    Set-CachedScheduleCompletion -Schedules $Schedules -Uid $Uid -Completed $true
}

function Get-CompletionToggleSchedules {
    param([array]$Schedules)

    @($Schedules)
}

function Get-IncompleteSchedules {
    param([array]$Schedules)

    @($Schedules | Where-Object { $_.ステータス -ne "完了" } | Sort-Object 開始日, タイトル)
}
function New-WorkLog {
    param(
        [string]$Uid,
        [string]$Date,
        [string]$Content,
        [string]$Time
    )

    [PSCustomObject]@{
        uid = $Uid
        date = $Date
        content = $Content
        time = $Time
    }
}

function Find-WorkLogIndex {
    param(
        [array]$Logs,
        $TargetLog
    )

    for ($i = 0; $i -lt $Logs.Count; $i++) {
        if ($Logs[$i].uid -eq $TargetLog.uid -and
            $Logs[$i].date -eq $TargetLog.date -and
            $Logs[$i].time -eq $TargetLog.time -and
            $Logs[$i].content -eq $TargetLog.content) {
            return $i
        }
    }

    return -1
}

function Upsert-WorkLog {
    param(
        [array]$Logs,
        $NewLog,
        $EditLog
    )

    if ($EditLog) {
        $index = Find-WorkLogIndex -Logs $Logs -TargetLog $EditLog
        if ($index -ge 0) {
            $Logs[$index] = $NewLog
            return @($Logs)
        }
    }

    return @($Logs + $NewLog)
}

function Format-WorkLogTime {
    param($WorkTime)

    if ($WorkTime) {
        if ($WorkTime -match '分$') {
            return $WorkTime
        }

        return "$($WorkTime)分"
    }

    return "0分"
}

function ConvertTo-DisplayWorkLog {
    param(
        $Log,
        [array]$Tasks
    )

    $taskEntry = $Tasks | Where-Object { $_.uid -eq $Log.uid } | Select-Object -First 1
    $title = if ($taskEntry) { $taskEntry.タイトル } else { "不明なスケジュール" }

    $Log | Add-Member -MemberType NoteProperty -Name "title" -Value $title -Force
    $Log | Add-Member -MemberType NoteProperty -Name "displayTime" -Value (Format-WorkLogTime -WorkTime ($Log.time)) -Force -PassThru
}

function ConvertTo-DisplayWorkLogs {
    param(
        [array]$Logs,
        [array]$Tasks
    )

    foreach ($log in ($Logs | Sort-Object date -Descending)) {
        ConvertTo-DisplayWorkLog -Log $log -Tasks $Tasks
    }
}
function Get-GanttDateCellBackground {
    param(
        [datetime]$Date,
        [string]$TodayText
    )

    $dateText = $Date.ToString("yyyy/MM/dd")
    $isToday = ($dateText -eq $TodayText)
    $isWeekend = ($Date.DayOfWeek -eq 'Saturday' -or $Date.DayOfWeek -eq 'Sunday')
    $isOddMonth = ($Date.Month % 2 -eq 1)

    if ($isToday) {
        return $CLR_GANTT_TODAY_BG
    }
    if ($isWeekend) {
        if ($isOddMonth) { return $CLR_GANTT_WE_ODD_BG }
        return $CLR_GANTT_WE_EVEN_BG
    }
    if ($isOddMonth) {
        return $CLR_GANTT_ODD_BG
    }

    return $CLR_GANTT_EVEN_BG
}

function Get-GanttDateHeaderTheme {
    param(
        [datetime]$Date,
        [string]$TodayText
    )

    $dateText = $Date.ToString("yyyy/MM/dd")
    $background = $CLR_GANTT_HDR_DEFAULT_BG
    $foreground = $CLR_GANTT_HDR_FG

    if ($dateText -eq $TodayText) {
        $background = $CLR_GANTT_HDR_TODAY_BG
        $foreground = $CLR_GANTT_HDR_TODAY_FG
    }
    elseif ($Date.Month % 2 -eq 1) {
        $background = $CLR_GANTT_HDR_ODD_BG
    }

    [PSCustomObject]@{
        Background = $background
        Foreground = $foreground
    }
}
function Get-GanttDeadline {
    param($Task)

    $deadline = $Task.終了日
    if ($Task.期限タイプ -eq "絶対期限" -and $Task.終了日 -ne "") {
        try {
            $deadline = ([datetime]$Task.終了日).AddDays(1).ToString("yyyy/MM/dd")
        }
        catch {
            $deadline = $Task.終了日
        }
    }

    return $deadline
}

function Test-GanttInPeriod {
    param(
        $Task,
        [string]$DateText
    )

    $inPeriod = ($Task.開始日 -ne "" -and $Task.終了日 -ne "" -and $DateText -ge $Task.開始日 -and $DateText -le $Task.終了日)
    if ($Task.開始日 -eq "" -and $Task.終了日 -ne "" -and $DateText -eq $Task.終了日) {
        $inPeriod = $true
    }

    return $inPeriod
}

function Get-GanttSymbol {
    param(
        $Task,
        [string]$DateText,
        [string]$TodayText,
        [string]$Deadline,
        [bool]$HasLog,
        [bool]$InPeriod,
        [string]$LastWorkDate
    )

    $symbol = ""

    if ($Task.期限タイプ -eq "参照用") {
        if ($InPeriod -or $DateText -eq $Deadline) {
            return "★"
        }

        return ""
    }

    if ($HasLog) {
        if ($Task.期限タイプ -ne "予定日" -and $Task.ステータス -eq "完了" -and $DateText -eq $LastWorkDate) {
            $symbol = "◉"
        }
        elseif ($Task.期限タイプ -eq "予定日" -and $DateText -eq $Deadline) {
            $symbol = "▶"
        }
        elseif ($InPeriod) {
            $symbol = "■"
        }
        else {
            $symbol = "▲"
        }
    }
    else {
        if ($Task.期限タイプ -eq "絶対期限" -and $DateText -eq $Deadline) {
            $symbol = "✕"
        }
        elseif ($Task.期限タイプ -eq "予定日" -and $DateText -eq $Deadline) {
            $symbol = "▷"
        }
        elseif ($InPeriod) {
            $symbol = "□"
        }
        elseif ($Task.ステータス -ne "完了" -and $Deadline -ne "" -and $DateText -gt $Deadline -and $DateText -lt $TodayText) {
            if ($Task.期限タイプ -ne "予定日") {
                $symbol = "・"
            }
            else {
                $symbol = "＊"
            }
        }
    }

    if ($DateText -eq $Deadline -and $symbol -ne "") {
        if ($Task.期限タイプ -eq "推奨期限") { $symbol += "‼" }
        if ($Task.期限タイプ -eq "目安期限") { $symbol += "❘" }
    }

    return $symbol
}

function Format-GanttCellToolTip {
    param(
        $Task,
        [string]$DateText,
        [string]$Deadline,
        [array]$LogsForDay
    )

    $hasLog = $LogsForDay.Count -gt 0
    $hasTimeOnDeadline = ($DateText -eq $Deadline -and ($Task.開始時間 -ne "" -or $Task.終了時間 -ne ""))
    if (-not $hasLog -and -not $hasTimeOnDeadline) {
        return ""
    }

    $timeInfo = ""
    if ($DateText -eq $Deadline) {
        if ($Task.開始時間 -ne "" -and $Task.終了時間 -ne "") { $timeInfo = "$($Task.開始時間)～$($Task.終了時間)`n`n" }
        elseif ($Task.開始時間 -eq "" -and $Task.終了時間 -ne "") { $timeInfo = "～$($Task.終了時間)`n`n" }
        elseif ($Task.終了時間 -eq "" -and $Task.開始時間 -ne "") { $timeInfo = "$($Task.開始時間)～`n`n" }
    }

    $logEntries = @()
    foreach ($log in $LogsForDay) {
        $logTime = Format-WorkLogTime -WorkTime ($log.time)
        $logEntries += "作業時間：$logTime`n$($log.content)"
    }

    return ($timeInfo + ($logEntries -join "`n`n")).Trim()
}

function Get-GanttCellBackground {
    param(
        $Task,
        [string]$DateText,
        [string]$TodayText,
        [string]$Symbol
    )

    $background = "Transparent"
    if ($DateText -lt $TodayText) {
        $background = $CLR_GANTT_PAST_BG
    }

    if ($Symbol -ne "") {
        if ($Task.ステータス -eq "完了") {
            $background = "Transparent"
        }
        elseif ($Symbol -match "✕") {
            $background = "#EA4335"
        }
        elseif ($Symbol -eq "★") {
            $background = $CLR_ROW_DISPLAY
        }
        elseif ($Symbol -eq "・") {
            $background = $CLR_STA_OVERDUE_BG
        }
        elseif ($Symbol -match "＊") {
            $background = $CLR_STA_OVERDUE_ABS_BG
        }
        else {
            $background = "#FF9900"
        }
    }

    return $background
}

function Get-GanttCellState {
    param(
        $Task,
        [string]$DateText,
        [string]$TodayText,
        [array]$TaskLogs,
        [string]$LastWorkDate
    )

    $logsForDay = @($TaskLogs | Where-Object { $_.date -eq $DateText })
    $hasLog = $logsForDay.Count -gt 0
    $deadline = Get-GanttDeadline -Task $Task
    $inPeriod = Test-GanttInPeriod -Task $Task -DateText $DateText
    $symbol = Get-GanttSymbol -Task $Task -DateText $DateText -TodayText $TodayText -Deadline $deadline -HasLog $hasLog -InPeriod $inPeriod -LastWorkDate $LastWorkDate
    $tooltip = Format-GanttCellToolTip -Task $Task -DateText $DateText -Deadline $deadline -LogsForDay $logsForDay
    $hasTimeOnThisDay = ($DateText -eq $deadline -and ($Task.開始時間 -ne "" -or $Task.終了時間 -ne ""))

    [PSCustomObject]@{
        Symbol = $symbol
        Background = Get-GanttCellBackground -Task $Task -DateText $DateText -TodayText $TodayText -Symbol $symbol
        ToolTip = $tooltip
        HasToolTip = ($tooltip -ne "")
        InfoVisibility = if ($hasLog -or $hasTimeOnThisDay) { "Visible" } else { "Collapsed" }
    }
}
function Get-RecentClosedTaskUids {
    param([array]$Tasks)

    $completedUids = @($Tasks | Where-Object { $_.ステータス -eq "完了" } | Select-Object -Last 15 | ForEach-Object { $_.uid })
    $discardedUids = @($Tasks | Where-Object { $_.ステータス -eq "廃棄" } | Select-Object -Last 15 | ForEach-Object { $_.uid })

    return @($completedUids + $discardedUids)
}

function Test-GanttTaskVisible {
    param(
        $Task,
        [array]$RecentClosedTaskUids,
        [string]$UnstartedEndLimitText
    )

    if (($Task.ステータス -eq "完了" -or $Task.ステータス -eq "廃棄") -and $RecentClosedTaskUids -notcontains $Task.uid) {
        return $false
    }

    if ($Task.ステータス -eq "未着手" -and $Task.終了日 -ne "" -and $Task.終了日 -gt $UnstartedEndLimitText) {
        return $false
    }

    return $true
}

function Select-GanttVisibleTasks {
    param(
        [array]$Tasks,
        [datetime]$BaseDate = (Get-Date)
    )

    $recentClosedTaskUids = Get-RecentClosedTaskUids -Tasks $Tasks
    $unstartedEndLimitText = $BaseDate.AddDays(44).ToString("yyyy/MM/dd")

    foreach ($task in $Tasks) {
        if (Test-GanttTaskVisible -Task $task -RecentClosedTaskUids $recentClosedTaskUids -UnstartedEndLimitText $unstartedEndLimitText) {
            $task
        }
    }
}

function New-GanttDataTable {
    param(
        [datetime]$StartDate,
        [int]$Days
    )

    $table = New-Object System.Data.DataTable
    [void]$table.Columns.Add("ステータス")
    [void]$table.Columns.Add("分類")
    [void]$table.Columns.Add("分類背景")
    [void]$table.Columns.Add("分類文字色")
    [void]$table.Columns.Add("スケジュール名")
    [void]$table.Columns.Add("メモ")
    [void]$table.Columns.Add("OriginalTask", [object])
    [void]$table.Columns.Add("MemoVis")

    for ($i = 0; $i -lt $Days; $i++) {
        $dateText = $StartDate.AddDays($i).ToString("yyyy/MM/dd")
        [void]$table.Columns.Add($dateText)
        [void]$table.Columns.Add("${dateText}_TT")
        [void]$table.Columns.Add("${dateText}_Vis", [bool])
        [void]$table.Columns.Add("${dateText}_Bg")
        [void]$table.Columns.Add("${dateText}_InfoVis")
    }

    return ,$table
}

function Add-GanttTaskRow {
    param(
        [System.Data.DataTable]$DataTable,
        $Task,
        [array]$Logs,
        [datetime]$StartDate,
        [int]$Days,
        [string]$TodayText,
        [bool]$SuppressWeekendScheduleHighlight = $false
    )

    $row = $DataTable.NewRow()
    $row["ステータス"] = $Task.ステータス
    $row["分類"] = $Task.分類
    $row["分類背景"] = $Task.分類背景
    $row["分類文字色"] = $Task.分類文字色
    $row["スケジュール名"] = $Task.タイトル
    $row["メモ"] = $Task.メモ
    $row["OriginalTask"] = $Task
    $row["MemoVis"] = if (-not [string]::IsNullOrWhiteSpace($Task.メモ) -and $Task.メモ -ne "") { "Visible" } else { "Collapsed" }

    $taskLogs = @($Logs | Where-Object { $_.uid -eq $Task.uid })
    $lastWorkDate = ""
    if ($taskLogs.Count -gt 0) {
        $lastWorkDate = ($taskLogs | Sort-Object date -Descending)[0].date
    }

    for ($i = 0; $i -lt $Days; $i++) {
        $date = $StartDate.AddDays($i)
        $dateText = $date.ToString("yyyy/MM/dd")
        $cell = Get-GanttCellState -Task $Task -DateText $dateText -TodayText $TodayText -TaskLogs $taskLogs -LastWorkDate $lastWorkDate
        $background = $cell.Background
        $isWeekend = ($date.DayOfWeek -eq 'Saturday' -or $date.DayOfWeek -eq 'Sunday')
        if ($SuppressWeekendScheduleHighlight -and $isWeekend -and $background -eq "#FF9900") {
            $background = "Transparent"
        }

        $row[$dateText] = $cell.Symbol
        $row["${dateText}_Bg"] = $background
        $row["${dateText}_TT"] = $cell.ToolTip
        $row["${dateText}_Vis"] = $cell.HasToolTip
        $row["${dateText}_InfoVis"] = $cell.InfoVisibility
    }

    [void]$DataTable.Rows.Add($row)
}

function ConvertTo-GanttDataView {
    param(
        [array]$Tasks,
        [array]$Logs,
        [datetime]$StartDate,
        [int]$Days,
        [datetime]$BaseDate = (Get-Date),
        [bool]$SuppressWeekendScheduleHighlight = $false
    )

    $todayText = $BaseDate.ToString("yyyy/MM/dd")
    $table = New-GanttDataTable -StartDate $StartDate -Days $Days

    foreach ($task in (Select-GanttVisibleTasks -Tasks $Tasks -BaseDate $BaseDate)) {
        Add-GanttTaskRow -DataTable $table -Task $task -Logs $Logs -StartDate $StartDate -Days $Days -TodayText $todayText -SuppressWeekendScheduleHighlight $SuppressWeekendScheduleHighlight
    }

    return ,$table.DefaultView
}
function Get-OutlookCalendarFolder {
    param(
        $Namespace,
        [string]$TargetEmail
    )

    if (-not [string]::IsNullOrWhiteSpace($TargetEmail)) {
        foreach ($store in $Namespace.Stores) {
            if ($store.DisplayName -eq $TargetEmail) {
                return $store.GetDefaultFolder(9)
            }
        }

        throw "指定したアカウント（$TargetEmail）が見つかりません。"
    }

    return $Namespace.GetDefaultFolder(9)
}

function ConvertFrom-OutlookAppointment {
    param($Item)

    [PSCustomObject]@{
        uid = $Item.EntryID
        title = $Item.Subject
        start = $Item.Start.ToString("yyyy/MM/dd")
        end = if ($Item.AllDayEvent) { $Item.End.AddDays(-1).ToString("yyyy/MM/dd") } else { $Item.End.ToString("yyyy/MM/dd") }
        startTime = if ($Item.AllDayEvent) { "" } else { $Item.Start.ToString("HH:mm") }
        endTime = if ($Item.AllDayEvent) { "" } else { $Item.End.ToString("HH:mm") }
        memo = Format-Memo $Item.Body
        categories = $Item.Categories
    }
}

function Get-OutlookScheduleSyncData {
    param(
        [string]$TargetEmail,
        [int]$MonthsBefore = 36,
        [int]$MonthsAfter = 36
    )

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $calendar = Get-OutlookCalendarFolder -Namespace $namespace -TargetEmail $TargetEmail
    $syncedAccount = $calendar.Store.DisplayName

    $items = $calendar.Items
    $items.IncludeRecurrences = $true
    $items.Sort("[開始]")

    $filterStart = (Get-Date).AddMonths(-$MonthsBefore).ToString("MM/dd/yyyy")
    $filterEnd = (Get-Date).AddMonths($MonthsAfter).ToString("MM/dd/yyyy")
    $filter = "[Start] >= '$filterStart' AND [End] <= '$filterEnd'"

    $count = 0
    $tasks = foreach ($item in $items.Restrict($filter)) {
        if ($item -isnot [System.__ComObject]) { continue }
        $count++
        ConvertFrom-OutlookAppointment -Item $item
    }

    [PSCustomObject]@{
        Tasks = @($tasks)
        Count = $count
        Account = $syncedAccount
    }
}

function Add-OutlookAppointment {
    param(
        [string]$Subject,
        [string]$Body,
        [datetime]$StartDate,
        [datetime]$EndDate,
        [bool]$IsTimed,
        [string]$StartTime,
        [string]$EndTime,
        [bool]$IsPrivate = $true,
        [bool]$ShowAsFree = $true
    )

    $outlook = New-Object -ComObject Outlook.Application
    $appointment = $outlook.CreateItem(1)

    $appointment.Subject = $Subject
    $appointment.Body = $Body
    $appointment.BusyStatus = if ($ShowAsFree) { 0 } else { 2 }
    $appointment.Sensitivity = if ($IsPrivate) { 2 } else { 0 }
    $appointment.ReminderSet = $false

    if ($IsTimed) {
        $appointment.AllDayEvent = $false
        $appointment.Start = $StartDate.ToString("yyyy/MM/dd ") + $StartTime
        $appointment.End = $StartDate.ToString("yyyy/MM/dd ") + $EndTime
    }
    else {
        $appointment.AllDayEvent = $true
        $appointment.Start = $StartDate.ToString("yyyy/MM/dd 00:00:00")
        $appointment.End = $EndDate.AddDays(1).ToString("yyyy/MM/dd 00:00:00")
    }

    $appointment.Save()
}

function Get-OutlookAppointmentOptions {
    param([string]$EntryId)

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $appointment = $namespace.GetItemFromID($EntryId)

    [PSCustomObject]@{
        IsPrivate = ($appointment.Sensitivity -eq 2)
        ShowAsFree = ($appointment.BusyStatus -eq 0)
    }
}

function Set-OutlookAppointmentDetails {
    param(
        [string]$EntryId,
        [string]$Subject,
        [string]$Body,
        [datetime]$StartDate,
        [datetime]$EndDate,
        [bool]$IsTimed,
        [string]$StartTime,
        [string]$EndTime,
        [bool]$IsPrivate = $true,
        [bool]$ShowAsFree = $true
    )

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $appointment = $namespace.GetItemFromID($EntryId)

    $appointment.Subject = $Subject
    $appointment.Body = $Body
    $appointment.BusyStatus = if ($ShowAsFree) { 0 } else { 2 }
    $appointment.Sensitivity = if ($IsPrivate) { 2 } else { 0 }
    $appointment.ReminderSet = $false

    if ($IsTimed) {
        $appointment.AllDayEvent = $false
        $appointment.Start = $StartDate.ToString("yyyy/MM/dd ") + $StartTime
        $appointment.End = $StartDate.ToString("yyyy/MM/dd ") + $EndTime
    }
    else {
        $appointment.AllDayEvent = $true
        $appointment.Start = $StartDate.ToString("yyyy/MM/dd 00:00:00")
        $appointment.End = $EndDate.AddDays(1).ToString("yyyy/MM/dd 00:00:00")
    }

    $appointment.Save()
}

function Set-OutlookAppointmentCompletion {
    param(
        [string]$EntryId,
        [bool]$Completed
    )

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $appointment = $namespace.GetItemFromID($EntryId)
    if ($Completed) {
        $appointment.Categories = Add-CategoryText -Categories $appointment.Categories -Category "完了"
    }
    else {
        $appointment.Categories = Remove-CategoryText -Categories $appointment.Categories -Category "完了"
    }
    $appointment.Save()
}
function Get-AllData {
    $tasks = Read-JsonArray -Path $TasksFile
    $logs = Read-JsonArray -Path $LogsFile
    
    $parsed = foreach ($t in $tasks) {
        ConvertTo-ScheduleItem -Task $t
    }
    return @{ parsed = @($parsed); logs = @($logs) }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="スケジュール管理システム" Height="600" Width="769" MinWidth="769" MinHeight="600"
        Background="#F5F5F5" Foreground="#333333" FontFamily="$FONT_MAIN" FontSize="$FONT_SIZE_MAIN"
        TextOptions.TextRenderingMode="ClearType" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <!-- Hide default selection background colors globally to ensure border-only selection -->
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="Transparent"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.InactiveSelectionHighlightBrushKey}" Color="Transparent"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightTextBrushKey}" Color="#333333"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.InactiveSelectionHighlightTextBrushKey}" Color="#333333"/>

        <!-- Common Styles -->
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="RowBackground" Value="#FFFFFF"/>
            <Setter Property="AlternatingRowBackground" Value="#F9F9F9"/>
            <Setter Property="Foreground" Value="#333333"/>
            <Setter Property="GridLinesVisibility" Value="All"/>
            <Setter Property="HorizontalGridLinesBrush" Value="$CLR_GRID_LINE"/>
            <Setter Property="VerticalGridLinesBrush" Value="$CLR_GRID_LINE"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="$CLR_BORDER"/>
            <Setter Property="HeadersVisibility" Value="Column"/>
            <Setter Property="MinRowHeight" Value="24"/>
            <Setter Property="CanUserAddRows" Value="False"/>
        </Style>
        <Style TargetType="DataGridCell">
            <!-- WPF標準の「選択時に背景色を強制上書き（透過）する」挙動を根絶するため、Templateごと差し替える -->
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="DataGridCell">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                SnapsToDevicePixels="True">
                            <ContentPresenter SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}" VerticalAlignment="Center" HorizontalAlignment="Stretch"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="BorderBrush" Value="$CLR_SELECTED_BORDER"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="FontFamily" Value="$FONT_MAIN"/>
            <Setter Property="Background" Value="#EAEAEA"/>
            <Setter Property="Foreground" Value="#333333"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
            <Setter Property="BorderBrush" Value="$CLR_BORDER"/>
            <Setter Property="HorizontalContentAlignment" Value="Center"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Background" Value="#EAEAEA"/>
            <Setter Property="Foreground" Value="#555555"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="$CLR_BORDER"/>
            <Setter Property="Margin" Value="0,0,0,0"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#FFFFFF"/>
                    <Setter Property="Foreground" Value="#1A73E8"/>
                    <Setter Property="BorderBrush" Value="$CLR_BORDER"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- Status Badges -->
        <Style x:Key="BadgeStatus" TargetType="Border">
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="TextBlock.FontWeight" Value="SemiBold"/>
            <Setter Property="TextBlock.FontSize" Value="10.5"/>
            <Style.Triggers>
                <DataTrigger Binding="{Binding ステータス}" Value="未着手"><Setter Property="Background" Value="$CLR_STA_UNSTARTED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_UNSTARTED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="完了"><Setter Property="Background" Value="$CLR_STA_COMPLETED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_COMPLETED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="廃棄"><Setter Property="Background" Value="$CLR_STA_DISCARDED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_DISCARDED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="表示"><Setter Property="Background" Value="$CLR_STA_DISPLAY_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_DISPLAY_FG"/></DataTrigger>
            </Style.Triggers>
        </Style>
        <!-- Type Badges -->
        <Style x:Key="BadgeType" TargetType="Border">
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="TextBlock.FontWeight" Value="SemiBold"/>
            <Setter Property="TextBlock.FontSize" Value="10.5"/>
            <Style.Triggers>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="絶対期限"><Setter Property="Background" Value="$CLR_TYP_ABSOLUTE_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_ABSOLUTE_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="推奨期限"><Setter Property="Background" Value="$CLR_TYP_RECOMMEND_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_RECOMMEND_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="予定日"><Setter Property="Background" Value="$CLR_TYP_PLAN_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_PLAN_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="目安期限"><Setter Property="Background" Value="$CLR_TYP_GUIDE_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_GUIDE_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 期限タイプ}" Value="参照用"><Setter Property="Background" Value="$CLR_TYP_REF_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_TYP_REF_FG"/></DataTrigger>
            </Style.Triggers>
        </Style>
        <!-- Category Badges -->
        <Style x:Key="BadgeCategory" TargetType="Border">
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="TextBlock.FontWeight" Value="SemiBold"/>
            <Setter Property="TextBlock.FontSize" Value="10.5"/>
        </Style>

        <DataTemplate x:Key="BadgeStatusTemplate">
            <Border Style="{StaticResource BadgeStatus}"><TextBlock Text="{Binding ステータス}" HorizontalAlignment="Center"/></Border>
        </DataTemplate>
        <DataTemplate x:Key="BadgeCategoryTemplate">
            <Border Style="{StaticResource BadgeCategory}" Background="{Binding 分類背景}"><TextBlock Text="{Binding 分類}" Foreground="{Binding 分類文字色}" HorizontalAlignment="Center"/></Border>
        </DataTemplate>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <Border Background="#FFFFFF" Padding="10,6" BorderThickness="0,0,0,1" BorderBrush="$CLR_BORDER">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Name="ToolbarPrimaryGroup" Grid.Row="0" Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,12,0">
                    <Button Name="BtnAddAppt" Content="追加" Padding="12,4" Background="#34A853" Foreground="White" BorderThickness="0" Margin="0,0,10,0" FontWeight="SemiBold" Cursor="Hand"/>
                    <Button Name="BtnEditAppt" Content="編集" Padding="12,4" Background="#5F6368" Foreground="White" BorderThickness="0" Margin="0,0,10,0" FontWeight="SemiBold" Cursor="Hand"/>
                    <Button Name="BtnComplete" Content="完了切替" Padding="12,4" Background="#1f8d61" Foreground="White" BorderThickness="0" Margin="0,0,10,0" FontWeight="SemiBold" Cursor="Hand"/>
                    <Button Name="BtnSync" Content="Outlook同期" Padding="12,4" Background="#1A73E8" Foreground="White" BorderThickness="0" Margin="0,0,10,0" FontWeight="SemiBold" Cursor="Hand"/>
                    <TextBlock Text="ガント開始日:" VerticalAlignment="Center" Margin="0,0,6,0" Foreground="#333333"/>
                    <DatePicker Name="GanttDatePicker" Width="120" VerticalAlignment="Center" VerticalContentAlignment="Center" Margin="0,0,5,0"/>
                    <TextBlock Text="表示日数:" VerticalAlignment="Center" Margin="0,0,6,0" Foreground="#333333"/>
                    <ComboBox Name="GanttDaysCombo" Width="40" VerticalAlignment="Center">
                        <ComboBoxItem Content="14"/>
                        <ComboBoxItem Content="35"/>
                        <ComboBoxItem Content="60"/>
                        <ComboBoxItem Content="90"/>
                        <ComboBoxItem Content="120"/>
                    </ComboBox>
                    <Button Name="BtnResetView" Content="表示リセット" Width="90" Height="24" Margin="10,0,0,0" Background="#F5F5F5" BorderBrush="$CLR_BORDER" Cursor="Hand"/>
                </StackPanel>
                <StackPanel Name="ToolbarSecondaryGroup" Grid.Row="0" Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="0">
                    <CheckBox Name="ChkLogMode" Content="作業ログ入力モード" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="#333333" ToolTip="作業ログ入力モード"/>
                    <CheckBox Name="ChkSuppressWeekendHighlight" Content="土日の予定色を抑制" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="#333333" ToolTip="土日の予定色を抑制"/>
                    <CheckBox Name="ChkTopmost" Content="最前面" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="#333333" ToolTip="最前面に固定"/>
                    <Button Name="BtnHelp" Content="？" Width="22" Height="22" Background="#F0F0F0" Foreground="#555555" BorderBrush="$CLR_BORDER" Cursor="Hand" ToolTip="留意事項を表示します"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <TabControl Name="MainTab" Grid.Row="1" Background="Transparent" BorderThickness="1" BorderBrush="$CLR_BORDER" Margin="6" Padding="0">
            <TabItem Header="🔍 カレンダー同期">
                <DataGrid Name="GridSync" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" SelectionUnit="Cell" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled" ScrollViewer.CanContentScroll="False">
                    <DataGrid.RowStyle>
                        <Style TargetType="DataGridRow">
                            <Setter Property="Background" Value="#FFFFFF"/>
                            <Style.Triggers>
                                <DataTrigger Binding="{Binding ステータス}" Value="完了">
                                    <Setter Property="Background" Value="$CLR_ROW_COMPLETED"/>
                                </DataTrigger>
                                <DataTrigger Binding="{Binding ステータス}" Value="廃棄">
                                    <Setter Property="Background" Value="$CLR_ROW_DISCARDED"/>
                                </DataTrigger>
                            </Style.Triggers>
                        </Style>
                    </DataGrid.RowStyle>
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="UID" Binding="{Binding uid}" Visibility="Collapsed"/>
                        <DataGridTemplateColumn Header="スケジュール名" SortMemberPath="タイトル" Width="$COL_WIDTH_TITLE">
                            <DataGridTemplateColumn.HeaderStyle>
                                <Style TargetType="DataGridColumnHeader" BasedOn="{StaticResource {x:Type DataGridColumnHeader}}"><Setter Property="Background" Value="$CLR_TITLE_CELL_BG"/></Style>
                            </DataGridTemplateColumn.HeaderStyle>
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <TextBox Text="{Binding タイトル, Mode=OneWay}" IsReadOnly="True" BorderThickness="0" Background="Transparent" VerticalAlignment="Center" Margin="6,0" TextWrapping="NoWrap"/>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTemplateColumn Header="ステータス" Width="$COL_WIDTH_STATUS">
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <Border Style="{StaticResource BadgeStatus}"><TextBlock Text="{Binding ステータス}" HorizontalAlignment="Center"/></Border>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTemplateColumn Header="期限タイプ" Width="$COL_WIDTH_TYPE">
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <Border Style="{StaticResource BadgeType}"><TextBlock Text="{Binding 期限タイプ}" HorizontalAlignment="Center"/></Border>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTemplateColumn Header="分類" Width="$COL_WIDTH_CAT" CellTemplate="{StaticResource BadgeCategoryTemplate}"/>
                        <DataGridTextColumn Header="開始日" Binding="{Binding 開始日}" Width="$COL_WIDTH_DATE">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="終了日" Binding="{Binding 終了日}" Width="$COL_WIDTH_DATE">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="開始" Binding="{Binding 開始時間}" Width="$COL_WIDTH_TIME">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Margin" Value="6,0"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                            <DataGridTextColumn.CellStyle>
                                <Style TargetType="DataGridCell" BasedOn="{StaticResource {x:Type DataGridCell}}">
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding 開始時間}" Value="">
                                            <Setter Property="Background" Value="$CLR_EMPTY_CELL_BG"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding 開始時間}" Value="{x:Null}">
                                            <Setter Property="Background" Value="$CLR_EMPTY_CELL_BG"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding ステータス}" Value="完了">
                                            <Setter Property="Background" Value="$CLR_ROW_COMPLETED"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding ステータス}" Value="廃棄">
                                            <Setter Property="Background" Value="$CLR_ROW_DISCARDED"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </DataGridTextColumn.CellStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="終了" Binding="{Binding 終了時間}" Width="$COL_WIDTH_TIME">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Margin" Value="6,0"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                            <DataGridTextColumn.CellStyle>
                                <Style TargetType="DataGridCell" BasedOn="{StaticResource {x:Type DataGridCell}}">
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding 終了時間}" Value="">
                                            <Setter Property="Background" Value="$CLR_EMPTY_CELL_BG"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding 終了時間}" Value="{x:Null}">
                                            <Setter Property="Background" Value="$CLR_EMPTY_CELL_BG"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding ステータス}" Value="完了">
                                            <Setter Property="Background" Value="$CLR_ROW_COMPLETED"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding ステータス}" Value="廃棄">
                                            <Setter Property="Background" Value="$CLR_ROW_DISCARDED"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </DataGridTextColumn.CellStyle>
                        </DataGridTextColumn>
                        <DataGridTemplateColumn Header="メモ" SortMemberPath="メモ" Width="*">
                            <DataGridTemplateColumn.HeaderStyle>
                                <Style TargetType="DataGridColumnHeader" BasedOn="{StaticResource {x:Type DataGridColumnHeader}}">
                                    <Setter Property="HorizontalContentAlignment" Value="Left"/>
                                    <Setter Property="Padding" Value="10,4,6,4"/>
                                </Style>
                            </DataGridTemplateColumn.HeaderStyle>
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <TextBox Text="{Binding メモ, Mode=OneWay}" IsReadOnly="True" BorderThickness="0" Background="Transparent" VerticalAlignment="Center" Margin="6,0" TextWrapping="Wrap"/>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
            <TabItem Header="📝 作業ログ">
                <DataGrid Name="GridLogs" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" SelectionUnit="Cell" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="対象スケジュール名" Binding="{Binding title}" Width="$COL_WIDTH_TITLE">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/><Setter Property="TextWrapping" Value="NoWrap"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="作業内容" Binding="{Binding content}" Width="*">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="Margin" Value="6,0"/><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="TextWrapping" Value="Wrap"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="作業日" Binding="{Binding date}" Width="$COL_WIDTH_DATE">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="作業時間" Binding="{Binding displayTime}" Width="$COL_WIDTH_LOG_TIME">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="6,0"/></Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
            <TabItem Header="📊 ガントチャート">
                <DataGrid Name="GridGantt" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" SelectionUnit="Cell" EnableRowVirtualization="True" EnableColumnVirtualization="True" BorderThickness="0" GridLinesVisibility="All" Background="Transparent" AlternationCount="0">
                    <DataGrid.FrozenColumnCount>3</DataGrid.FrozenColumnCount>
                    <DataGrid.RowStyle>
                        <Style TargetType="DataGridRow">
                            <Setter Property="Background" Value="#FFFFFF"/>
                        </Style>
                    </DataGrid.RowStyle>
                    <DataGrid.Columns>
                        <!-- Columns will be injected here -->
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
        </TabControl>
        
        <StatusBar Grid.Row="2" Background="#F0F0F0" BorderThickness="0,1,0,0" BorderBrush="$CLR_BORDER" Padding="4,2">
            <StatusBarItem>
                <TextBlock Name="StatusMsg" Text="準備完了" Foreground="#555555" FontWeight="SemiBold"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

$script:AppSettings = Get-AppSettings
Apply-AppFontSettings -Settings $AppSettings
$xaml = [xml]($xaml.OuterXml -replace 'Noto Sans JP, Meiryo, Yu Gothic UI', $FONT_MAIN)

function New-MainWindow {
    param([xml]$Xaml)

    $reader = (New-Object System.Xml.XmlNodeReader $Xaml)
    [System.Windows.Markup.XamlReader]::Load($reader)
}

function Initialize-MainWindowControls {
    param($Window)

    $script:BtnAddAppt = $Window.FindName("BtnAddAppt")
    $script:BtnEditAppt = $Window.FindName("BtnEditAppt")
    $script:BtnSync = $Window.FindName("BtnSync")
    $script:BtnComplete = $Window.FindName("BtnComplete")
    $script:GanttDatePicker = $Window.FindName("GanttDatePicker")
    $script:GanttDaysCombo = $Window.FindName("GanttDaysCombo")
    $script:BtnResetView = $Window.FindName("BtnResetView")
    $script:ChkLogMode = $Window.FindName("ChkLogMode")
    $script:ChkSuppressWeekendHighlight = $Window.FindName("ChkSuppressWeekendHighlight")
    $script:ChkTopmost = $Window.FindName("ChkTopmost")
    $script:ToolbarSecondaryGroup = $Window.FindName("ToolbarSecondaryGroup")
    $script:BtnHelp = $Window.FindName("BtnHelp")
    $script:GridSync = $Window.FindName("GridSync")
    $script:GridGantt = $Window.FindName("GridGantt")
    $script:GridLogs = $Window.FindName("GridLogs")
    $script:StatusMsg = $Window.FindName("StatusMsg")
}

$Form = New-MainWindow -Xaml $xaml
Initialize-MainWindowControls -Window $Form

Restore-WindowPlacement -Window $Form -Settings $AppSettings
$GanttDatePicker.SelectedDate = (Get-Date).AddDays([int]$AppSettings.ganttStartOffsetDays)
Select-ComboBoxItemByContent -ComboBox $GanttDaysCombo -Content ([string]$AppSettings.ganttDefaultDays)
if ($GanttDaysCombo.SelectedIndex -lt 0) { Select-ComboBoxItemByContent -ComboBox $GanttDaysCombo -Content "35" }
$ChkLogMode.IsChecked = [bool]$AppSettings.logInputModeDefault
$ChkSuppressWeekendHighlight.IsChecked = [bool]$AppSettings.suppressWeekendScheduleHighlightDefault
$ChkTopmost.IsChecked = [bool]$AppSettings.topmostDefault
$Form.Topmost = [bool]$ChkTopmost.IsChecked
$BtnAddAppt.Add_Click({ Invoke-AddAppointmentForm })

function ConvertTo-WpfBrush {
    param([string]$Color)

    [System.Windows.Media.BrushConverter]::new().ConvertFrom($Color)
}

function New-GanttHeaderStyle {
    param(
        [string]$Background,
        [string]$Foreground = $null
    )

    $style = New-Object System.Windows.Style([System.Windows.Controls.Primitives.DataGridColumnHeader])
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BackgroundProperty, (ConvertTo-WpfBrush -Color $Background))))
    if ($Foreground) {
        $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::ForegroundProperty, (ConvertTo-WpfBrush -Color $Foreground))))
    }
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::PaddingProperty, [System.Windows.Thickness]::new(6, 4, 6, 4))))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::HorizontalContentAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::VerticalContentAlignmentProperty, [System.Windows.VerticalAlignment]::Center)))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderThicknessProperty, [System.Windows.Thickness]::new(0, 0, 1, 1))))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderBrushProperty, (ConvertTo-WpfBrush -Color $CLR_BORDER))))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.TextBlock]::TextAlignmentProperty, [System.Windows.TextAlignment]::Center)))

    return $style
}

function New-GanttFixedCellStyle {
    [System.Windows.Markup.XamlReader]::Parse(@"
<Style TargetType="DataGridCell" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
            <Setter Property="BorderBrush" Value="$CLR_SELECTED_BORDER"/>
        </Trigger>
        <DataTrigger Binding="{Binding ステータス}" Value="完了">
            <Setter Property="Background" Value="$CLR_ROW_COMPLETED"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding ステータス}" Value="廃棄">
            <Setter Property="Background" Value="$CLR_ROW_DISCARDED"/>
        </DataTrigger>
    </Style.Triggers>
</Style>
"@)
}

function New-GanttTitleCellTemplate {
    [System.Windows.Markup.XamlReader]::Parse(@"
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Grid Background="Transparent">
        <TextBlock Text="{Binding スケジュール名}" VerticalAlignment="Center" Margin="6,0" TextWrapping="NoWrap">
            <TextBlock.ToolTip>
                <ToolTip>
                    <TextBlock Text="{Binding メモ}" TextWrapping="Wrap" MaxWidth="300" Foreground="#333333"/>
                </ToolTip>
            </TextBlock.ToolTip>
        </TextBlock>
        <Polygon Points="7,0 7,7 0,0" Fill="#0078D7" HorizontalAlignment="Right" VerticalAlignment="Top" 
                 Margin="0,-2,0,0" Visibility="{Binding MemoVis}"/>
    </Grid>
</DataTemplate>
"@)
}

function New-GanttDateCellStyle {
    param(
        [string]$DateText,
        [string]$CellBackground
    )

    [System.Windows.Markup.XamlReader]::Parse(@"
<Style TargetType="DataGridCell" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <!-- WPFテーマのIsSelectedトリガーによる論理プロパティ上書きを完全遮断するための独立テンプレート -->
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="DataGridCell">
                <Border Background="{TemplateBinding Background}" 
                        BorderThickness="{TemplateBinding BorderThickness}" 
                        BorderBrush="{TemplateBinding BorderBrush}" 
                        SnapsToDevicePixels="True">
                    <ContentPresenter SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}"
                                      HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
                </Border>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
    <Setter Property="Background" Value="$CellBackground"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Style.Triggers>
        
        <!-- 枠線描画 -->
        <Trigger Property="IsSelected" Value="True">
            <Setter Property="BorderBrush" Value="$CLR_SELECTED_BORDER"/>
        </Trigger>
        
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="$CLR_STA_OVERDUE_BG">
            <Setter Property="Background" Value="$CLR_STA_OVERDUE_BG"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="$CLR_STA_OVERDUE_ABS_BG">
            <Setter Property="Background" Value="$CLR_STA_OVERDUE_ABS_BG"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="$CLR_GANTT_PAST_BG">
            <Setter Property="Background" Value="$CLR_GANTT_PAST_BG"/>
        </DataTrigger>
        
        <!-- 記号の背景色 -->
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="#FF9900">
            <Setter Property="Background" Value="#FF9900"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="#EA4335">
            <Setter Property="Background" Value="#EA4335"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${DateText}_Bg]}" Value="$CLR_ROW_DISPLAY">
            <Setter Property="Background" Value="$CLR_ROW_DISPLAY"/>
        </DataTrigger>
    </Style.Triggers>
</Style>
"@)
}

function New-GanttDateCellTemplate {
    param([string]$DateText)

    [System.Windows.Markup.XamlReader]::Parse(@"
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Grid Background="Transparent" ToolTipService.IsEnabled="{Binding [${DateText}_Vis]}">
        <Grid.ToolTip>
            <ToolTip>
                <TextBlock Text="{Binding [${DateText}_TT]}" TextWrapping="Wrap" MaxWidth="300" />
            </ToolTip>
        </Grid.ToolTip>
        <TextBlock Text="{Binding [$DateText]}" 
                   HorizontalAlignment="Center" VerticalAlignment="Center" 
                   FontWeight="Bold" FontSize="$FONT_SIZE_GANTT" Foreground="$CLR_SYMBOL_FG" FontFamily="$FONT_GANTT"/>
        <!-- Combined Info Mark (Top-Right Blue) -->
        <Polygon Points="7,0 7,7 0,0" Fill="#0078D7" HorizontalAlignment="Right" VerticalAlignment="Top" 
                 Visibility="{Binding [${DateText}_InfoVis]}"/>
    </Grid>
</DataTemplate>
"@)
}
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
function Show-Toast($msg) {
    if ($StatusMsg) {
        $StatusMsg.Text = $msg
        
        # UIを強制更新（DoEvents）
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [Action]( { $frame.Continue = $false } )
        ) | Out-Null
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    }
}


function New-AddAppointmentWindow {
    [xml]$formXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Outlook予定追加" Width="420" SizeToContent="Height"
        TextOptions.TextRenderingMode="ClearType" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#666666"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Margin" Value="0,0,0,2"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Height" Value="28"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="DatePicker">
            <Setter Property="Height" Value="28"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="4,2"/>
            <Setter Property="BorderBrush" Value="#CCCCCC"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- 0: Type & Cat -->
            <RowDefinition Height="Auto"/> <!-- 1: Title -->
            <RowDefinition Height="Auto"/> <!-- 2: Dates -->
            <RowDefinition Height="Auto"/> <!-- 3: Times -->
            <RowDefinition Height="Auto"/> <!-- 4: Memo -->
            <RowDefinition Height="Auto"/> <!-- 5: Options -->
            <RowDefinition Height="Auto"/> <!-- 6: Buttons -->
        </Grid.RowDefinitions>

        <!-- 行0: 期限タイプ & 分類 -->
        <Grid Grid.Row="0" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="15"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="期限タイプ"/>
                <ComboBox Name="ComboType">
                    <ComboBoxItem Content="✕（絶対期限）" Tag="✕"/>
                    <ComboBoxItem Content="◆（推奨期限）" Tag="◆"/>
                    <ComboBoxItem Content="◇（目安期限）" Tag="◇"/>
                    <ComboBoxItem Content="▶（予定日）" Tag="▶"/>
                    <ComboBoxItem Content="★（参照用）" Tag="★"/>
                </ComboBox>
            </StackPanel>
            <StackPanel Grid.Column="2">
                <TextBlock Text="分類"/>
                <ComboBox Name="ComboCat">
                </ComboBox>
            </StackPanel>
        </Grid>

        <!-- 行1: タイトル -->
        <StackPanel Grid.Row="1" Margin="0,0,0,10">
            <TextBlock Text="タイトル"/>
            <TextBox Name="TxtTitle" Height="28"/>
        </StackPanel>

        <!-- 行2: 日付 -->
        <Grid Grid.Row="2" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="15"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="開始日"/>
                <DatePicker Name="DateStart"/>
            </StackPanel>
            <StackPanel Grid.Column="2" Name="ContainerEnd">
                <TextBlock Name="LabelEnd" Text="終了日"/>
                <DatePicker Name="DateEnd"/>
            </StackPanel>
        </Grid>

        <!-- 行3: 時間 (予定日の場合のみ) -->
        <Grid Name="PanelTime" Grid.Row="3" Margin="0,0,0,10" Visibility="Collapsed">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="15"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="開始時間"/>
                <TextBox Name="TimeStart" Height="28" Text="09:00" HorizontalContentAlignment="Center"/>
            </StackPanel>
            <StackPanel Grid.Column="2">
                <TextBlock Text="終了時間"/>
                <TextBox Name="TimeEnd" Height="28" Text="10:00" HorizontalContentAlignment="Center"/>
            </StackPanel>
        </Grid>

        <!-- 行4: メモ -->
        <StackPanel Grid.Row="4" VerticalAlignment="Stretch">
            <TextBlock Text="メモ"/>
            <TextBox Name="TxtMemo" MinHeight="80" MaxHeight="150" TextWrapping="Wrap" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" VerticalContentAlignment="Top" Padding="5" Background="#FFFFFF"/>
        </StackPanel>

        <!-- 行5: Outlook オプション -->
        <StackPanel Grid.Row="5" Orientation="Horizontal" Margin="0,10,0,0">
            <CheckBox Name="ChkPrivate" Content="非公開" VerticalAlignment="Center" Margin="0,0,14,0"/>
            <CheckBox Name="ChkShowAsFree" Content="空き時間として表示" VerticalAlignment="Center"/>
        </StackPanel>

        <!-- 行6: ボタン -->
        <StackPanel Grid.Row="6" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,15,0,0">
            <Button Name="BtnSave" Content="Outlookに保存" Width="130" Height="32" Background="#1A73E8" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand" Margin="0,0,10,0">
                <Button.Style>
                    <Style TargetType="Button">
                        <Style.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1557B0"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Button.Style>
            </Button>
            <Button Name="BtnCancel" Content="キャンセル" Width="90" Height="32" Background="#F5F5F5" BorderBrush="#DDDDDD" Cursor="Hand"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader $formXaml
    [Windows.Markup.XamlReader]::Load($reader)
}

function Update-AddAppointmentTypeUi {
    param(
        $ComboType,
        $PanelTime,
        $DateStart,
        $DateEnd
    )

    $selectedItem = $ComboType.SelectedItem
    $isTimed = ($null -ne $selectedItem -and $selectedItem.Tag -eq "▶")
    $isSingleDay = ($null -ne $selectedItem -and ($selectedItem.Tag -eq "▶" -or $selectedItem.Tag -eq "★"))

    if ($isTimed) {
        $PanelTime.Visibility = [System.Windows.Visibility]::Visible
    }
    else {
        $PanelTime.Visibility = [System.Windows.Visibility]::Collapsed
    }

    if ($isSingleDay) {
        $DateEnd.SelectedDate = $DateStart.SelectedDate
        $DateEnd.IsEnabled = $false
    }
    else {
        $DateEnd.IsEnabled = $true
    }
}

function Test-AddAppointmentInput {
    param(
        $TitleTextBox,
        $DateStart,
        [bool]$IsTimed,
        $TimeStart,
        $TimeEnd
    )

    if ([string]::IsNullOrWhiteSpace($TitleTextBox.Text)) {
        [System.Windows.MessageBox]::Show("タイトルを入力してください。", "エラー", "OK", "Error")
        return $false
    }
    if (-not $DateStart.SelectedDate) {
        [System.Windows.MessageBox]::Show("開始日を選択してください。", "エラー", "OK", "Error")
        return $false
    }
    if ($IsTimed) {
        if (-not (Test-TimeText -Text $TimeStart.Text)) {
            [System.Windows.MessageBox]::Show("開始時間の形式が正しくありません（例 09:00）", "形式エラー", "OK", "Warning")
            return $false
        }
        if (-not (Test-TimeText -Text $TimeEnd.Text)) {
            [System.Windows.MessageBox]::Show("終了時間の形式が正しくありません（例 10:00）", "形式エラー", "OK", "Warning")
            return $false
        }
    }

    return $true
}

# 予定追加フォームを表示する関数
function Invoke-AppointmentForm {
    param(
        $ExistingTask
    )

    $window = New-AddAppointmentWindow

    $comboType = $window.FindName("ComboType")
    $comboCat  = $window.FindName("ComboCat")
    $comboCat.ItemsSource = Get-CategoryNames
    $txtTitle  = $window.FindName("TxtTitle")
    $dateStart = $window.FindName("DateStart")
    $dateEnd   = $window.FindName("DateEnd")
    $panelTime = $window.FindName("PanelTime")
    $timeStart = $window.FindName("TimeStart")
    $timeEnd   = $window.FindName("TimeEnd")
    $txtMemo   = $window.FindName("TxtMemo")
    $chkPrivate = $window.FindName("ChkPrivate")
    $chkShowAsFree = $window.FindName("ChkShowAsFree")
    $btnSave   = $window.FindName("BtnSave")
    $btnCancel = $window.FindName("BtnCancel")

    $settings = Get-AppSettings
    $isEditMode = ($null -ne $ExistingTask)

    if ($isEditMode) {
        $window.Title = "Outlook予定編集"
        $btnSave.Content = "変更を保存"
    }

    # 初期値設定
    $today = Get-Date
    $dateStart.SelectedDate = $today
    $dateEnd.SelectedDate   = $today

    if ($isEditMode) {
        $typeSymbol = switch ($ExistingTask.期限タイプ) {
            "絶対期限" { "✕" }
            "推奨期限" { "◆" }
            "目安期限" { "◇" }
            "予定日" { "▶" }
            "参照用" { "★" }
            default { "◆" }
        }
        Select-ComboBoxItemByTag -ComboBox $comboType -Tag $typeSymbol
        $comboCat.Text = [string]$ExistingTask.分類
        $txtTitle.Text = ([string]$ExistingTask.タイトル) -replace '^[✕◆◇▶★]\s*', ''
        $dateStart.SelectedDate = [datetime]::Parse($ExistingTask.開始日)
        $dateEnd.SelectedDate = [datetime]::Parse($ExistingTask.終了日)
        if (-not [string]::IsNullOrWhiteSpace($ExistingTask.開始時間)) { $timeStart.Text = $ExistingTask.開始時間 }
        if (-not [string]::IsNullOrWhiteSpace($ExistingTask.終了時間)) { $timeEnd.Text = $ExistingTask.終了時間 }
        $txtMemo.Text = [string]$ExistingTask.メモ
        try {
            $outlookOptions = Get-OutlookAppointmentOptions -EntryId $ExistingTask.uid
            $chkPrivate.IsChecked = [bool]$outlookOptions.IsPrivate
            $chkShowAsFree.IsChecked = [bool]$outlookOptions.ShowAsFree
        }
        catch {
            $chkPrivate.IsChecked = [bool]$settings.addAppointmentPrivateDefault
            $chkShowAsFree.IsChecked = [bool]$settings.addAppointmentShowAsFreeDefault
        }
    }
    else {
        Select-ComboBoxItemByTag -ComboBox $comboType -Tag $settings.addAppointmentTypeDefaultSymbol
        if ($comboType.SelectedIndex -lt 0) { Select-ComboBoxItemByTag -ComboBox $comboType -Tag "◆" }
        $comboCat.Text = [string]$settings.addAppointmentCategoryDefault
        if ([string]::IsNullOrWhiteSpace($comboCat.Text) -and $comboCat.Items.Count -gt 0) { $comboCat.SelectedIndex = 0 }
        $chkPrivate.IsChecked = [bool]$settings.addAppointmentPrivateDefault
        $chkShowAsFree.IsChecked = [bool]$settings.addAppointmentShowAsFreeDefault
    }

    $updateUIByType = {
        Update-AddAppointmentTypeUi -ComboType $comboType -PanelTime $panelTime -DateStart $dateStart -DateEnd $dateEnd
    }

    $comboType.Add_SelectionChanged({
        & $updateUIByType
    })

    # 単日扱い（予定日・参照用）の場合は終了日も同期
    $dateStart.Add_SelectedDateChanged({
        $selectedItem = $comboType.SelectedItem
        if ($null -ne $selectedItem -and ($selectedItem.Tag -eq "▶" -or $selectedItem.Tag -eq "★")) {
            $dateEnd.SelectedDate = $dateStart.SelectedDate
        }
    })

    # 初回実行
    $window.Add_Loaded({ & $updateUIByType })

    # 保存処理
    $btnSave.Add_Click({
        $selectedType = $comboType.SelectedItem
        if ($null -eq $selectedType) { return }
        $isTimed = ($selectedType.Tag -eq "▶")

        if (-not (Test-AddAppointmentInput -TitleTextBox $txtTitle -DateStart $dateStart -IsTimed $isTimed -TimeStart $timeStart -TimeEnd $timeEnd)) {
            return
        }

        try {
            $formattedTitle = Format-AppointmentTitle -Symbol $selectedType.Tag -Category $comboCat.Text -Title $txtTitle.Text

            $sDate = $dateStart.SelectedDate
            $eDate = $dateEnd.SelectedDate

            if ($isEditMode) {
                Set-OutlookAppointmentDetails -EntryId $ExistingTask.uid -Subject $formattedTitle -Body $txtMemo.Text -StartDate $sDate -EndDate $eDate -IsTimed $isTimed -StartTime $timeStart.Text -EndTime $timeEnd.Text -IsPrivate $chkPrivate.IsChecked -ShowAsFree $chkShowAsFree.IsChecked
                Show-Toast "Outlook予定を更新しました: $formattedTitle"
            }
            else {
                Add-OutlookAppointment -Subject $formattedTitle -Body $txtMemo.Text -StartDate $sDate -EndDate $eDate -IsTimed $isTimed -StartTime $timeStart.Text -EndTime $timeEnd.Text -IsPrivate $chkPrivate.IsChecked -ShowAsFree $chkShowAsFree.IsChecked
                Show-Toast "Outlookに予定を追加しました: $formattedTitle"
            }
            $window.DialogResult = $true
            $window.Close()
        } catch {
            [System.Windows.MessageBox]::Show("保存に失敗しました。詳細:`n$($_.Exception.Message)", "エラー", "OK", "Error")
        }
    })

    $btnCancel.Add_Click({
            $window.DialogResult = $false
            $window.Close()
        })
    if ($window.ShowDialog() -eq $true) {
        if ($isEditMode) {
            Invoke-OutlookSync -SuccessPrefix "予定編集後の同期完了"
        }
        else {
            Invoke-OutlookSync -SuccessPrefix "予定追加後の同期完了"
        }
    }
}

function Invoke-AddAppointmentForm {
    Invoke-AppointmentForm
}

function Invoke-EditAppointmentForm {
    param($Task)

    Invoke-AppointmentForm -ExistingTask $Task
}

function Invoke-ViewForm {
    param(
        $title,
        $text,
        [int]$Width = 650,
        [int]$Height = 500,
        [int]$MinWidth = 320,
        [int]$MinHeight = 300
    )
    [xml]$vXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="詳細" Height="$Height" Width="$Width" MinWidth="$MinWidth" MinHeight="$MinHeight"
            WindowStartupLocation="CenterOwner" Background="#F0F0F0" FontFamily="$FONT_MAIN" FontSize="$FONT_SIZE_DIALOG"
            TextOptions.TextRenderingMode="ClearType" ResizeMode="CanResizeWithGrip">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="16">
            <TextBlock Name="txtView" TextWrapping="Wrap" Foreground="#333333" LineHeight="20"/>
        </ScrollViewer>
    </Window>
"@
    $vReader = (New-Object System.Xml.XmlNodeReader $vXaml)
    $v = [System.Windows.Markup.XamlReader]::Load($vReader)
    $v.Owner = $Form
    $v.Title = $title
    $v.FindName("txtView").Text = $text
    [void]$v.ShowDialog()
}

function New-LogWindow {
    param($Task)

    [xml]$dXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="ログ入力: $($Task.タイトル -replace '&','&amp;')" Height="320" Width="350"
            Background="#F5F5F5" Foreground="#333333" FontFamily="$FONT_MAIN" FontSize="$FONT_SIZE_DIALOG"
            TextOptions.TextRenderingMode="ClearType" WindowStartupLocation="CenterOwner" ResizeMode="CanResize" MinWidth="320" MinHeight="300">
        <Grid Margin="12,8,12,12">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="作業日" Margin="0,0,0,2" FontWeight="SemiBold"/>
            <DatePicker Name="dpDate" Grid.Row="1" Height="26" Margin="0,0,0,8"/>
            
            <TextBlock Text="作業時間 (分)" Grid.Row="2" Margin="0,0,0,2" FontWeight="SemiBold"/>
            <TextBox Name="txtTime" Grid.Row="3" Height="26" Margin="0,0,0,8" Padding="4" Text="15"/>
            
            <TextBlock Text="作業内容" Grid.Row="4" Margin="0,0,0,2" FontWeight="SemiBold"/>
            <TextBox Name="txtContent" Grid.Row="5" MinHeight="60" TextWrapping="Wrap" AcceptsReturn="True"
                     Background="#FFFFFF" Foreground="#333333" BorderThickness="1" BorderBrush="#CCCCCC" Padding="4"/>
                     
            <Button Name="btnSave" Grid.Row="6" Content="保存" Height="30" Width="100" HorizontalAlignment="Right" Background="#1A73E8" Foreground="White" 
                    BorderThickness="0" Margin="0,10,0,0" FontWeight="SemiBold" Cursor="Hand"/>
        </Grid>
    </Window>
"@
    $dReader = (New-Object System.Xml.XmlNodeReader $dXaml)
    [System.Windows.Markup.XamlReader]::Load($dReader)
}

function Initialize-LogFormFields {
    param(
        $DatePicker,
        $TimeTextBox,
        $ContentTextBox,
        $DefaultDate,
        $EditLog
    )

    if ($EditLog) {
        $DatePicker.Text = $EditLog.date
        if ($EditLog.time) { $TimeTextBox.Text = ($EditLog.time -replace '分$', '') }
        $ContentTextBox.Text = $EditLog.content
    }
    elseif ($DefaultDate) {
        $DatePicker.Text = $DefaultDate
    }
    else {
        $DatePicker.Text = (Get-Date).ToString("yyyy/MM/dd")
    }
}

function Invoke-LogForm {
    param($task, $defaultDate, $editLog)
    
    $d = New-LogWindow -Task $task
    $d.Owner = $Form

    $dpDate = $d.FindName("dpDate")
    $txtTime = $d.FindName("txtTime")
    $txtContent = $d.FindName("txtContent")
    $btnSave = $d.FindName("btnSave")
    
    Initialize-LogFormFields -DatePicker $dpDate -TimeTextBox $txtTime -ContentTextBox $txtContent -DefaultDate $defaultDate -EditLog $editLog
    
    $btnSave.Add_Click({
            [array]$logs = Read-JsonArray -Path $LogsFile
            $saveDate = if ($dpDate.SelectedDate) { $dpDate.SelectedDate.ToString("yyyy/MM/dd") } else { $dpDate.Text }
        
            $newLog = New-WorkLog -Uid $task.uid -Date $saveDate -Content $txtContent.Text -Time $txtTime.Text
            $logs = Upsert-WorkLog -Logs $logs -NewLog $newLog -EditLog $editLog
            Write-JsonData -Path $LogsFile -Data $logs
        
            $d.DialogResult = $true
            $d.Close()
        })
    
    if ($d.ShowDialog() -eq $true) {
        Refresh-UI
        Show-Toast "保存しました"
    }
}

function Invoke-CompleteSchedulePicker {
    param([array]$Tasks)

    $items = Get-CompletionToggleSchedules -Schedules $Tasks
    if ($items.Count -eq 0) {
        Show-Toast "切り替えできるスケジュールがありません"
        return $null
    }

    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="完了切替" Height="190" Width="520"
            Background="#F5F5F5" Foreground="#333333" FontFamily="$FONT_MAIN" FontSize="$FONT_SIZE_DIALOG"
            TextOptions.TextRenderingMode="ClearType" WindowStartupLocation="CenterOwner" ResizeMode="NoResize">
        <Grid Margin="14">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="完了状態を切り替えるスケジュール" FontWeight="SemiBold" Margin="0,0,0,6"/>
            <ComboBox Name="ComboSchedule" Grid.Row="1" Height="28" DisplayMemberPath="DisplayText"/>
            <TextBlock Name="TxtMemo" Grid.Row="2" TextWrapping="Wrap" Foreground="#666666" Margin="0,8,0,0"/>
            <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
                <Button Name="BtnCancel" Content="キャンセル" Width="90" Height="28" Margin="0,0,8,0"/>
                <Button Name="BtnOk" Content="完了にする" Width="110" Height="28" Background="#1f8d61" Foreground="White" BorderThickness="0"/>
            </StackPanel>
        </Grid>
    </Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    $window.Owner = $Form

    $combo = $window.FindName("ComboSchedule")
    $memo = $window.FindName("TxtMemo")
    $btnOk = $window.FindName("BtnOk")
    $btnCancel = $window.FindName("BtnCancel")

    $comboItems = @($items | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name DisplayText -Value "$($_.開始日) $($_.タイトル)" -Force
            $_
        })
    $combo.ItemsSource = $comboItems
    $combo.SelectedIndex = 0

    $updateTogglePreview = {
        if ($combo.SelectedItem) {
            if ($combo.SelectedItem.ステータス -eq "完了") {
                $memo.Text = "現在: 完了 / 実行後: 非完了に戻す"
                $btnOk.Content = "非完了に戻す"
                $btnOk.Background = "#5F6368"
            }
            else {
                $memo.Text = "現在: $($combo.SelectedItem.ステータス) / 実行後: 完了にする"
                $btnOk.Content = "完了にする"
                $btnOk.Background = "#1f8d61"
            }
        }
    }

    $combo.Add_SelectionChanged({ & $updateTogglePreview })
    & $updateTogglePreview

    $btnCancel.Add_Click({
            $window.DialogResult = $false
            $window.Close()
        })
    $btnOk.Add_Click({
            if (-not $combo.SelectedItem) {
                Show-Toast "スケジュールを選択してください"
                return
            }
            $window.DialogResult = $true
            $window.Close()
        })

    if ($window.ShowDialog() -eq $true) {
        return $combo.SelectedItem
    }

    return $null
}

function Invoke-ScheduleEditPicker {
    param([array]$Tasks)

    $items = @($Tasks)
    if ($items.Count -eq 0) {
        Show-Toast "編集できるスケジュールがありません"
        return $null
    }

    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="スケジュール編集" Height="190" Width="520"
            Background="#F5F5F5" Foreground="#333333" FontFamily="$FONT_MAIN" FontSize="$FONT_SIZE_DIALOG"
            TextOptions.TextRenderingMode="ClearType" WindowStartupLocation="CenterOwner" ResizeMode="NoResize">
        <Grid Margin="14">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="編集するスケジュール" FontWeight="SemiBold" Margin="0,0,0,6"/>
            <ComboBox Name="ComboSchedule" Grid.Row="1" Height="28" DisplayMemberPath="DisplayText"/>
            <TextBlock Name="TxtMemo" Grid.Row="2" TextWrapping="Wrap" Foreground="#666666" Margin="0,8,0,0"/>
            <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
                <Button Name="BtnCancel" Content="キャンセル" Width="90" Height="28" Margin="0,0,8,0"/>
                <Button Name="BtnOk" Content="編集する" Width="100" Height="28" Background="#1A73E8" Foreground="White" BorderThickness="0"/>
            </StackPanel>
        </Grid>
    </Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    $window.Owner = $Form

    $combo = $window.FindName("ComboSchedule")
    $memo = $window.FindName("TxtMemo")
    $btnOk = $window.FindName("BtnOk")
    $btnCancel = $window.FindName("BtnCancel")

    $comboItems = @($items | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name DisplayText -Value "$($_.開始日) $($_.タイトル)" -Force
            $_
        })
    $combo.ItemsSource = $comboItems
    $combo.SelectedIndex = 0

    $combo.Add_SelectionChanged({
            if ($combo.SelectedItem) {
                $memo.Text = "分類: $($combo.SelectedItem.分類) / 期限タイプ: $($combo.SelectedItem.期限タイプ)"
            }
        })
    if ($combo.SelectedItem) {
        $memo.Text = "分類: $($combo.SelectedItem.分類) / 期限タイプ: $($combo.SelectedItem.期限タイプ)"
    }

    $btnCancel.Add_Click({
            $window.DialogResult = $false
            $window.Close()
        })
    $btnOk.Add_Click({
            if (-not $combo.SelectedItem) {
                Show-Toast "スケジュールを選択してください"
                return
            }
            $window.DialogResult = $true
            $window.Close()
        })

    if ($window.ShowDialog() -eq $true) {
        return $combo.SelectedItem
    }

    return $null
}
function Add-GanttFixedColumns {
    $fixedCellStyle = New-GanttFixedCellStyle

    $statusColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
    $statusColumn.Header = "ステータス"
    $statusColumn.Width = $COL_WIDTH_STATUS
    $statusColumn.CellTemplate = $Form.Resources["BadgeStatusTemplate"]
    $statusColumn.CellStyle = $fixedCellStyle
    $GridGantt.Columns.Add($statusColumn)

    $categoryColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
    $categoryColumn.Header = "分類"
    $categoryColumn.Width = $COL_WIDTH_CAT
    $categoryColumn.CellTemplate = $Form.Resources["BadgeCategoryTemplate"]
    $categoryColumn.CellStyle = $fixedCellStyle
    $GridGantt.Columns.Add($categoryColumn)

    $titleColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
    $titleColumn.Header = "スケジュール名"
    $titleColumn.SortMemberPath = "スケジュール名"
    $titleColumn.Width = $COL_WIDTH_TITLE
    $titleColumn.CellStyle = $fixedCellStyle
    $titleColumn.HeaderStyle = New-GanttHeaderStyle -Background $CLR_TITLE_CELL_BG
    $titleColumn.CellTemplate = New-GanttTitleCellTemplate
    $GridGantt.Columns.Add($titleColumn)
}

function Add-GanttDateColumn {
    param(
        [datetime]$Date,
        [string]$TodayText
    )

    $dateText = $Date.ToString("yyyy/MM/dd")
    $cellBackground = Get-GanttDateCellBackground -Date $Date -TodayText $TodayText
    $headerTheme = Get-GanttDateHeaderTheme -Date $Date -TodayText $TodayText

    $column = New-Object System.Windows.Controls.DataGridTemplateColumn
    $column.Header = $Date.ToString("d`n(ddd)")
    $column.SortMemberPath = $dateText
    $column.HeaderStyle = New-GanttHeaderStyle -Background $headerTheme.Background -Foreground $headerTheme.Foreground
    $column.CellStyle = New-GanttDateCellStyle -DateText $dateText -CellBackground $cellBackground
    $column.CellTemplate = New-GanttDateCellTemplate -DateText $dateText

    $GridGantt.Columns.Add($column)
}

function Build-GanttColumns {
    param($startDate, $days)

    $GridGantt.Columns.Clear()
    Add-GanttFixedColumns

    $todayText = (Get-Date).ToString("yyyy/MM/dd")

    for ($i = 0; $i -lt $days; $i++) {
        Add-GanttDateColumn -Date ($startDate.AddDays($i)) -TodayText $todayText
    }
}

# 右クリックハンドラは廃止されました

function Refresh-UI {
    $data = Get-AllData
    
    # === 同期シート・作業ログ ===
    $GridSync.ItemsSource = [System.Collections.ArrayList]@($data.parsed)
    
    $displayLogs = ConvertTo-DisplayWorkLogs -Logs $data.logs -Tasks $data.parsed
    $GridLogs.ItemsSource = [System.Collections.ArrayList]@($displayLogs)
    
    # === ガントチャート ===
    $startDate = $GanttDatePicker.SelectedDate
    if ($startDate -eq $null) { $startDate = (Get-Date).AddDays(-7) }
    $days = [int]($GanttDaysCombo.Text)
    if ($days -eq 0) { $days = 35 }

    $suppressWeekendScheduleHighlight = ($ChkSuppressWeekendHighlight -and $ChkSuppressWeekendHighlight.IsChecked)

    Build-GanttColumns -startDate $startDate -days $days
    $GridGantt.ItemsSource = ConvertTo-GanttDataView -Tasks $data.parsed -Logs $data.logs -StartDate $startDate -Days $days -SuppressWeekendScheduleHighlight $suppressWeekendScheduleHighlight
}

function Invoke-OutlookSync {
    param(
        [string]$SuccessPrefix = "同期完了"
    )

    $previousContent = $BtnSync.Content
    $BtnSync.IsEnabled = $false
    $BtnSync.Content = "同期中..."

    try {
        $syncData = Get-OutlookScheduleSyncData -TargetEmail $TARGET_OUTLOOK_EMAIL
        Write-JsonData -Path $TasksFile -Data $syncData.Tasks
        Refresh-UI

        Show-Toast "$SuccessPrefix ($($syncData.Count) 件) - アカウント: $($syncData.Account)"
        return $true
    }
    catch {
        $msg = $_.Exception.Message
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - 同期エラー: $msg" | Out-File (Join-Path $ScriptPath "error.log") -Append -Encoding UTF8
        Show-Toast "同期失敗: $msg"
        return $false
    }
    finally {
        $BtnSync.IsEnabled = $true
        $BtnSync.Content = $previousContent
    }
}

function Handle-GanttGridDoubleClick {
    if (-not $GridGantt.CurrentCell.IsValid) {
        return
    }

    $col = $GridGantt.CurrentColumn
    $item = $GridGantt.CurrentCell.Item
    $title = $item["スケジュール名"]
    $taskObj = $item["OriginalTask"]

    if ($col.Header -eq "スケジュール名") {
        if ($taskObj) {
            if ($ChkLogMode.IsChecked) {
                Invoke-LogForm -task $taskObj
            }
            else {
                $memo = $item["メモ"]
                if (-not [string]::IsNullOrWhiteSpace($memo)) {
                    Invoke-ViewForm -title "メモ - $title" -text $memo -Width 350 -Height 320
                }
            }
        }
    }
    elseif ($col -is [System.Windows.Controls.DataGridTemplateColumn] -and $col.SortMemberPath) {
        $dateText = $col.SortMemberPath
        if ($ChkLogMode.IsChecked -and $taskObj) {
            Invoke-LogForm -task $taskObj -defaultDate $dateText
            return
        }

        $text = $item["${dateText}_TT"]
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            Invoke-ViewForm -title "作業ログ ($dateText) - $title" -text $text -Width 350 -Height 320
        }
    }
}

function Handle-LogsGridDoubleClick {
    if (-not $GridLogs.CurrentItem) {
        return
    }

    $logObj = $GridLogs.CurrentItem
    $data = Get-AllData
    $taskObj = $data.parsed | Where-Object { $_.uid -eq $logObj.uid } | Select-Object -First 1
    if ($taskObj) {
        Invoke-LogForm -task $taskObj -editLog $logObj
    }
}

function Get-DisplayedGanttTasks {
    $tasks = @()
    if (-not $GridGantt -or -not $GridGantt.ItemsSource) {
        return $tasks
    }

    foreach ($row in $GridGantt.ItemsSource) {
        $task = $row["OriginalTask"]
        if ($task) {
            $tasks += $task
        }
    }

    return $tasks
}

function Complete-SelectedSchedule {
    $task = Invoke-CompleteSchedulePicker -Tasks (Get-DisplayedGanttTasks)
    if (-not $task) {
        return
    }

    $setCompleted = ($task.ステータス -ne "完了")
    Set-OutlookAppointmentCompletion -EntryId $task.uid -Completed $setCompleted
    $schedules = Read-JsonArray -Path $TasksFile
    $schedules = Set-CachedScheduleCompletion -Schedules $schedules -Uid $task.uid -Completed $setCompleted
    Write-JsonData -Path $TasksFile -Data $schedules
    if ($setCompleted) {
        Show-Toast "完了にしました: $($task.タイトル)"
    }
    else {
        Show-Toast "非完了に戻しました: $($task.タイトル)"
    }
    Invoke-OutlookSync -SuccessPrefix "完了切替後の同期完了"
}

function Edit-SelectedSchedule {
    $task = Invoke-ScheduleEditPicker -Tasks (Get-DisplayedGanttTasks)
    if (-not $task) {
        return
    }

    Invoke-EditAppointmentForm -Task $task
}
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
            Complete-SelectedSchedule
        }
        catch {
            Show-Toast "完了切替に失敗: $($_.Exception.Message)"
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

$Form.Add_SizeChanged({
        if ($Form.ActualWidth -lt 980) {
            $ChkLogMode.Content = "ログ"
            $ChkSuppressWeekendHighlight.Content = "土日"
            $ChkTopmost.Content = "前面"
        }
        else {
            $ChkLogMode.Content = "作業ログ入力モード"
            $ChkSuppressWeekendHighlight.Content = "土日の予定色を抑制"
            $ChkTopmost.Content = "最前面"
        }

        if ($Form.ActualWidth -lt 825) {
            [System.Windows.Controls.Grid]::SetRow($ToolbarSecondaryGroup, 1)
            [System.Windows.Controls.Grid]::SetColumn($ToolbarSecondaryGroup, 0)
            $ToolbarSecondaryGroup.Margin = "0,6,0,0"
        }
        else {
            [System.Windows.Controls.Grid]::SetRow($ToolbarSecondaryGroup, 0)
            [System.Windows.Controls.Grid]::SetColumn($ToolbarSecondaryGroup, 1)
            $ToolbarSecondaryGroup.Margin = "0"
        }
    })

$Form.Add_Closing({
        Save-WindowPlacement -Window $Form -Settings $AppSettings
    })

# INITIAL LOAD
Refresh-UI
$Form.ShowDialog()

