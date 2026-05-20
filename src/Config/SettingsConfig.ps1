$SettingsConfigRoot = if ($ScriptPath) { $ScriptPath } elseif ($script:AppRoot) { $script:AppRoot } else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$SettingsFile = Join-Path $SettingsConfigRoot "settings.json"

function Get-DefaultAppSettings {
    [PSCustomObject]@{
        ganttDefaultDays = 35
        ganttStartOffsetDays = -7
        logInputModeDefault = $true
        suppressWeekendScheduleHighlightDefault = $false
        topmostDefault = $false
        hiddenStatusesDefault = @()
        addAppointmentPrivateDefault = $true
        addAppointmentShowAsFreeDefault = $true
        addAppointmentTypeDefaultSymbol = "◆"
        addAppointmentCategoryDefault = "業務"
        rememberWindowPlacement = $true
        windowWidth = 769
        windowHeight = 600
        windowMinWidth = 825
        windowMinHeight = 420
        windowLeft = $null
        windowTop = $null
        fontMain = "Noto Sans JP, Meiryo, Yu Gothic UI"
        fontGantt = "Yu Gothic"
        fontSizeMain = 11
        fontSizeDialog = 11
        fontSizeGantt = 11
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

function Save-AppSettings {
    param($Settings)

    Write-JsonData -Path $SettingsFile -Data $Settings
}

function Test-WindowPlacementOnScreen {
    param(
        [double]$Left,
        [double]$Top,
        [double]$Width,
        [double]$Height
    )

    $screenLeft = [System.Windows.SystemParameters]::VirtualScreenLeft
    $screenTop = [System.Windows.SystemParameters]::VirtualScreenTop
    $screenRight = $screenLeft + [System.Windows.SystemParameters]::VirtualScreenWidth
    $screenBottom = $screenTop + [System.Windows.SystemParameters]::VirtualScreenHeight

    return (
        $Left -lt $screenRight -and
        ($Left + [Math]::Min($Width, 120)) -gt $screenLeft -and
        $Top -lt $screenBottom -and
        ($Top + [Math]::Min($Height, 80)) -gt $screenTop
    )
}

function Restore-WindowPlacement {
    param(
        $Window,
        $Settings
    )

    if ($Settings.windowMinWidth -and [double]$Settings.windowMinWidth -gt 0) {
        $Window.MinWidth = [double]$Settings.windowMinWidth
    }
    if ($Settings.windowMinHeight -and [double]$Settings.windowMinHeight -gt 0) {
        $Window.MinHeight = [double]$Settings.windowMinHeight
    }

    if ($Settings.windowWidth -and [double]$Settings.windowWidth -ge $Window.MinWidth) {
        $Window.Width = [double]$Settings.windowWidth
    }
    if ($Settings.windowHeight -and [double]$Settings.windowHeight -ge $Window.MinHeight) {
        $Window.Height = [double]$Settings.windowHeight
    }

    if ($Settings.rememberWindowPlacement -and $null -ne $Settings.windowLeft -and $null -ne $Settings.windowTop) {
        $left = [double]$Settings.windowLeft
        $top = [double]$Settings.windowTop
        if (Test-WindowPlacementOnScreen -Left $left -Top $top -Width $Window.Width -Height $Window.Height) {
            $Window.WindowStartupLocation = "Manual"
            $Window.Left = $left
            $Window.Top = $top
        }
    }
}

function Save-WindowPlacement {
    param(
        $Window,
        $Settings
    )

    if (-not $Settings.rememberWindowPlacement) { return }
    if ($Window.WindowState -eq "Minimized") { return }

    $Settings.windowWidth = [int][Math]::Round($Window.RestoreBounds.Width)
    $Settings.windowHeight = [int][Math]::Round($Window.RestoreBounds.Height)
    $Settings.windowLeft = [int][Math]::Round($Window.RestoreBounds.Left)
    $Settings.windowTop = [int][Math]::Round($Window.RestoreBounds.Top)
    Save-AppSettings -Settings $Settings
}

function Apply-AppFontSettings {
    param($Settings)

    if (-not [string]::IsNullOrWhiteSpace($Settings.fontMain)) {
        $script:FONT_MAIN = [string]$Settings.fontMain
    }
    if (-not [string]::IsNullOrWhiteSpace($Settings.fontGantt)) {
        $script:FONT_GANTT = [string]$Settings.fontGantt
    }
    if ($Settings.fontSizeMain -and [double]$Settings.fontSizeMain -gt 0) {
        $script:FONT_SIZE_MAIN = [double]$Settings.fontSizeMain
    }
    if ($Settings.fontSizeDialog -and [double]$Settings.fontSizeDialog -gt 0) {
        $script:FONT_SIZE_DIALOG = [double]$Settings.fontSizeDialog
    }
    if ($Settings.fontSizeGantt -and [double]$Settings.fontSizeGantt -gt 0) {
        $script:FONT_SIZE_GANTT = [double]$Settings.fontSizeGantt
    }
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
