function ConvertTo-WpfBrush {
    param([string]$Color)

    [System.Windows.Media.BrushConverter]::new().ConvertFrom($Color)
}

function New-GanttHeaderStyle {
    param(
        [string]$Background,
        [string]$Foreground = $null
    )

    $style = New-Object System.Windows.Style([System.Windows.Controls.Primitives.DataGridColumnHeader])
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BackgroundProperty, (ConvertTo-WpfBrush -Color $Background))))
    if ($Foreground) {
        $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::ForegroundProperty, (ConvertTo-WpfBrush -Color $Foreground))))
    }
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::PaddingProperty, [System.Windows.Thickness]::new(6, 4, 6, 4))))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::HorizontalContentAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::VerticalContentAlignmentProperty, [System.Windows.VerticalAlignment]::Center)))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderThicknessProperty, [System.Windows.Thickness]::new(0, 0, 1, 1))))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Primitives.DataGridColumnHeader]::BorderBrushProperty, (ConvertTo-WpfBrush -Color $CLR_BORDER))))
    $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.TextBlock]::TextAlignmentProperty, [System.Windows.TextAlignment]::Center)))

    return $style
}

