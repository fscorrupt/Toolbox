function Write-Log {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path,

		[Parameter(Mandatory = $true)]
		[string]$Message,

		[Parameter(Mandatory = $true)]
		[string]$Component,

		[Parameter(Mandatory = $true)]
		[ValidateSet('Info','Warning','Error')]
		[string]$Type
	)

	switch ($Type) {
		'Info' 
		{
			[int]$Type = 1
		}
		'Warning' 
		{
			[int]$Type = 2
		}
		'Error' 
		{
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

	# Write the line to the log file
	Add-Content -Path $Path -Value $Content -Force -Confirm:$false
}

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

##################################################################
# This Script will Disable RemotePowershell for all Users        #
# If you need it for some users, specify the AD Group on Line 59 #
##################################################################

$Date = Get-Date -Format yyyyMMdd
$LogLevel = 'None'
$log = "C:\Logs\Disable-RemotePowerShell" + "_$Date.log"

# Allowed AD Group for RemotePowerShell:
$AllowedGroup = "ENTER AD GROUP"
Write-Log -Path $log -Message '---------------' -Component ScriptEnd -Type Info	
Write-Log -Path $log -Message "Start of Script" -Component ScriptEnd -Type Info
Write-Log -Path $log -Message '---------------' -Component ScriptEnd -Type Info	

Write-Log -Path $log -Message "Getting all Users, this could take some time..." -Component ScriptStart -Type Info
$AllUsers = Get-User -ResultSize Unlimited -WarningAction SilentlyContinue | select SamAccountName,RemotePowerShellEnabled,Accountdisabled | where {$_.RemotePowerShellEnabled -eq $true -and $_.Accountdisabled -eq $false}
$AllowedUsers = Get-ADGroupMember $AllowedGroup -Recursive | ForEach-Object {Get-User -Identity $_.SamAccountName | select SamAccountName,RemotePowerShellEnabled}

#Enable RemotePowerShell for allowed Users
Write-Log -Path $log -Message '----------------------' -Component AllowPart -Type Info	
Write-Log -Path $log -Message "Admin User Allow Part" -Component AllowPart -Type Info
Write-Log -Path $log -Message '----------------------' -Component AllowPart -Type Info	

foreach ($AllowedUser in $AllowedUsers) {
	if ($AllowedUser.RemotePowerShellEnabled -eq $False) {
		Set-User $AllowedUser.SamAccountName -RemotePowerShellEnabled $true -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
		$Validate = (Get-User $AllowedUser.SamAccountName).RemotePowerShellEnabled
		if ($Validate -eq $true){
			Write-Log -Path $log -Message "RemotePowershell Enabled for Admin User: $($AllowedUser.SamAccountName)" -Component AllowPart -Type Info
		}
		if ($Validate -eq $false){
			Write-Log -Path $log -Message "ACCESS DENIED - Could not enable RemotePowershell for Admin User: $($AllowedUser.SamAccountName)" -Component AllowPart -Type Error
		}
	}
}

#Disable RemotePowerShell for all Users
Write-Log -Path $log -Message '------------------' -Component DisablePart -Type Info	
Write-Log -Path $log -Message "User disable Part" -Component DisablePart -Type Info
Write-Log -Path $log -Message '------------------' -Component DisablePart -Type Info	

foreach ($User in $AllUsers) {
	if ($AllowedUsers.SamAccountName -notcontains $User.SamAccountName) {
		Set-User $User.SamAccountName -RemotePowerShellEnabled $false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
		$Validate = (Get-User $User.SamAccountName).RemotePowerShellEnabled
		if ($Validate -eq $false){
			Write-Log -Path $log -Message "RemotePowershell Disabled for User: $($User.SamAccountName)" -Component DisablePart -Type Info
		}
		if ($Validate -eq $true){
			Write-Log -Path $log -Message "ACCESS DENIED - Could not disable RemotePowershell for User: $($User.SamAccountName)" -Component DisablePart -Type Error
		}
	}
}

Write-Log -Path $log -Message '--------------' -Component ScriptEnd -Type Info	
Write-Log -Path $log -Message "End of Script" -Component ScriptEnd -Type Info
Write-Log -Path $log -Message '--------------' -Component ScriptEnd -Type Info	

#Display RemotePowerSthell State
#$RemotePowerShellState = Get-User -ResultSize Unlimited | where RemotePowerShellEnabled -eq $true |select SamAccountName,RemotePowerShellEnabled
#$RemotePowerShellState
