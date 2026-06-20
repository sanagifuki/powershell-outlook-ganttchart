function Format-WorkLogTime {
    param($WorkTime)

    if ($WorkTime) {
        if ($WorkTime -match '分$') {
            return $WorkTime
        }

        return "$($WorkTime)分"
    }

    return "0分"
}

function ConvertTo-DisplayWorkLog {
    param(
        $Log,
        [array]$Tasks
    )

    $taskEntry = $Tasks | Where-Object { $_.uid -eq $Log.uid } | Select-Object -First 1
    $savedTitle = if ($Log.PSObject.Properties["title"]) { [string]$Log.title } else { "" }
    $title = if ($taskEntry) {
        $taskEntry.タイトル
    }
    elseif (-not [string]::IsNullOrWhiteSpace($savedTitle)) {
        $savedTitle
    }
    else {
        "削除・同期対象外のスケジュール"
    }

    $Log | Add-Member -MemberType NoteProperty -Name "title" -Value $title -Force
    $Log | Add-Member -MemberType NoteProperty -Name "displayTime" -Value (Format-WorkLogTime -WorkTime ($Log.time)) -Force -PassThru
}

function ConvertTo-DisplayWorkLogs {
    param(
        [array]$Logs,
        [array]$Tasks
    )

    foreach ($log in ($Logs | Sort-Object date -Descending)) {
        ConvertTo-DisplayWorkLog -Log $log -Tasks $Tasks
    }
}
