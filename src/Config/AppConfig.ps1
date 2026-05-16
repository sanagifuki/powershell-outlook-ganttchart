
$ScriptPath = if ($script:AppRoot) { $script:AppRoot } else { $PSScriptRoot }
$TasksFile = Join-Path $ScriptPath "schedules.json"
$LogsFile = Join-Path $ScriptPath "logs.json"

# ========================
# Outlook設定
# ========================
# 同期したいメールアドレスを指定します。
# ※空欄("")にすると、Outlookの既定(メイン)アカウントが同期されます。
$TARGET_OUTLOOK_EMAIL = ""

# ========================
