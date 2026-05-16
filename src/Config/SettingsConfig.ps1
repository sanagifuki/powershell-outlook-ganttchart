$SettingsConfigRoot = if ($ScriptPath) { $ScriptPath } elseif ($script:AppRoot) { $script:AppRoot } else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$SettingsFile = Join-Path $SettingsConfigRoot "settings.json"

function Get-DefaultAppSettings {
    [PSCustomObject]@{
        ganttDefaultDays = 35
        ganttStartOffsetDays = -7
        logInputModeDefault = $true
        suppressWeekendScheduleHighlightDefault = $false
        addAppointmentPrivateDefault = $true
        addAppointmentShowAsFreeDefault = $true
        addAppointmentTypeDefaultSymbol = "◆"
        addAppointmentCategoryDefault = "業務"
    }
}

function Add-MissingSetting {
    param(
        $Settings,
        [string]$Name,
        $Value
    )

    if ($null -eq $Settings.PSObject.Properties[$Name]) {
        $Settings | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
    }
}

function Get-AppSettings {
    if (-not (Test-Path $SettingsFile)) {
        Write-JsonData -Path $SettingsFile -Data (Get-DefaultAppSettings)
    }

    $settings = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $defaults = Get-DefaultAppSettings
    foreach ($property in $defaults.PSObject.Properties) {
        Add-MissingSetting -Settings $settings -Name $property.Name -Value $property.Value
    }

    return $settings
}

function Select-ComboBoxItemByContent {
    param(
        $ComboBox,
        [string]$Content
    )

    for ($i = 0; $i -lt $ComboBox.Items.Count; $i++) {
        if ([string]$ComboBox.Items[$i].Content -eq $Content) {
            $ComboBox.SelectedIndex = $i
            return
        }
    }
}

function Select-ComboBoxItemByTag {
    param(
        $ComboBox,
        [string]$Tag
    )

    for ($i = 0; $i -lt $ComboBox.Items.Count; $i++) {
        if ([string]$ComboBox.Items[$i].Tag -eq $Tag) {
            $ComboBox.SelectedIndex = $i
            return
        }
    }
}
