# リファクタリングメモ

## 現在の状態

現行の単一 `OutlookGantt.ps1` を、`src/` 配下へ分割した。

目的は、開発時の見通しを良くしつつ、会社PCへ持ち出すための単一ファイル生成を維持すること。

単一ファイルは `build.ps1` で `dist/OutlookGantt.ps1` として生成する。
開発時は `run-dev.ps1` を使う。

## 方針

- `run-dev.ps1` と `build.ps1` は同じ `build.manifest.psd1` を読む。
- 読み込み順はファイル名ではなく manifest で管理する。
- `verify.ps1` で構文確認、軽量テスト、単一ファイル生成、生成物の構文確認をまとめて行う。
- UIやOutlook実体に触らないロジックは `test.ps1` にサンプルを増やしてから触る。

## 現在の分担

- `App/`: 起動後のイベント登録、画面更新、イベントハンドラ。
- `Config/`: データファイルパス、Outlook対象、色、列幅、フォント。
- `Content/`: アプリ内ヘルプ本文。
- `Domain/`: タイトル解析、作業ログ編集/表示、ガント判定、ガントDataView生成などのアプリルール。
- `Infrastructure/`: JSON読み書き、Outlook COM連携。
- `UI/`: WPFメイン画面、ダイアログ、Gridレイアウト、ガント列テンプレート。
- `Shared/`: 汎用テキスト処理、WPF小物。

## 次の候補

- `MainWindow.ps1` の巨大XAMLをどう扱うか検討する。
- `AddAppointmentDialog.ps1` / `LogDialog.ps1` のXAMLとイベント処理をさらに分ける。
- `OutlookClient.ps1` のCOM解放、エラー粒度、同期範囲設定を見直す。
- JSON読み書きの壊れたファイル対応、バックアップ、自動復旧を追加する。
- Pester導入が重くなければ、`test.ps1` から段階的に移行する。
