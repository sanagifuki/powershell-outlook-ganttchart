Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$ScriptPath = $PSScriptRoot
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
$CLR_GANTT_PAST_BG = "#ada1cc"    # 過去の日付: 薄紫色

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
$COL_WIDTH_CAT    = 72          # 「分類」列の幅
$COL_WIDTH_DATE   = 72          # 「日付」列の幅
$COL_WIDTH_TIME   = 43          # 「時間」列の幅
$COL_WIDTH_MEMO   = 250         # 「メモ」列の幅
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
$CLR_CAT_IMPORTANT_BG = "#FFCFC9"; $CLR_CAT_IMPORTANT_FG = "#c22e2c" # 重要
$CLR_CAT_CHORE_BG = "#FFE5A0"; $CLR_CAT_CHORE_FG = "#5f4e2e" # 雑務
$CLR_CAT_PAY_BG = "#bee4ca"; $CLR_CAT_PAY_FG = "#166534" # 業務
$CLR_CAT_PROC_BG = "#BFE1F6"; $CLR_CAT_PROC_FG = "#1A5FAF" # 手続き
$CLR_CAT_RES_BG = "#E6CFF2"; $CLR_CAT_RES_FG = "#8F6EAF" # 調査
$CLR_CAT_SKILL_BG = "#FFC8AA"; $CLR_CAT_SKILL_FG = "#874B17" # スキルアップ
$CLR_CAT_CORP_BG = "#a8d8f5"; $CLR_CAT_CORP_FG = "#1A5FAF" # 会社対応

