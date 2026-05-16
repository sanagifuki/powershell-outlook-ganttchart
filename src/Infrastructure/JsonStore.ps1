function Read-JsonArray {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @()
    }

    $json = Get-Content $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($json)) {
        return @()
    }

    return @(ConvertFrom-Json $json)
}

function Write-JsonData {
    param(
        [string]$Path,
        $Data
    )

    $Data | ConvertTo-Json | Out-File $Path -Encoding UTF8
}

