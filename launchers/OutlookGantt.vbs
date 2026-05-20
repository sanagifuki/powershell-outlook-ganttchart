' コンソールを表示せずに OutlookGantt.ps1 を起動するためのラッパーです。
' このファイルは OutlookGantt.ps1 と同じフォルダに置いてください。
' ショートカットを作る場合は、この VBS をリンク先にしてください。
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path = fso.BuildPath(scriptDir, "OutlookGantt.ps1")

command = "powershell.exe -ExecutionPolicy Bypass -File """ & ps1Path & """"
shell.Run command, 0, False
