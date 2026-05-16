# --- Events ---
$BtnSync.Add_Click({
        $BtnSync.IsEnabled = $false
        $BtnSync.Content = "同期中..."
        try {
            $syncData = Get-OutlookScheduleSyncData -TargetEmail $TARGET_OUTLOOK_EMAIL
            Write-JsonData -Path $TasksFile -Data $syncData.Tasks
            Refresh-UI
        
            Show-Toast "同期完了 ($($syncData.Count) 件) - アカウント: $($syncData.Account)"
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

