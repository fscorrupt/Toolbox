<#
    Script Description:
    
    This PowerShell script automates DHCP reservation cleanup by analyzing DHCP log files for renewals. 
    It maintains a history of renewals, identifies obsolete entries, and removes reservations for devices that haven't renewed in a specified time. 
    The script runs daily, utilizing Task Scheduler.
    After X days logrotation with export of data to an archive folder.

#>

############
# Variables#
############
# Date Part
$Days = '90'
$UTCDate = (Get-Date).ToUniversalTime()
$UTCDateArchive = (Get-Date).ToUniversalTime().AddDays(-$Days)  
$DatePattern = 'MM/dd/yy'
$DatePatternArchiveFolder = 'yyyyMMdd'
# Specify the English (United States) culture
$culture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
# Get the formatted UTC date
$formattedUtcDate = $UTCDate.ToString('ddd', $culture)
$currentDate = $UTCDate.ToString($DatePattern, $culture)
$ArchiveDateStart = $UTCDateArchive.ToString($DatePatternArchiveFolder, $culture)
$ArchiveDateEnd = $UTCDate.ToString($DatePatternArchiveFolder, $culture)
# Script Part
$ScopeName = 'Scope1'
$IPPattern = ',?(\d+\.\d+\.\d+.\d{3}),' # Example: ",x.x.x.100," and higher
$IPPatternDHCP = '(\d+\.\d+\.\d+.\d{3})' # Example: "x.x.x.100" and higher
$LogPattern = 'Renew,' # only query entries which got a address
# Log Part
$ExportPath = "C:\$ScopeName\Logs\DHCP"
$ArchivePath = "C:\$ScopeName\Logs\DHCP\Archive\$($ArchiveDateStart)-$($ArchiveDateEnd)"
$DHCPLogPath = "C:\Windows\System32\dhcp"
$FilteredcsvFilePath = "$ExportPath\DhcpSrvLog.csv"
$DHCPLog = "$DHCPLogPath\DhcpSrvLog-$formattedUtcDate.log"
$OriginalcsvFilePath = "$ExportPath\Original_DhcpSrvLog-$formattedUtcDate.csv"
$MissingDevicesToDeletecsvFilePath = "$ExportPath\MissingDevicesToDelete.csv"
$StaleDevicesToDeletecsvFilePath = "$ExportPath\StaleDevicesToDelete.csv"
$Path = "$ExportPath\DHCPCleanup.log"

