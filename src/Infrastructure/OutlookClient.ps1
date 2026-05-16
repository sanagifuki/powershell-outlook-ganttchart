function Get-OutlookCalendarFolder {
    param(
        $Namespace,
        [string]$TargetEmail
    )

    if (-not [string]::IsNullOrWhiteSpace($TargetEmail)) {
        foreach ($store in $Namespace.Stores) {
            if ($store.DisplayName -eq $TargetEmail) {
                return $store.GetDefaultFolder(9)
            }
        }

        throw "指定したアカウント（$TargetEmail）が見つかりません。"
    }

    return $Namespace.GetDefaultFolder(9)
}

function ConvertFrom-OutlookAppointment {
    param($Item)

    [PSCustomObject]@{
        uid = $Item.EntryID
        title = $Item.Subject
        start = $Item.Start.ToString("yyyy/MM/dd")
        end = if ($Item.AllDayEvent) { $Item.End.AddDays(-1).ToString("yyyy/MM/dd") } else { $Item.End.ToString("yyyy/MM/dd") }
        startTime = if ($Item.AllDayEvent) { "" } else { $Item.Start.ToString("HH:mm") }
        endTime = if ($Item.AllDayEvent) { "" } else { $Item.End.ToString("HH:mm") }
        memo = Format-Memo $Item.Body
        categories = $Item.Categories
    }
}

function Get-OutlookScheduleSyncData {
    param(
        [string]$TargetEmail,
        [int]$MonthsBefore = 36,
        [int]$MonthsAfter = 36
    )

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $calendar = Get-OutlookCalendarFolder -Namespace $namespace -TargetEmail $TargetEmail
    $syncedAccount = $calendar.Store.DisplayName

    $items = $calendar.Items
    $items.IncludeRecurrences = $true
    $items.Sort("[開始]")

    $filterStart = (Get-Date).AddMonths(-$MonthsBefore).ToString("MM/dd/yyyy")
    $filterEnd = (Get-Date).AddMonths($MonthsAfter).ToString("MM/dd/yyyy")
    $filter = "[Start] >= '$filterStart' AND [End] <= '$filterEnd'"

    $count = 0
    $tasks = foreach ($item in $items.Restrict($filter)) {
        if ($item -isnot [System.__ComObject]) { continue }
        $count++
        ConvertFrom-OutlookAppointment -Item $item
    }

    [PSCustomObject]@{
        Tasks = @($tasks)
        Count = $count
        Account = $syncedAccount
    }
}

