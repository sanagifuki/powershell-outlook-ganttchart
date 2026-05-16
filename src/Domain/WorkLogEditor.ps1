function New-WorkLog {
    param(
        [string]$Uid,
        [string]$Date,
        [string]$Content,
        [string]$Time
    )

    [PSCustomObject]@{
        uid = $Uid
        date = $Date
        content = $Content
        time = $Time
    }
}

function Find-WorkLogIndex {
    param(
        [array]$Logs,
        $TargetLog
    )

    for ($i = 0; $i -lt $Logs.Count; $i++) {
        if ($Logs[$i].uid -eq $TargetLog.uid -and
            $Logs[$i].date -eq $TargetLog.date -and
            $Logs[$i].time -eq $TargetLog.time -and
            $Logs[$i].content -eq $TargetLog.content) {
            return $i
        }
    }

    return -1
}

function Upsert-WorkLog {
    param(
        [array]$Logs,
        $NewLog,
        $EditLog
    )

    if ($EditLog) {
        $index = Find-WorkLogIndex -Logs $Logs -TargetLog $EditLog
        if ($index -ge 0) {
            $Logs[$index] = $NewLog
            return @($Logs)
        }
    }

    return @($Logs + $NewLog)
}