# Logging function
function Write-Log {
    [CmdletBinding()]
    param(
        #        [Parameter(Mandatory = $true)]
        #        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string]$Component,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Type
    )
    $Logtype = $type
    switch ($Type) {
        'Info' {
            [int]$Type = 1 
        }
        'Warning' {
            [int]$Type = 2 
        }
        'Error' {
            [int]$Type = 3 
        }
    }

    # Create a log entry
    $Content = "<![LOG[$Message]LOG]!>" + `
        "<time=`"$(Get-Date -Format 'HH:mm:ss.ffffff')`" " + `
        "date=`"$(Get-Date -Format 'M-d-yyyy')`" " + `
        "component=`"$Component`" " + `
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + `
        "type=`"$Type`" " + `
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " + `
        "file=`"`">"

    $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 

    # Write the line to the log file
    $Path_advanced = $Path.Replace(".log", "_advanced.log")
    Add-Content -Path $Path_advanced -Value $Content -Force -Confirm:$false
    Add-Content -Path $Path -Value "[$Logtype] $FormattedDate - $Message" -Force -Confirm:$false
    #Write-Host $Message
}
##############
# Main Script#
##############
Write-Log -Component "Info" -Type Info -Message "##################################################################"
Write-Log -Component "Info" -Type Info -Message "-------- Script started on $formattedUtcDate $ArchiveDate --------"
Write-Log -Component "Info" -Type Info -Message "##################################################################"
# Create Log Folder if not present
if (!(Test-Path $ExportPath)) {
    Write-Log -Component "Prereq" -Type Info -Message "Creating folder structure for logs: $ExportPath"
    New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
}

# Get Today's DHCP log
Write-Log -Component "Main" -Type Info -Message "Getting today's DHCP log: $DHCPLog"
$Log = Get-Content $DHCPLog

# Select only lines that match the pattern
Write-Log -Component "Main" -Type Info -Message "Filter DHCP log based on pattern..."
$selectedLines = $Log | Select-String -Pattern $LogPattern | Where-Object { ($_ -match $IPPattern ) }

# Import filtered csv with all data only if file exists (on first run it does not exist)
if (Test-Path $FilteredcsvFilePath) {
    Write-Log -Component "Main" -Type Info -Message "Import filtered csv file: $FilteredcsvFilePath"
    $csvEntries = Import-Csv $FilteredcsvFilePath -Delimiter ';'
}

# Create an Array for every selected entry from the DHCP Log file
Write-Log -Component "Main" -Type Info -Message "Creating an array foreach filtered entry in dhcp log..."
$entriesArray = foreach ($line in $selectedLines) {
    $linesplit = $line -split ','
        
    # Extract information
    $date = $linesplit[1]
    $time = $linesplit[2]
    $ip = $linesplit[4]
    $hostname = $linesplit[5]
    $mac = $linesplit[6]
        
    # Create a custom object and output it
    [PSCustomObject]@{
        Date     = $date
        Time     = $time
        IP       = $ip
        Hostname = $hostname
        MAC      = $mac
    }
}
Write-Log -Component "Main" -Type Info -Message "Found '$($entriesArray.count)' entries in current log..."
# Export unfiltered entries to todays csv (every weekday has its own file)
Write-Log -Component "Main" -Type Info -Message "Export unfiltered entries: $OriginalcsvFilePath"
$entriesArray | Select-Object * | Export-Csv -Delimiter ';' -Path $OriginalcsvFilePath -Append -NoTypeInformation

# If filtered csv got imported contuine here
if ($csvEntries) {
    # Find the earliest date in the CSV data (this is the Start date of script and important for cleanup)
    Write-Log -Component "Main" -Type Info -Message "Getting startdate of DHCP Cleanup script..."
    $earliestDate = ($csvEntries | ForEach-Object {
            [datetime]::ParseExact($_.Date, $DatePattern, $null)
        } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum).ToString($DatePattern)

    # Determine Delta Days since beginning
    $currentDateVar = [datetime]::ParseExact("$currentDate", $DatePattern, $null)
    $earliestDateVar = [datetime]::ParseExact("$earliestDate", $DatePattern, $null)
    $DeltaBeginningDate = ($currentDateVar - $earliestDateVar).days
    Write-Log -Component "Main" -Type Info -Message "Script Started $DeltaBeginningDate days ago, $($Days - $DeltaBeginningDate) days to go..."
    # If devices older X days contuine with cleanup    
    if ($DeltaBeginningDate -ge $Days) {
        Write-Log -Component "Main" -Type Info -Message "DHCP cleaner watched $DeltaBeginningDate days, starting cleanup now..."
        # Check DHCP
        $Scope = (Get-DHCPServerV4Scope | Where-Object { $_.Name -eq $ScopeName }).ScopeId
        $FilteredDHCPAddresses = Get-DhcpServerv4Reservation -ScopeId $Scope.IPAddressToString | Where-Object { ($_.IPAddress -match $IPPatternDHCP) }
        Write-Log -Component "Main" -Type Info -Message "Checking DHCP ($Scope) reservations based on pattern..."
        # Determine if there are DHCP entries available and not present in csv - obsolete devices
        # Filter DHCP reservations that are missing in CSV based on MAC address

        # Reset Variable to '', just to be safe
        $MissingDHCPReservations = $null
        $MissingDHCPReservations = $FilteredDHCPAddresses | Where-Object { $_.ClientId.replace('-', '') -notin $csvEntries.MAC }
        Write-Log -Component "Main" -Type Info -Message "Found '$($MissingDHCPReservations.count)' entries that are not present in logfile..."
        $ToDelete = @()
        foreach ($missing in $MissingDHCPReservations) {
            # Create Table for Export
            $entryinfo = New-Object psobject
            $entryinfo | Add-Member -MemberType NoteProperty -Name "IP" -Value $missing.IPAddress.IPAddressToString
            $entryinfo | Add-Member -MemberType NoteProperty -Name "ScopeId" -Value $missing.ScopeId
            $entryinfo | Add-Member -MemberType NoteProperty -Name "Name" -Value $missing.Name
            $entryinfo | Add-Member -MemberType NoteProperty -Name "MAC" -Value $missing.ClientId.replace('-', '')
            $entryinfo | Add-Member -MemberType NoteProperty -Name "Description" -Value $missing.Description
            $ToDelete += $entryinfo

            # Remove Reservation
            $missing | Remove-DhcpServerv4Reservation -WhatIf
            Write-Log -Component "Main" -Type Warning -Message "DHCP reservation removed for - IP: $($entryinfo.ip) | Name: $($entryinfo.Name) | MAC: $($entryinfo.MAC) | MAC: $($entryinfo.Description)"
        }
        if ($ToDelete){
            # Export removed entries to a csv
            $ToDelete | Select-Object * | Export-Csv -Delimiter ';' -Path $MissingDevicesToDeletecsvFilePath -Append -NoTypeInformation
            Write-Log -Component "Main" -Type Info -Message "Exported all removed entries to logfile: $MissingDevicesToDeletecsvFilePath"
            $logrotation = $true
        }
        #Stale Device Part
        # Stale devices in csv but older then X days
        Write-Log -Component "Main" -Type Info -Message "Checking for Stale entries in csv..."
        foreach ($staleEntry in $csvEntries) {
            $date1 = [datetime]::ParseExact("$currentDate", $DatePattern, $null)
            $date2 = [datetime]::ParseExact("$($staleEntry.date)", $DatePattern, $null)
            # Determine Delta Days from entries
            $DeltaDate = ($date1 - $date2).days
            # If devices older X days contuine with cleanup  
            if ($DeltaDate -ge $Days) {
                $StaleToDelete = @()
                # Create Table for Export
                $staleEntrytemp = New-Object psobject
                $staleEntrytemp | Add-Member -MemberType NoteProperty -Name "IP" -Value $staleEntry.IP
                $staleEntrytemp | Add-Member -MemberType NoteProperty -Name "Name" -Value $staleEntry.Hostname
                $staleEntrytemp | Add-Member -MemberType NoteProperty -Name "MAC" -Value $staleEntry.MAC
                $StaleToDelete += $staleEntrytemp
            }
        }
        if ($StaleToDelete) {
            Write-Log -Component "Main" -Type Info -Message "Found '$($StaleToDelete.count)' entries older then '$Days days' in logfile..."
            # Check DHCP
            Write-Log -Component "Main" -Type Info -Message "Checking DHCP ($Scope) reservations based on pattern..."
            $Scope = (Get-DHCPServerV4Scope | Where-Object { $_.Name -eq $ScopeName }).ScopeId
            $FilteredDHCPAddresses = Get-DhcpServerv4Reservation -ScopeId $Scope.IPAddressToString | Where-Object { ($_.IPAddress -match $IPPatternDHCP) }
            foreach ($staletodeleteEntry in $StaleToDelete) {
                # Reset Variable to '', just to be safe
                $DHCPReservation = $null
                # Filter DHCP reservations that match based on MAC
                $DHCPReservation = $FilteredDHCPAddresses | Where-Object { $_.ClientId.replace('-', '') -eq $staletodeleteEntry.MAC }
        
                if ($DHCPReservation) {
                    Write-Log -Component "Main" -Type Warning -Message "Reservation found, removing now..."
                    $StaleDeletedEntries = @()
                    # Create Table for Export
                    $staleDeletedEntrytemp = New-Object psobject
                    $staleDeletedEntrytemp | Add-Member -MemberType NoteProperty -Name "IP" -Value $DHCPReservation.IPAddress.IPAddressToString
                    $staleDeletedEntrytemp | Add-Member -MemberType NoteProperty -Name "ScopeId" -Value $DHCPReservation.ScopeId
                    $staleDeletedEntrytemp | Add-Member -MemberType NoteProperty -Name "Name" -Value $DHCPReservation.Name
                    $staleDeletedEntrytemp | Add-Member -MemberType NoteProperty -Name "MAC" -Value $DHCPReservation.ClientId.replace('-', '')
                    $staleDeletedEntrytemp | Add-Member -MemberType NoteProperty -Name "Description" -Value $DHCPReservation.Description
                    $StaleDeletedEntries += $staleDeletedEntrytemp
                    # Remove Reservation
                    $DHCPReservation | Remove-DhcpServerv4Reservation -WhatIf
                    Write-Log -Component "Main" -Type Warning -Message "DHCP reservation removed for - IP: $($staleDeletedEntrytemp.IP) | Name: $($staleDeletedEntrytemp.Name) | MAC: $($staleDeletedEntrytemp.MAC) | Description: $($staleDeletedEntrytemp.Description)"   
                }
            }
            # Export removed entries to a csv
            $StaleDeletedEntries | Select-Object * | Export-Csv -Delimiter ';' -Path $StaleDevicesToDeletecsvFilePath -Append -NoTypeInformation
            Write-Log -Component "Main" -Type Info -Message "Exported all removed entries to logfile: $StaleDevicesToDeletecsvFilePath"
            $logrotation = $true
        }
        Else {
            Write-Log -Component "Main" -Type Info -Message "No stale devices found..."
        }
    }
}

# Merge csv and current log entries
$combinedEntries = $csvEntries + $entriesArray

# Group merged entries and select only newest
$groupedEntries = $combinedEntries | Group-Object -Property MAC | ForEach-Object {
    $_.Group | Sort-Object { [datetime]::ParseExact("$($_.Date) $($_.Time)", 'MM/dd/yy HH:mm:ss', $null) } -Descending | Select-Object -First 1
}

# Export merged Grouped uniqe Entries
$groupedEntries | Select-Object * | Export-Csv -Delimiter ';' -Path $FilteredcsvFilePath -NoTypeInformation
Write-Log -Component "Main" -Type Info -Message "We now have '$($groupedEntries.count)' unique entries in csv file..."

Write-Log -Component "Info" -Type Info -Message "---------------- Script end ----------------"

# Create Archive Folder if not present
if ($logrotation) {
    if (!(Test-Path $ArchivePath)) {
        New-Item -ItemType Directory -Path $ArchivePath -Force | Out-Null
    }
    # Move all current logs into archive and start fresh
    $files = Get-ChildItem -Path $ExportPath -File
    foreach ($file in $files) {
        Move-Item $file.FullName  $ArchivePath -Force
    }
}
