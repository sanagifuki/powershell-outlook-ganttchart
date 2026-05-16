# PowerShell Outlook Ganttchart

Outlook の予定を取得し、作業ログと合わせてガントチャート表示する PowerShell/WPF アプリ。

## 開発

開発時は分割された `src/` 配下のファイルを使う。

```powershell
.\run-dev.ps1
```

## 単一ファイル生成

会社PCなどへコピペで持っていく場合は、単一ファイルを生成する。

```powershell
.\build.ps1
```

既定では `dist/OutlookGantt.ps1` を生成する。

ルートの `OutlookGantt.ps1` を更新したい場合は、出力先を指定する。

```powershell
.\build.ps1 -OutputPath .\OutlookGantt.ps1
```

## テスト

UIやOutlook実体を起動しない範囲の軽いロジック確認を行う。

```powershell
.\test.ps1
```

構文確認、軽量テスト、単一ファイル生成、生成物の構文確認をまとめて行う。

```powershell
.\verify.ps1
```

## 構成

- `src/App/`: 起動、イベント、画面更新。
- `src/Config/`: パス、Outlook対象、色、列幅、フォント。
- `src/Domain/`: ガント表示用データ構築。
- `src/Infrastructure/`: JSON読み書きなど外部データとの境界。
- `src/UI/`: WPFメイン画面とダイアログ。
- `src/Shared/`: 汎用関数。

`OutlookGantt.ps1` は持ち出し用の単一ファイルとして扱い、通常の編集は `src/` 側で行う。
