# launchers

起動用ファイルを置く場所です。

## OutlookGantt.vbs

`OutlookGantt.vbs` は、コンソールを表示せずに `OutlookGantt.ps1` を起動するためのラッパーです。
VBS自身と同じフォルダにある `OutlookGantt.ps1` を起動します。

会社PCなどに持ち出す場合は、`OutlookGantt.vbs` と `OutlookGantt.ps1` を同じフォルダに置いてください。
ショートカットは、`OutlookGantt.vbs` から作成してください。

## PowerShellを直接指定する場合

VBSを使わずにショートカットから直接起動したい場合は、リンク先を次のようにします。

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "<OutlookGantt.ps1のパス>"
```
