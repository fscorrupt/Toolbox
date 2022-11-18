function InitiateReboot{
	$restartcomputer = Restart-Computer -Force -Confirm:$false
}
function LoggedonUsers {
	$computer = $env:COMPUTERNAME
	$Users = query.exe user /server:$computer 2>&1
	
	if ($Error){
		$UserConnected = $false
	}
	Else {
		$UserConnected = $true
	}
	Return $UserConnected
}
function EvaluateUpdateStates{
	# Check if Updates are Currently installing or Downloading, to determinate if we can reboot or not.
	$CantReboot = '11','7','6','5','4','2' # https://learn.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/sdk/ccm_softwareupdate-client-wmi-class
	$GettingUpdatesStates =(Get-WmiObject -Query 'SELECT * FROM CCM_SoftwareUpdate' -namespace 'ROOT\ccm\ClientSDK' | where {$_.EvaluationState -in $CantReboot}).EvaluationState
	
	# Check if Users are Connected
	$UsersConnected = LoggedonUsers
	
	# Initiate Reboot, when there is no users connected and no update installation in progress.
	if (!$GettingUpdatesStates -and !$UsersConnected){
		InitiateReboot
	}
}

# Getting Service Windows from device
$ServiceWindows = Get-WmiObject -namespace root\CCM\ClientSDK -class CCM_ServiceWindow | Where-Object {$_.Type -lt '6'} | Select-Object ID, StartTime, EndTime, Duration, Type
			
# Adding converted Start/End Time
$ServiceWindows = $ServiceWindows | Select *,
@{N="Start";E={ [System.Management.ManagementDateTimeConverter]::ToDateTime($_.StartTime).ToUniversalTime()} },
@{N="End";E={ [System.Management.ManagementDateTimeConverter]::ToDateTime($_.EndTime).ToUniversalTime()} }
			
# Select service window
$ServiceWindow = $ServiceWindows | Sort start | Select -First 1
			
# Check if Service Windows are overlapping
$SW_Overlap = $ServiceWindows | ? { ( $_.Start -ge $ServiceWindow.Start ) -and ( $_.Start -le $ServiceWindow.End ) -and ( $_.ID -ne $ServiceWindow.ID ) }
			
# Change Start/End time if they overlap.
If ($SW_Overlap){
	$StartTime = @($ServiceWindow.Start) + @($sw_overlap.start) | sort | Select -first 1
	$EndTime = @($ServiceWindow.End) + @($SW_Overlap.End) | sort | Select -Last 1
}
Else{
	$StartTime = $ServiceWindow.Start
	$EndTime = $ServiceWindow.End
}
			
# Determinate if Server is currently in Maintenance
$CurrentTime = (Get-Date)
$InMaint = [bool](($CurrentTime -ge $StartTime) -and ($CurrentTime -le $EndTime))

if($InMaint){
	EvaluateUpdateStates
}