function Get-AllData {
    $tasks = if (Test-Path $TasksFile) { Get-Content $TasksFile -Raw -Encoding UTF8 | ConvertFrom-Json } else { @() }
    $logs = if (Test-Path $LogsFile) { Get-Content $LogsFile -Raw -Encoding UTF8 | ConvertFrom-Json } else { @() }
    $status = @{} # No longer used
    
    $parsed = foreach ($t in $tasks) {
        $rawTitle = $t.title
        $st = "未着手"
        $statusFixed = $false
        
        if ($t.categories -like "*完了*") { $st = "完了"; $statusFixed = $true }
        elseif ($t.categories -like "*廃止*") { $st = "廃棄"; $statusFixed = $true }
        
        $type = ""
        if ($rawTitle -match "✕") { $type = "絶対期限" }
        elseif ($rawTitle -match "◆") { $type = "推奨期限" }
        elseif ($rawTitle -match "★") { 
            $type = "参照用"
            if (-not $statusFixed) { $st = "表示" }
        }
        elseif ($rawTitle -match "◇") { $type = "目安期限" }
        elseif ($rawTitle -match "▶") { $type = "予定日" }

        $cat = ""
        if ($rawTitle -match "[\[［](.+?)[\]］]") { $cat = $Matches[1] }
        $cleanTitle = $rawTitle -replace "[\[［](.+?)[\]］]", ""

        [PSCustomObject]@{
            uid = $t.uid; タイトル = $cleanTitle; ステータス = $st; 期限タイプ = $type; 分類 = $cat; 
            開始日 = $t.start; 終了日 = $t.end; 開始時間 = $t.startTime; 終了時間 = $t.endTime; メモ = (Format-Memo $t.memo)
        }
    }
    return @{ parsed = @($parsed); logs = @($logs); status = $status }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="スケジュール管理システム" Height="400" Width="675" MinWidth="675" MinHeight="400"
        Background="#F5F5F5" Foreground="#333333" FontFamily="Noto Sans JP, Meiryo, Yu Gothic UI, MS Gothic" FontSize="11"
        WindowStartupLocation="CenterScreen">
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
            <Setter Property="FontFamily" Value="Noto Sans JP, Meiryo, Yu Gothic UI, MS Gothic"/>
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
            <Setter Property="CornerRadius" Value="4"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1,0,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Style.Triggers>
                <DataTrigger Binding="{Binding ステータス}" Value="未着手"><Setter Property="Background" Value="$CLR_STA_UNSTARTED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_UNSTARTED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="完了"><Setter Property="Background" Value="$CLR_STA_COMPLETED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_COMPLETED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="廃棄"><Setter Property="Background" Value="$CLR_STA_DISCARDED_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_DISCARDED_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding ステータス}" Value="表示"><Setter Property="Background" Value="$CLR_STA_DISPLAY_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_STA_DISPLAY_FG"/></DataTrigger>
            </Style.Triggers>
        </Style>
        <!-- Type Badges -->
        <Style x:Key="BadgeType" TargetType="Border">
            <Setter Property="CornerRadius" Value="4"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1,0,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
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
            <Setter Property="CornerRadius" Value="4"/>
            <Setter Property="Padding" Value="4,0"/>
            <Setter Property="Margin" Value="1,1,0,1"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Style.Triggers>
                <DataTrigger Binding="{Binding 分類}" Value="重要"><Setter Property="Background" Value="$CLR_CAT_IMPORTANT_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_IMPORTANT_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="雑務"><Setter Property="Background" Value="$CLR_CAT_CHORE_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_CHORE_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="支払い"><Setter Property="Background" Value="$CLR_CAT_PAY_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_PAY_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="業務"><Setter Property="Background" Value="$CLR_CAT_PAY_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_PAY_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="手続き"><Setter Property="Background" Value="$CLR_CAT_PROC_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_PROC_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="調査"><Setter Property="Background" Value="$CLR_CAT_RES_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_RES_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="スキルアップ"><Setter Property="Background" Value="$CLR_CAT_SKILL_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_SKILL_FG"/></DataTrigger>
                <DataTrigger Binding="{Binding 分類}" Value="会社対応"><Setter Property="Background" Value="$CLR_CAT_CORP_BG"/><Setter Property="TextBlock.Foreground" Value="$CLR_CAT_CORP_FG"/></DataTrigger>
            </Style.Triggers>
        </Style>

        <DataTemplate x:Key="BadgeStatusTemplate">
            <Border Style="{StaticResource BadgeStatus}"><TextBlock Text="{Binding ステータス}" HorizontalAlignment="Center"/></Border>
        </DataTemplate>
        <DataTemplate x:Key="BadgeCategoryTemplate">
            <Border Style="{StaticResource BadgeCategory}"><TextBlock Text="{Binding 分類}" HorizontalAlignment="Center"/></Border>
        </DataTemplate>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <Border Background="#FFFFFF" Padding="10,6" BorderThickness="0,0,0,1" BorderBrush="$CLR_BORDER">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Button Name="BtnSync" Content="Outlook同期" Padding="12,4" Background="#1A73E8" Foreground="White" BorderThickness="0" Margin="0,0,20,0" FontWeight="SemiBold" Cursor="Hand"/>
                <TextBlock Text="ガント開始日:" VerticalAlignment="Center" Margin="0,0,6,0" Foreground="#333333"/>
                <DatePicker Name="GanttDatePicker" Width="120" VerticalAlignment="Center" VerticalContentAlignment="Center" Margin="0,0,20,0"/>
                <TextBlock Text="表示日数:" VerticalAlignment="Center" Margin="0,0,6,0" Foreground="#333333"/>
                <ComboBox Name="GanttDaysCombo" Width="60" VerticalAlignment="Center" SelectedIndex="1">
                    <ComboBoxItem Content="14"/>
                    <ComboBoxItem Content="35"/>
                    <ComboBoxItem Content="60"/>
                    <ComboBoxItem Content="90"/>
                    <ComboBoxItem Content="120"/>
                </ComboBox>
                <Button Name="BtnResetView" Content="表示リセット" Width="90" Height="24" Margin="10,0,0,0" Background="#F5F5F5" BorderBrush="$CLR_BORDER" Cursor="Hand"/>
                <CheckBox Name="ChkLogMode" Content="作業ログ入力モード" IsChecked="True" VerticalAlignment="Center" Margin="15,0,0,0" Foreground="#333333"/>
                <Button Name="BtnHelp" Content="？" Width="22" Height="22" Margin="10,0,0,0" Background="#F0F0F0" Foreground="#555555" BorderBrush="$CLR_BORDER" Cursor="Hand" ToolTip="留意事項を表示します"/>
            </StackPanel>
        </Border>
        
        <TabControl Name="MainTab" Grid.Row="1" Background="Transparent" BorderThickness="1" BorderBrush="$CLR_BORDER" Margin="6" Padding="0">
            <TabItem Header="🔍 カレンダー同期">
                <DataGrid Name="GridSync" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" SelectionUnit="Cell" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.CanContentScroll="False">
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
                        <DataGridTemplateColumn Header="分類" Width="$COL_WIDTH_CAT">
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <Border Style="{StaticResource BadgeCategory}"><TextBlock Text="{Binding 分類}" HorizontalAlignment="Center"/></Border>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
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
                        <DataGridTemplateColumn Header="メモ" SortMemberPath="メモ" Width="$COL_WIDTH_MEMO">
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
                        <DataGridTextColumn Header="作業時間" Binding="{Binding displayTime}" Width="$COL_WIDTH_TIME">
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

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Form = [System.Windows.Markup.XamlReader]::Load($reader)

# Define controls
$BtnSync = $Form.FindName("BtnSync")
$GanttDatePicker = $Form.FindName("GanttDatePicker")
$GanttDaysCombo = $Form.FindName("GanttDaysCombo")
$BtnResetView = $Form.FindName("BtnResetView")
$ChkLogMode = $Form.FindName("ChkLogMode")
$BtnHelp = $Form.FindName("BtnHelp")
$GridSync = $Form.FindName("GridSync")
$GridGantt = $Form.FindName("GridGantt")
$GridLogs = $Form.FindName("GridLogs")
$StatusMsg = $Form.FindName("StatusMsg")

# Set Default Dates
$GanttDatePicker.SelectedDate = (Get-Date).AddDays(-7)

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

function Invoke-ViewForm {
    param($title, $text)
    [xml]$vXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="詳細" Height="500" Width="650"
            WindowStartupLocation="CenterOwner" Background="#F0F0F0" FontFamily="Noto Sans JP" FontSize="12"
            ResizeMode="CanResizeWithGrip">
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

function Invoke-LogForm {
    param($task, $defaultDate, $editLog)
    
    [xml]$dXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="ログ入力: $($task.タイトル -replace '&','&amp;')" Height="320" Width="350"
            Background="#F5F5F5" Foreground="#333333" FontFamily="Noto Sans JP" FontSize="11"
            WindowStartupLocation="CenterOwner" ResizeMode="CanResize" MinWidth="320" MinHeight="300">
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
    $d = [System.Windows.Markup.XamlReader]::Load($dReader)
    $d.Owner = $Form

    $dpDate = $d.FindName("dpDate")
    $txtTime = $d.FindName("txtTime")
    $txtContent = $d.FindName("txtContent")
    $btnSave = $d.FindName("btnSave")
    
    if ($editLog) {
        $dpDate.Text = $editLog.date
        if ($editLog.time) { $txtTime.Text = ($editLog.time -replace '分$', '') }
        $txtContent.Text = $editLog.content
    }
    elseif ($defaultDate) {
        $dpDate.Text = $defaultDate
    }
    else {
        $dpDate.Text = (Get-Date).ToString("yyyy/MM/dd")
    }
    
    $btnSave.Add_Click({
            [array]$logs = if (Test-Path $LogsFile) { Get-Content $LogsFile -Raw -Encoding UTF8 | ConvertFrom-Json }else { @() }
            $saveDate = if ($dpDate.SelectedDate) { $dpDate.SelectedDate.ToString("yyyy/MM/dd") } else { $dpDate.Text }
        
            $newLog = [PSCustomObject]@{ uid = $task.uid; date = $saveDate; content = $txtContent.Text; time = $txtTime.Text }
        
            if ($editLog) {
                $idx = -1
                for ($i = 0; $i -lt $logs.Count; $i++) {
                    if ($logs[$i].uid -eq $editLog.uid -and $logs[$i].date -eq $editLog.date -and $logs[$i].time -eq $editLog.time -and $logs[$i].content -eq $editLog.content) {
                        $idx = $i
                        break
                    }
                }
                if ($idx -ge 0) {
                    $logs[$idx] = $newLog
                }
                else {
                    $logs += $newLog
                }
            }
            else {
                $logs += $newLog
            }
            $logs | ConvertTo-Json | Out-File $LogsFile -Encoding UTF8
        
            $d.DialogResult = $true
            $d.Close()
        })
    
    if ($d.ShowDialog() -eq $true) {
        Refresh-UI
        Show-Toast "保存しました"
    }
}

function Build-GanttColumns {
    param($startDate, $days)
    
    $GridGantt.Columns.Clear()
    
    $fixedCellStyle = [System.Windows.Markup.XamlReader]::Parse(@"
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
    
    # 1. ステータス
    $col1 = New-Object System.Windows.Controls.DataGridTemplateColumn
    $col1.Header = "ステータス"
    $col1.Width = $COL_WIDTH_STATUS
    $col1.CellTemplate = $Form.Resources["BadgeStatusTemplate"]
    $col1.CellStyle = $fixedCellStyle
    $GridGantt.Columns.Add($col1)
    
    # 2. 分類
    $col2 = New-Object System.Windows.Controls.DataGridTemplateColumn
    $col2.Header = "分類"
    $col2.Width = $COL_WIDTH_CAT
    $col2.CellTemplate = $Form.Resources["BadgeCategoryTemplate"]
    $col2.CellStyle = $fixedCellStyle
    $GridGantt.Columns.Add($col2)
    
    # 3. スケジュール名
    $col3 = New-Object System.Windows.Controls.DataGridTemplateColumn
    $col3.Header = "スケジュール名"
    $col3.SortMemberPath = "スケジュール名"
    $col3.Width = $COL_WIDTH_TITLE
    $col3.CellStyle = $fixedCellStyle
    # ヘッダー設定（同期タブと統一）
    $col3HeaderStyle = New-Object System.Windows.Style -ArgumentList ([System.Windows.Controls.Primitives.DataGridColumnHeader])
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BackgroundProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($CLR_TITLE_CELL_BG))))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::HorizontalContentAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::PaddingProperty, [System.Windows.Thickness]::new(6, 4, 6, 4))))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderThicknessProperty, [System.Windows.Thickness]::new(0, 0, 1, 1))))
    $col3HeaderStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderBrushProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($CLR_BORDER))))
    $col3.HeaderStyle = $col3HeaderStyle

    $col3.CellTemplate = [System.Windows.Markup.XamlReader]::Parse(@"
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
    $GridGantt.Columns.Add($col3)
    
    $todayStr = (Get-Date).ToString("yyyy/MM/dd")

    # 日付カラム追加
    for ($i = 0; $i -lt $days; $i++) {
        $d = $startDate.AddDays($i)
        $dStr = $d.ToString("yyyy/MM/dd")
        $isToday = ($dStr -eq $todayStr)
        $isWeekend = ($d.DayOfWeek -eq 'Saturday' -or $d.DayOfWeek -eq 'Sunday')
        $isOddMonth = ($d.Month % 2 -eq 1)
        
        # --- Determine cell background color ---
        $cellBg = $CLR_GANTT_EVEN_BG
        if ($isToday) {
            $cellBg = $CLR_GANTT_TODAY_BG
        }
        elseif ($isWeekend) {
            if ($isOddMonth) { $cellBg = $CLR_GANTT_WE_ODD_BG }
            else { $cellBg = $CLR_GANTT_WE_EVEN_BG }
        }
        elseif ($isOddMonth) {
            $cellBg = $CLR_GANTT_ODD_BG
        }
        
        # --- Determine header style ---
        $headerBg = $CLR_GANTT_HDR_DEFAULT_BG
        $headerFg = $CLR_GANTT_HDR_FG
        if ($isToday) {
            $headerBg = $CLR_GANTT_HDR_TODAY_BG
            $headerFg = $CLR_GANTT_HDR_TODAY_FG
        }
        elseif ($isOddMonth) {
            $headerBg = $CLR_GANTT_HDR_ODD_BG
        }
        
        $col = New-Object System.Windows.Controls.DataGridTemplateColumn
        $col.Header = $d.ToString("d`n(ddd)")
        $col.SortMemberPath = $dStr
        
        # Apply header style
        $headerStyle = New-Object System.Windows.Style([System.Windows.Controls.Primitives.DataGridColumnHeader])
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BackgroundProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($headerBg))))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::ForegroundProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($headerFg))))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::PaddingProperty, [System.Windows.Thickness]::new(6, 4, 6, 4))))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::HorizontalContentAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.TextBlock]::TextAlignmentProperty, [System.Windows.TextAlignment]::Center)))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::VerticalContentAlignmentProperty, [System.Windows.VerticalAlignment]::Center)))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderThicknessProperty, [System.Windows.Thickness]::new(0, 0, 1, 1))))
        $headerStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderBrushProperty, [System.Windows.Media.BrushConverter]::new().ConvertFrom($CLR_BORDER))))
        $col.HeaderStyle = $headerStyle
        
        $cellStyleXaml = @"
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
    <Setter Property="Background" Value="$cellBg"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Style.Triggers>
        
        <!-- 枠線描画 -->
        <Trigger Property="IsSelected" Value="True">
            <Setter Property="BorderBrush" Value="$CLR_SELECTED_BORDER"/>
        </Trigger>
        
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="$CLR_STA_OVERDUE_BG">
            <Setter Property="Background" Value="$CLR_STA_OVERDUE_BG"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="$CLR_STA_OVERDUE_ABS_BG">
            <Setter Property="Background" Value="$CLR_STA_OVERDUE_ABS_BG"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="$CLR_GANTT_PAST_BG">
            <Setter Property="Background" Value="$CLR_GANTT_PAST_BG"/>
        </DataTrigger>
        
        <!-- 記号の背景色 -->
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="#FF9900">
            <Setter Property="Background" Value="#FF9900"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="#EA4335">
            <Setter Property="Background" Value="#EA4335"/>
        </DataTrigger>
        <DataTrigger Binding="{Binding [${dStr}_Bg]}" Value="$CLR_ROW_DISPLAY">
            <Setter Property="Background" Value="$CLR_ROW_DISPLAY"/>
        </DataTrigger>
    </Style.Triggers>
