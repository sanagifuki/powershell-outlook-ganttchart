# launchers

起動用ショートカットを置く場所です。

このフォルダ内の起動ファイルは、同じフォルダに `OutlookGantt.ps1` がある前提で使う設定になっています。
会社PCなどに持ち出す場合は、使いたい起動ファイルと `OutlookGantt.ps1` を同じフォルダに置いてください。

`OutlookGantt.lnk` は、PowerShellで `.\OutlookGantt.ps1` を起動します。
PowerShellの起動引数は次の設定です。

```text
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ".\OutlookGantt.ps1"
```

`OutlookGantt.vbs` は、コンソールを表示せずに `OutlookGantt.ps1` を起動するためのラッパーです。
VBS自身と同じフォルダにある `OutlookGantt.ps1` を起動します。
