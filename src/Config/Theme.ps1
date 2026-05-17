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