</Style>
"@
        $col.CellStyle = [System.Windows.Markup.XamlReader]::Parse($cellStyleXaml)

        # Style definition for dynamic Gantt cells (ToolTip via DataTemplate)
        $templateXaml = @"
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Grid Background="Transparent" ToolTipService.IsEnabled="{Binding [${dStr}_Vis]}">
        <Grid.ToolTip>
            <ToolTip>
                <TextBlock Text="{Binding [${dStr}_TT]}" TextWrapping="Wrap" MaxWidth="300" />
            </ToolTip>
        </Grid.ToolTip>
        <TextBlock Text="{Binding [$dStr]}" 
                   HorizontalAlignment="Center" VerticalAlignment="Center" 
                   FontWeight="Bold" FontSize="11" Foreground="$CLR_SYMBOL_FG"/>
        <!-- Combined Info Mark (Top-Right Blue) -->
        <Polygon Points="7,0 7,7 0,0" Fill="#0078D7" HorizontalAlignment="Right" VerticalAlignment="Top" 
                 Visibility="{Binding [${dStr}_InfoVis]}"/>
    </Grid>
</DataTemplate>
"@
        # テンプレート適用
        $col.CellTemplate = [System.Windows.Markup.XamlReader]::Parse($templateXaml)
        $GridGantt.Columns.Add($col)
    }
}

