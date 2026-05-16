# リファクタリングメモ

## 現在の第一段階

現行の単一 `OutlookGantt.ps1` を、動作変更なしで `src/` 配下へ分割した。

目的は、開発時の見通しを良くしつつ、会社PCへ持ち出すための単一ファイル生成を維持すること。

## 方針

- まずは分割版と生成版が同じ動きをする状態を優先する。
- ロジック変更はこの土台が安定してから行う。
- `run-dev.ps1` と `build.ps1` は同じ `build.manifest.psd1` を読む。
- 読み込み順はファイル名ではなく manifest で管理する。

## 次の候補

- `DataStore.ps1` からタイトル解析を `Domain/ScheduleParser.ps1` へ分ける。
- `Refresh.ps1` からガント記号判定を小さい関数へ切り出す。
- Outlook COM 取得処理を `Infrastructure/OutlookClient.ps1` へ移す。
- JSON読み書きの壊れたファイル対応やバックアップを追加する。
