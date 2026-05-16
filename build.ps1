param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'build.manifest.psd1'),
    [string]$OutputPath = (Join-Path $PSScriptRoot 'dist\OutlookGantt.ps1')
)

$ErrorActionPreference = 'Stop'
$manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
$repoRoot = Split-Path -Parent $ManifestPath

$builder = [System.Text.StringBuilder]::new()
[void]$builder.AppendLine('# Auto-generated from src/*.ps1 by build.ps1.')
[void]$builder.AppendLine('# Edit files under src/ instead of this generated file.')
[void]$builder.AppendLine()

foreach ($relativePath in $manifest.SourceFiles) {
    $path = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Source file not found: $relativePath"
    }
    [void]$builder.Append((Get-Content -LiteralPath $path -Raw -Encoding UTF8))
}

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $builder.ToString() -Encoding UTF8 -NoNewline
Write-Host "Built: $OutputPath"
