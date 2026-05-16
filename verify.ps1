param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'build.manifest.psd1')
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $ManifestPath

$sourceErrors = @()
Get-ChildItem -Recurse -File (Join-Path $repoRoot 'src') -Filter '*.ps1' | ForEach-Object {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        $sourceErrors += $_.FullName
        foreach ($error in $errors) {
            $sourceErrors += "  $($error.ErrorId): $($error.Message)"
        }
    }
}
if ($sourceErrors.Count -gt 0) {
    $sourceErrors | Write-Error
    exit 1
}

& (Join-Path $repoRoot 'test.ps1') -ManifestPath $ManifestPath
& (Join-Path $repoRoot 'build.ps1') -ManifestPath $ManifestPath

$generatedPath = Join-Path $repoRoot 'dist/OutlookGantt.ps1'
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $generatedPath).Path, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count -gt 0) {
    $errors | Format-List
    exit 1
}

Write-Host 'Verification passed.'