# 右クリックハンドラは廃止されました

function Refresh-UI {
    $data = Get-AllData
    
    # === 同期シート・作業ログ ===
    $GridSync.ItemsSource = [System.Collections.ArrayList]@($data.parsed)
    
    # ログ表示用のデータを準備（最新順にソートし、タイトルを紐付け、表示時間を整形）
    $displayLogs = foreach ($l in ($data.logs | Sort-Object date -Descending)) {
        $taskEntry = $data.parsed | Where-Object { $_.uid -eq $l.uid } | Select-Object -First 1
        $title = if ($taskEntry) { $taskEntry.タイトル } else { "不明なスケジュール" }
        
        # タイトルと表示時間をプロパティとして追加
        $l | Add-Member -MemberType NoteProperty -Name "title" -Value $title -Force
        $timeStr = if ($l.time) { if ($l.time -match '分$') { $l.time } else { "$($l.time)分" } } else { "0分" }
        $l | Add-Member -MemberType NoteProperty -Name "displayTime" -Value $timeStr -Force -PassThru
    }
    $GridLogs.ItemsSource = [System.Collections.ArrayList]@($displayLogs)
    
    # === ガントチャート ===
    $startDate = $GanttDatePicker.SelectedDate
    if ($startDate -eq $null) { $startDate = (Get-Date).AddDays(-7) }
    $days = [int]($GanttDaysCombo.Text)
    if ($days -eq 0) { $days = 35 }

    Build-GanttColumns -startDate $startDate -days $days
    
    $todayStr = (Get-Date).ToString("yyyy/MM/dd")
    $dt = New-Object System.Data.DataTable
    [void]$dt.Columns.Add("ステータス"); [void]$dt.Columns.Add("分類"); [void]$dt.Columns.Add("スケジュール名"); [void]$dt.Columns.Add("メモ"); [void]$dt.Columns.Add("OriginalTask", [object]); [void]$dt.Columns.Add("MemoVis");
    for ($i = 0; $i -lt $days; $i++) { 
        $tdateStr = $startDate.AddDays($i).ToString("yyyy/MM/dd")
        [void]$dt.Columns.Add($tdateStr)
        [void]$dt.Columns.Add("${tdateStr}_TT")
        [void]$dt.Columns.Add("${tdateStr}_Vis", [bool])
        [void]$dt.Columns.Add("${tdateStr}_Bg")
        [void]$dt.Columns.Add("${tdateStr}_InfoVis")
    }
    
    # A4: フィルタリング
    $taskArray = $data.parsed
    
    # 完了・廃棄は直近15件ずつ保持する（配列として確実に取得するために @() を使用）
    $compKeep = @($taskArray | Where-Object { $_.ステータス -eq "完了" } | Select-Object -Last 15 | ForEach-Object { $_.uid })
    $discKeep = @($taskArray | Where-Object { $_.ステータス -eq "廃棄" } | Select-Object -Last 15 | ForEach-Object { $_.uid })
    $uidsToKeep = $compKeep + $discKeep
    
    foreach ($p in $taskArray) {
        # 完了・廃棄ステータスの制限（直近のみ表示）
        if (($p.ステータス -eq "完了" -or $p.ステータス -eq "廃棄") -and $uidsToKeep -notcontains $p.uid) { continue }
        
        # 未着手スケジュールのフィルタリング（期限が遠すぎるものは非表示: TODAY + 44日）
        if ($p.ステータス -eq "未着手" -and $p.終了日 -ne "") {
            $endLimitStr = (Get-Date).AddDays(44).ToString("yyyy/MM/dd")
            if ($p.終了日 -gt $endLimitStr) { continue }
        }
        
        $row = $dt.NewRow()
        $row["ステータス"] = $p.ステータス; $row["分類"] = $p.分類; $row["スケジュール名"] = $p.タイトル; $row["メモ"] = $p.メモ; $row["OriginalTask"] = $p
        $row["MemoVis"] = if (-not [string]::IsNullOrWhiteSpace($p.メモ) -and $p.メモ -ne "") { "Visible" } else { "Collapsed" }
        
        $pLogs = @($data.logs | Where-Object { $_.uid -eq $p.uid }) 
        $lastWorkDate = ""
        if ($pLogs.Count -gt 0) {
            $lastWorkDate = ($pLogs | Sort-Object date -Descending)[0].date
        }
        
        for ($i = 0; $i -lt $days; $i++) {
            $dStr = $startDate.AddDays($i).ToString("yyyy/MM/dd")
            $hasLog = @($pLogs | Where-Object { $_.date -eq $dStr }).Count -gt 0
            $inPeriod = ($p.開始日 -ne "" -and $p.終了日 -ne "" -and $dStr -ge $p.開始日 -and $dStr -le $p.終了日)
            if ($p.開始日 -eq "" -and $p.終了日 -ne "" -and $dStr -eq $p.終了日) { $inPeriod = $true }

            $sym = ""
            $deadline = $p.終了日
            if ($p.期限タイプ -eq "絶対期限" -and $p.終了日 -ne "") { 
                try { $deadline = ([datetime]$p.終了日).AddDays(1).ToString("yyyy/MM/dd") } catch {}
            }
            
            if ($p.期限タイプ -eq "参照用") {
                if ($inPeriod -or $dStr -eq $deadline) { $sym = "★" }
            }
            else {
                if ($hasLog) {
                    if ($p.期限タイプ -ne "予定日" -and $p.ステータス -eq "完了" -and $dStr -eq $lastWorkDate) {
                        $sym = "◉"
                    }
                    elseif ($p.期限タイプ -eq "予定日" -and $dStr -eq $deadline) {
                        $sym = "▶"
                    }
                    elseif ($inPeriod) {
                        $sym = "■"
                    }
                    else {
                        $sym = "▲"
                    }
                }
                else {
                    if ($p.期限タイプ -eq "絶対期限" -and $dStr -eq $deadline) {
                        $sym = "✕"
                    }
                    elseif ($p.期限タイプ -eq "予定日" -and $dStr -eq $deadline) {
                        $sym = "▷"
                    }
                    elseif ($inPeriod) {
                        $sym = "□"
                    }
                    else {
                        if ($p.ステータス -ne "完了" -and $deadline -ne "" -and $dStr -gt $deadline -and $dStr -lt $todayStr) {
                            if ($p.期限タイプ -ne "予定日") {
                                $sym = "・"
                            }
                            else {
                                $sym = "＊"
                            }
                        }
                    }
                }
                
                if ($dStr -eq $deadline -and $sym -ne "") {
                    if ($p.期限タイプ -eq "推奨期限") { $sym += "‼" }
                    if ($p.期限タイプ -eq "目安期限") { $sym += "❘" }
                }
            }
            
            # --- ToolTip Logs + Time Info Construction ---
            $logText = ""
            if ($hasLog -or ($dStr -eq $deadline -and ($p.開始時間 -ne "" -or $p.終了時間 -ne ""))) {
                $timeInfo = ""
                if ($dStr -eq $deadline) {
                    if ($p.開始時間 -ne "" -and $p.終了時間 -ne "") { $timeInfo = "$($p.開始時間)～$($p.終了時間)`n`n" }
                    elseif ($p.開始時間 -eq "" -and $p.終了時間 -ne "") { $timeInfo = "～$($p.終了時間)`n`n" }
                    elseif ($p.終了時間 -eq "" -and $p.開始時間 -ne "") { $timeInfo = "$($p.開始時間)～`n`n" }
                }

                $logEntries = @()
                if ($hasLog) {
                    $logsForDay = $pLogs | Where-Object { $_.date -eq $dStr }
                    foreach ($l in $logsForDay) {
                        $lTime = if ($l.time) { if ($l.time -match '分$') { $l.time } else { "$($l.time)分" } } else { "0分" }
                        $logEntries += "作業時間：$lTime`n$($l.content)"
                    }
                }
                
                $logJoin = $logEntries -join "`n`n"
                $logText = $timeInfo + $logJoin
                $logText = $logText.Trim()
            }
            
            $bg = "Transparent"
            # 今日より前の日付（過去）を紫色にする
            if ($dStr -lt $todayStr) { $bg = $CLR_GANTT_PAST_BG }

            if ($sym -ne "") {
                if ($p.ステータス -eq "完了") {
                    $bg = "Transparent"
                }
                elseif ($sym -match "✕") {
                    $bg = "#EA4335" # Red
                }
                elseif ($sym -eq "★") {
                    $bg = $CLR_ROW_DISPLAY # Yellow
                }
                elseif ($sym -eq "・") {
                    $bg = $CLR_STA_OVERDUE_BG # Light Pink
                }
                elseif ($sym -match "＊") {
                    $bg = $CLR_STA_OVERDUE_ABS_BG # Light Red
                }
                else {
                    $bg = "#FF9900" # Orange
                }
            }
            
            $row[$dStr] = $sym
            $row["${dStr}_Bg"] = $bg
            $row["${dStr}_TT"] = $logText
            $row["${dStr}_Vis"] = ($logText -ne "")
            
            # 統合コーナーマーク（右上・青）：ログがある場合、または時間設定（開始・終了）がある場合（期限日）
            $hasTimeOnThisDay = ($dStr -eq $deadline -and ($p.開始時間 -ne "" -or $p.終了時間 -ne ""))
            $row["${dStr}_InfoVis"] = if ($hasLog -or $hasTimeOnThisDay) { "Visible" } else { "Collapsed" }
        }
        [void]$dt.Rows.Add($row)
    }
    $GridGantt.ItemsSource = $dt.DefaultView
}

