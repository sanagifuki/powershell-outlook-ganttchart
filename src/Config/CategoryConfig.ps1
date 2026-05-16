$CategoryConfigRoot = if ($ScriptPath) { $ScriptPath } elseif ($script:AppRoot) { $script:AppRoot } else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$CategoriesFile = Join-Path $CategoryConfigRoot "categories.json"

function Get-DefaultCategories {
    @(
        [PSCustomObject]@{ name = "業務"; background = $CLR_CAT_PAY_BG; foreground = $CLR_CAT_PAY_FG }
        [PSCustomObject]@{ name = "重要"; background = $CLR_CAT_IMPORTANT_BG; foreground = $CLR_CAT_IMPORTANT_FG }
        [PSCustomObject]@{ name = "調査"; background = $CLR_CAT_RES_BG; foreground = $CLR_CAT_RES_FG }
        [PSCustomObject]@{ name = "雑務"; background = $CLR_CAT_CHORE_BG; foreground = $CLR_CAT_CHORE_FG }
        [PSCustomObject]@{ name = "手続き"; background = $CLR_CAT_PROC_BG; foreground = $CLR_CAT_PROC_FG }
        [PSCustomObject]@{ name = "スキルアップ"; background = $CLR_CAT_SKILL_BG; foreground = $CLR_CAT_SKILL_FG }
        [PSCustomObject]@{ name = "会社対応"; background = $CLR_CAT_CORP_BG; foreground = $CLR_CAT_CORP_FG }
        [PSCustomObject]@{ name = "支払い"; background = $CLR_CAT_PAY_BG; foreground = $CLR_CAT_PAY_FG }
    )
}

function Get-Categories {
    $categories = if (Test-Path $CategoriesFile) { Read-JsonArray -Path $CategoriesFile } else { Get-DefaultCategories }

    foreach ($category in $categories) {
        if (-not $category.background) { $category | Add-Member -MemberType NoteProperty -Name background -Value "#E5E7EB" -Force }
        if (-not $category.foreground) { $category | Add-Member -MemberType NoteProperty -Name foreground -Value "#333333" -Force }
        $category
    }
}

function Get-CategoryNames {
    @(Get-Categories | ForEach-Object { $_.name })
}

function Get-CategoryTheme {
    param([string]$Name)

    $category = Get-Categories | Where-Object { $_.name -eq $Name } | Select-Object -First 1
    if ($category) {
        return $category
    }

    [PSCustomObject]@{
        name = $Name
        background = "#E5E7EB"
        foreground = "#333333"
    }
}
