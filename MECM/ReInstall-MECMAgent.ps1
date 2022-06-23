$ccmsetup = "C:\Windows\ccmsetup\ccmsetup.exe"
$Uninstallarg = "/uninstall"
$Installarg = "/mp:SCCMSERVERNAME.domain.local /logon SMSSITECODE=XXX"
$Action = '{00000000-0000-0000-0000-000000000022}'

<#Logfile Path
	C:\Windows\ccmsetup\Logs\ccmsetup.log
#>

#Uninstall ccmagent
Start-Process $ccmsetup -ArgumentList $Uninstallarg -Wait

#Remove all Binaries
Remove-Item -Path C:\Windows\ccmsetup\* -Recurse -Exclude "logs","ccmsetup.exe" -ErrorAction SilentlyContinue -Confirm:$false

#Install ccmagent
Start-Process $ccmsetup -ArgumentList $Installarg -Wait

#Trigger Machine Policy Action
Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $Action -ErrorAction SilentlyContinue 