# --- Events ---
$BtnSync.Add_Click({
        $BtnSync.IsEnabled = $false
        $BtnSync.Content = "同期中..."
        try {
            $outlook = New-Object -ComObject Outlook.Application
            $namespace = $outlook.GetNamespace("MAPI")
        
            $calendar = $null
            $syncedAccount = "" # ★同期したアカウント名を保持する変数を追加

            # 先頭でメアドが指定されているかチェック
            if (-not [string]::IsNullOrWhiteSpace($TARGET_OUTLOOK_EMAIL)) {
                $targetStore = $null
                foreach ($store in $namespace.Stores) {
                    if ($store.DisplayName -eq $TARGET_OUTLOOK_EMAIL) {
                        $targetStore = $store
                        break
                    }
                }
                if ($null -eq $targetStore) {
                    throw "指定したアカウント（$TARGET_OUTLOOK_EMAIL）が見つかりません。"
                }
                $calendar = $targetStore.GetDefaultFolder(9)
                $syncedAccount = $targetStore.DisplayName # 指定したメアドを記録
            }
            else {
                # 指定がない場合は既定のアカウントを取得
                $calendar = $namespace.GetDefaultFolder(9)
                $syncedAccount = $calendar.Store.DisplayName # 既定アカウントのメアドを自動取得
            }

            $items = $calendar.Items
            $items.IncludeRecurrences = $true
            $items.Sort("[開始]")
        
            $filter = "[Start] >= '$((Get-Date).AddMonths(-36).ToString("MM/dd/yyyy"))' AND [End] <= '$((Get-Date).AddMonths(36).ToString("MM/dd/yyyy"))'"
            $count = 0
            $tasks = foreach ($item in $items.Restrict($filter)) {
                if ($item -isnot [System.__ComObject]) { continue }
                $count++
                [PSCustomObject]@{ uid = $item.EntryID; title = $item.Subject; start = $item.Start.ToString("yyyy/MM/dd"); end = if ($item.AllDayEvent) { $item.End.AddDays(-1).ToString("yyyy/MM/dd") }else { $item.End.ToString("yyyy/MM/dd") }; startTime = if ($item.AllDayEvent) { "" }else { $item.Start.ToString("HH:mm") }; endTime = if ($item.AllDayEvent) { "" }else { $item.End.ToString("HH:mm") }; memo = (Format-Memo $item.Body); categories = $item.Categories }
            }
            $tasks | ConvertTo-Json | Out-File $TasksFile -Encoding UTF8
            Refresh-UI
        
            # ★ここで下のステータスバーに同期したアカウント名を表示します！
            Show-Toast "同期完了 ($count 件) - アカウント: $syncedAccount"
        }
        catch {
            $msg = $_.Exception.Message
            "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - 同期エラー: $msg" | Out-File (Join-Path $ScriptPath "error.log") -Append -Encoding UTF8
            Show-Toast "同期失敗: $msg"
        }
        finally {
            $BtnSync.IsEnabled = $true
            $BtnSync.Content = "Outlook同期"
        }
    })

