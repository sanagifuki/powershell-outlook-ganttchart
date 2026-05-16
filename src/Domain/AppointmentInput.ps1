function Format-AppointmentTitle {
    param(
        [string]$Symbol,
        [string]$Category,
        [string]$Title
    )

    return "$Symbol［$Category］$Title"
}

function Test-TimeText {
    param([string]$Text)

    return ($Text -match '^\d{1,2}:\d{2}$')
}

