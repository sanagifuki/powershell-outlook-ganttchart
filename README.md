# OutGantt

<p align="center">
  <img src="docs/header.png" alt="OutGantt">
</p>

Outlook の予定を取得し、作業ログと合わせてガントチャート表示する PowerShell/WPF アプリ。
会社PCに単一ファイルで持ち出せることを重視しつつ、開発時は `src/` 配下の分割ファイルで編集できる構成にしている。

![ガントチャート画面](docs/screenshot-gantt-chart.png)

## 主な機能

- Outlook予定の同期
- 予定追加、予定編集
- ステータス切替: `未着手` / `完了` / `保留` / `廃棄`
- 作業ログの追加、編集、日付セルからの入力
- カレンダー同期、作業ログ、ガントチャートの3タブ表示
- 保留/廃棄/完了の表示・非表示切替
- 土日の予定色抑制、最前面表示、ウィンドウ位置復元
- `settings.json` / `categories.json` による設定変更
- `build.ps1` による持ち出し用単一ファイル生成

## 使い方

デスクトップ版 Outlook（Classic版）がインストールされ、アカウントがセットアップされている必要がある。

開発環境では次で起動する。

```powershell
.\run-dev.ps1
```

持ち出し用の単一ファイルを直接起動する場合は、PowerShell から `OutlookGantt.ps1` を実行する。

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\OutlookGantt.ps1"
```

コンソールを表示したくない場合は、`launchers/OutlookGantt.vbs` を `OutlookGantt.ps1` と同じフォルダに置き、VBS から起動する。ショートカットを作る場合も、この VBS から作成する。

直接 PowerShell のショートカットを作る場合の例:

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "<OutlookGantt.ps1のパス>"
```

## 画面操作

`予定` メニュー:
- `Outlook同期`: Outlook予定を取得して画面を更新する。
- `予定追加`: Outlookに新しい予定を追加する。追加後は自動で同期する。
- `予定編集`: 現在表示中の予定から選んで編集する。編集後は自動で同期する。
- `ステータス切替`: 現在表示中の予定から選んで `未着手` / `完了` / `保留` / `廃棄` を切り替える。変更後は自動で同期する。

`表示` メニュー:
- `表示リセット`: 列幅やスクロール位置を初期状態に戻す。
- `土日の予定色を抑制`: 土日列にある予定セルのオレンジ色だけを抑制する。
- `保留を非表示` / `廃棄を非表示` / `完了を非表示`: 対象ステータスを画面上から非表示にする。
- `最前面`: ウィンドウを最前面に固定する。

ダブルクリック操作:
- ガントチャートのスケジュール名: 作業ログ入力モードONなら作業ログ入力、OFFならメモ表示。
- ガントチャートの日付セル: 作業ログ入力モードONならその日付で作業ログ入力、OFFなら作業ログ詳細表示。
- 作業ログシート: 既存ログを編集する。

## ステータスと表示ルール

ステータスは Outlook のカテゴリーから判定する。

- `完了` カテゴリー: `完了`
- `保留` カテゴリー: `保留`
- `廃止` カテゴリー: `廃棄`
- 上記なし: `未着手`
- タイトルに `★` がある場合: `表示`

ガントチャートでは、表示を軽くするために次の自動フィルタを使う。

- `未着手` かつ終了日が `今日 + 44日` より先の予定は非表示。
- `完了` / `廃棄` はそれぞれ直近15件だけ表示。
- 表示メニューで非表示にしたステータスは、自動フィルタより前に除外。

カレンダー同期タブでは、表示メニューで非表示にしたステータスだけを除外する。

## タイトル記号

予定タイトルに含まれる記号で期限タイプを判定する。

- `★`: 参照用
- `✕`: 絶対期限
- `◆`: 推奨期限
- `◇`: 目安期限
- `▶`: 予定日

予定追加画面では、期限タイプと分類を選ぶとタイトルに対応する記号と分類が入る。

## 設定ファイル

`settings.json` と `categories.json` は、リポジトリルートまたは単一ファイルと同じフォルダに置く。
未配置の場合は、初回読み込み時に自動生成される。

`settings.json` の主な項目:

```json
{
  "ganttDefaultDays": 35,
  "ganttStartOffsetDays": -7,
  "logInputModeDefault": true,
  "suppressWeekendScheduleHighlightDefault": false,
  "topmostDefault": false,
  "hiddenStatusesDefault": [],
  "addAppointmentPrivateDefault": true,
  "addAppointmentShowAsFreeDefault": true,
  "addAppointmentTypeDefaultSymbol": "◆",
  "addAppointmentCategoryDefault": "業務",
  "rememberWindowPlacement": true,
  "windowWidth": 769,
  "windowHeight": 600,
  "windowMinWidth": 825,
  "windowMinHeight": 420,
  "windowLeft": null,
  "windowTop": null,
  "fontMain": "Noto Sans JP, Meiryo, Yu Gothic UI",
  "fontGantt": "Yu Gothic",
  "fontSizeMain": 11,
  "fontSizeDialog": 11,
  "fontSizeGantt": 11
}
```

`hiddenStatusesDefault` は初期状態で非表示にするステータスを指定する。

```json
["保留", "廃棄"]
```

`categories.json` は分類名とバッジ色を管理する。

```json
[
  { "name": "業務", "background": "#BAE6FD", "foreground": "#0369A1" },
  { "name": "調査", "background": "#E9D5FF", "foreground": "#6B21A8" }
]
```

## データファイル

同じフォルダにある以下の JSON を使う。

- `schedules.json`: Outlook同期データのキャッシュ。
- `logs.json`: 作業ログ。
- `settings.json`: 画面や予定追加の設定。
- `categories.json`: 分類設定。

別PCへ持ち出す場合やバックアップする場合は、必要に応じてこれらの JSON も一緒に扱う。

## 単一ファイル生成

会社PCなどへコピペで持っていく場合は、単一ファイルを生成する。

```powershell
.\build.ps1
```

既定では `dist/OutlookGantt.ps1` を生成する。
生成物の先頭には、元になったGitコミットIDをコメントとして入れる。

ルートの `OutlookGantt.ps1` を更新したい場合は、出力先を指定する。

```powershell
.\build.ps1 -OutputPath .\OutlookGantt.ps1
```

## 開発

通常の編集は `src/` 側で行い、`OutlookGantt.ps1` は持ち出し用の生成物として扱う。

```powershell
.\run-dev.ps1
```

Outlook に動作確認用の予定を追加する場合は、次を実行する。

```powershell
.\tools\add-test-schedules.ps1
```

UIやOutlook実体を起動しない範囲の軽いロジック確認:

```powershell
.\test.ps1
```

構文確認、軽量テスト、単一ファイル生成、生成物の構文確認:

```powershell
.\verify.ps1
```

## 構成

- `src/App/`: イベント登録、画面更新、イベントハンドラ。
- `src/Config/`: データファイルパス、Outlook対象、色、列幅、フォント、設定。
- `src/Content/`: アプリ内ヘルプ本文。
- `src/Domain/`: タイトル解析、ステータス、作業ログ、ガント判定、ガントDataView生成。
- `src/Infrastructure/`: JSON読み書き、Outlook COM連携。
- `src/UI/`: WPFメイン画面、ダイアログ、Gridレイアウト、ガント列テンプレート。
- `src/Shared/`: 汎用関数。
- `tools/`: 開発補助スクリプト。
- `launchers/`: 持ち出し用の起動補助ファイル。