$GanttDatePicker.Add_SelectedDateChanged({ Refresh-UI })
$GanttDaysCombo.Add_DropDownClosed({ Refresh-UI })

$BtnHelp.Add_Click({
        $helpText = @"
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

■ デフォルトのカスタマイズ（コード編集）
・色の変更：スクリプト冒頭の「カラー設定」セクション（$CLR_...）で管理しています。
・列の幅：$COL_WIDTH_TITLE 等の変数で調整できます。

■ データ管理
・schedules.json：Outlook同期データ（キャッシュ）。
・logs.json：入力した作業ログ。
※バックアップ時はこの2ファイルを保存してください。
"@
        Invoke-ViewForm -title "留意事項・ヘルプ" -text $helpText
    })

$BtnResetView.Add_Click({
        # GridSync のリセット
        $GridSync.Columns | ForEach-Object { $_.Width = [System.Windows.Controls.DataGridLength]::Auto }
        if ($GridSync.Columns.Count -gt 1) { $GridSync.Columns[1].Width = $COL_WIDTH_TITLE } # スケジュール名
        if ($GridSync.Columns.Count -gt 2) { $GridSync.Columns[2].Width = $COL_WIDTH_STATUS } # ステータス
        if ($GridSync.Columns.Count -gt 3) { $GridSync.Columns[3].Width = $COL_WIDTH_TYPE }   # 期限タイプ
        if ($GridSync.Columns.Count -gt 4) { $GridSync.Columns[4].Width = $COL_WIDTH_CAT }    # 分類
        if ($GridSync.Columns.Count -gt 5) { $GridSync.Columns[5].Width = $COL_WIDTH_DATE }   # 開始日
        if ($GridSync.Columns.Count -gt 6) { $GridSync.Columns[6].Width = $COL_WIDTH_DATE }   # 終了日
        if ($GridSync.Columns.Count -gt 7) { $GridSync.Columns[7].Width = $COL_WIDTH_TIME }   # 開始
        if ($GridSync.Columns.Count -gt 8) { $GridSync.Columns[8].Width = $COL_WIDTH_TIME }   # 終了
        # 最後の列（メモ）を Star にする
        if ($GridSync.Columns.Count -gt 9) { $GridSync.Columns[9].Width = $COL_WIDTH_MEMO }   # メモ
        for ($i = 0; $i -lt $GridSync.Columns.Count; $i++) { $GridSync.Columns[$i].DisplayIndex = $i }

        # GridLogs のリセット
        if ($GridLogs.Columns.Count -gt 0) { $GridLogs.Columns[0].Width = $COL_WIDTH_TITLE } # 対象スケジュール名
        if ($GridLogs.Columns.Count -gt 1) { $GridLogs.Columns[1].Width = [System.Windows.Controls.DataGridLength]::new(1, [System.Windows.Controls.DataGridLengthUnitType]::Star) } # 作業内容
        for ($i = 0; $i -lt $GridLogs.Columns.Count; $i++) { $GridLogs.Columns[$i].DisplayIndex = $i }

        # GridGantt のリセット
        Build-GanttColumns
        Refresh-UI
        Show-Toast "表示をリセットしました"
    })

