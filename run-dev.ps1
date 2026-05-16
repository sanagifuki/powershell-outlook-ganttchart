param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'build.manifest.psd1')
)

$ErrorActionPreference = 'Stop'
$manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
$repoRoot = Split-Path -Parent $ManifestPath

foreach ($relativePath in $manifest.SourceFiles) {
    $path = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Source file not found: $relativePath"
    }
    . $path
}
