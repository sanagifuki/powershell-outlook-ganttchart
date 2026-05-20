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

function Add-OutlookAppointment {
    param(
        [string]$Subject,
        [string]$Body,
        [datetime]$StartDate,
        [datetime]$EndDate,
        [bool]$IsTimed,
        [string]$StartTime,
        [string]$EndTime,
        [bool]$IsPrivate = $true,
        [bool]$ShowAsFree = $true
    )

    $outlook = New-Object -ComObject Outlook.Application
    $appointment = $outlook.CreateItem(1)

    $appointment.Subject = $Subject
    $appointment.Body = $Body
    $appointment.BusyStatus = if ($ShowAsFree) { 0 } else { 2 }
    $appointment.Sensitivity = if ($IsPrivate) { 2 } else { 0 }
    $appointment.ReminderSet = $false

    if ($IsTimed) {
        $appointment.AllDayEvent = $false
        $appointment.Start = $StartDate.ToString("yyyy/MM/dd ") + $StartTime
        $appointment.End = $StartDate.ToString("yyyy/MM/dd ") + $EndTime
    }
    else {
        $appointment.AllDayEvent = $true
        $appointment.Start = $StartDate.ToString("yyyy/MM/dd 00:00:00")
        $appointment.End = $EndDate.AddDays(1).ToString("yyyy/MM/dd 00:00:00")
    }

    $appointment.Save()
}

function Get-OutlookAppointmentOptions {
    param([string]$EntryId)

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $appointment = $namespace.GetItemFromID($EntryId)

    [PSCustomObject]@{
        IsPrivate = ($appointment.Sensitivity -eq 2)
        ShowAsFree = ($appointment.BusyStatus -eq 0)
    }
}

function Set-OutlookAppointmentDetails {
    param(
        [string]$EntryId,
        [string]$Subject,
        [string]$Body,
        [datetime]$StartDate,
        [datetime]$EndDate,
        [bool]$IsTimed,
        [string]$StartTime,
        [string]$EndTime,
        [bool]$IsPrivate = $true,
        [bool]$ShowAsFree = $true
    )

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $appointment = $namespace.GetItemFromID($EntryId)

    $appointment.Subject = $Subject
    $appointment.Body = $Body
    $appointment.BusyStatus = if ($ShowAsFree) { 0 } else { 2 }
    $appointment.Sensitivity = if ($IsPrivate) { 2 } else { 0 }
    $appointment.ReminderSet = $false

    if ($IsTimed) {
        $appointment.AllDayEvent = $false
        $appointment.Start = $StartDate.ToString("yyyy/MM/dd ") + $StartTime
        $appointment.End = $StartDate.ToString("yyyy/MM/dd ") + $EndTime
    }
    else {
        $appointment.AllDayEvent = $true
        $appointment.Start = $StartDate.ToString("yyyy/MM/dd 00:00:00")
        $appointment.End = $EndDate.AddDays(1).ToString("yyyy/MM/dd 00:00:00")
    }

    $appointment.Save()
}

function Set-OutlookAppointmentCompletion {
    param(
        [string]$EntryId,
        [bool]$Completed
    )

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $appointment = $namespace.GetItemFromID($EntryId)
    if ($Completed) {
        $appointment.Categories = Add-CategoryText -Categories $appointment.Categories -Category "完了"
    }
    else {
        $appointment.Categories = Remove-CategoryText -Categories $appointment.Categories -Category "完了"
    }
    $appointment.Save()
}

function Set-OutlookAppointmentStatus {
    param(
        [string]$EntryId,
        [string]$Status
    )

    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $appointment = $namespace.GetItemFromID($EntryId)
    $appointment.Categories = ConvertTo-StatusCategories -Categories $appointment.Categories -Status $Status
    $appointment.Save()
}