$GridSync.Add_MouseDoubleClick({
        if ($GridSync.CurrentColumn -and $GridSync.CurrentColumn.Header -eq "スケジュール名") {
            if ($GridSync.CurrentItem) { Invoke-LogForm -task $GridSync.CurrentItem }
        }
    })
$GridGantt.Add_MouseDoubleClick({
        if ($GridGantt.CurrentCell.IsValid) {
            $col = $GridGantt.CurrentColumn
            $item = $GridGantt.CurrentCell.Item
            $title = $item["スケジュール名"]
            $taskObj = $item["OriginalTask"]

            if ($col.Header -eq "スケジュール名") {
                # スケジュール名列の動作切替
                if ($taskObj) {
                    if ($ChkLogMode.IsChecked) {
                        Invoke-LogForm -task $taskObj
                    }
                    else {
                        $memo = $item["メモ"]
                        if (-not [string]::IsNullOrWhiteSpace($memo)) {
                            Invoke-ViewForm -title "メモ - $title" -text $memo
                        }
                    }
                }
            }
            elseif ($col -is [System.Windows.Controls.DataGridTemplateColumn] -and $col.SortMemberPath) {
                # 日付セル（記号列）ならログ表示画面を開く（従来通り）
                $dStr = $col.SortMemberPath
                $text = $item["${dStr}_TT"]
                if (-not [string]::IsNullOrWhiteSpace($text)) {
                    Invoke-ViewForm -title "作業ログ ($dStr) - $title" -text $text
                }
            }
        }
    })
$GridLogs.Add_MouseDoubleClick({
        if ($GridLogs.CurrentItem) {
            $logObj = $GridLogs.CurrentItem
            $data = Get-AllData
            $taskObj = $data.parsed | Where-Object { $_.uid -eq $logObj.uid } | Select-Object -First 1
            if ($taskObj) { Invoke-LogForm -task $taskObj -editLog $logObj }
        }
    })

# INITIAL LOAD
Refresh-UI
$Form.ShowDialog()

