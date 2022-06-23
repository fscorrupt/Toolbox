#Change Shell Color Theme
$Host.UI.RawUI.WindowTitle = "Powers-Hell"
cls

# Variables
$adminUPN = "user@contoso.com"

function uptime {
	Get-WmiObject win32_operatingsystem | select csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}

Function pass {
	-join(48..57+65..90+97..122|ForEach-Object{[char]$_}|Get-Random -C 20) | Set-Clipboard
}

Function printer-remote {
	# For Konica Minolta
	write-host "Enter Printername: " -ForegroundColor Yellow -NoNewline
	$Printername = Read-Host
	$URL = "https://$Printername"+":50443/panel/remote_panel.cgi"
	if ($URL){
		[system.Diagnostics.Process]::Start("msedge",$URL) | Out-Null
	}
}

Function msol {
	Connect-MsolService -UserPrincipalName $adminUPN
}

Function msgraph {
	Connect-MSGraph -UserPrincipalName $adminUPN
}

Function azuread {
	Connect-AzureAD -UserPrincipalName $adminUPN
}

Function sid2sam {
	$cSID = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value
	Write-Host "SID of current user ($env:USERNAME) is: " -NoNewline 
	Write-Host $cSID -ForegroundColor Cyan
	Write-Host ''
	Write-Host "Enter SID (to get sammacountname): " -NoNewline -ForegroundColor Yellow
	$sid= Read-Host 
	Write-Host ''
	$User = $([adsi]"LDAP://<SID=$sid>").samaccountname
	Write-Host "Username is: " -NoNewline
	Write-Host $User -ForegroundColor Cyan
}
Function loaded {
	Write-Host 'Loaded Functions: uptime | pass | sid2sam | printer-remote | msol | msgraph | azuread' -ForegroundColor Yellow
	Write-Host ''
}
# Run Loaded
loaded
function Prompt {
	Write-Host '[' -NoNewline
	Write-Host (Get-Date -UFormat '%T') -ForegroundColor Green -NoNewline
	Write-Host ']: ' -NoNewline
	Write-Host 'As you wish Master' -NoNewline
	return ": "
}