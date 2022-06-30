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

Function printer-info {
	$IP = Read-host "Enter IP of Printer"

	Import-Module Proxx.SNMP -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
	if ($ModuleImportError){
		Install-Module -Name Proxx.SNMP -Force
	}

	$model = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.25.3.2.1.3.1).Value
	$total = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.1.1.0).Value
	$Serial = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.2.1.43.5.1.1.17.1).Value
	$printcolor = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.2.2).Value
	$copycolor = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.2.1).Value
	$printbw = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.1.2).Value
	$copybw = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.1.1).Value
	$Uptime = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.1.3.0).Value
	$BlackToner = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.43.11.1.1.9.1.4).Value +'%'
	$CyanToner = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.43.11.1.1.9.1.1).Value +'%'
	$MagentaToner = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.43.11.1.1.9.1.2).Value +'%'
	$YellowToner = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.43.11.1.1.9.1.3).Value +'%'
	$BlackDrum = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.43.11.1.1.9.1.11).Value +'%'
	$CyanDrum = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.43.11.1.1.9.1.5).Value +'%'
	$MagentaDrum = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.43.11.1.1.9.1.7).Value +'%'
	$YellowDrum = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.43.11.1.1.9.1.9).Value +'%'

	Write-Host ""
	Write-host "------ General ------" -ForegroundColor Green
	Write-host "Model:                   " -NoNewline -ForegroundColor Yellow 
	Write-Host "$model" -ForegroundColor Cyan
	Write-host "Uptime:                  " -NoNewline -ForegroundColor Yellow 
	Write-Host "$Uptime" -ForegroundColor Gray
	Write-host "Serial:                  " -NoNewline -ForegroundColor Yellow 
	Write-Host "$Serial" -ForegroundColor Gray
	Write-Host ""
	Write-host "------ Prints ------" -ForegroundColor Green
	Write-host "Total Prints:            " -NoNewline -ForegroundColor Yellow 
	Write-Host "$total" -ForegroundColor Gray
	Write-host "Color Prints:            " -NoNewline -ForegroundColor Yellow 
	Write-Host "$printcolor" -ForegroundColor Gray
	Write-host "Color Copy:              " -NoNewline -ForegroundColor Yellow 
	Write-Host "$copycolor" -ForegroundColor Gray
	Write-host "BW Prints:               " -NoNewline -ForegroundColor Yellow 
	Write-Host "$printbw" -ForegroundColor Gray
	Write-host "BW Copy:                 " -NoNewline -ForegroundColor Yellow 
	Write-Host "$copybw" -ForegroundColor Gray
	Write-Host ""
	Write-host "------ TONER ------" -ForegroundColor Green
	Write-host "Remaining BW Toner:      " -NoNewline -ForegroundColor Yellow 
	Write-Host "$BlackToner" -ForegroundColor Gray
	Write-host "Remaining Cyan Toner:    " -NoNewline -ForegroundColor Yellow 
	Write-Host "$CyanToner" -ForegroundColor Gray
	Write-host "Remaining Magenta Toner: " -NoNewline -ForegroundColor Yellow 
	Write-Host "$MagentaToner" -ForegroundColor Gray
	Write-host "Remaining Yellow Toner:  " -NoNewline -ForegroundColor Yellow 
	Write-Host "$YellowToner" -ForegroundColor Gray
	Write-Host ""
	Write-host "------ DRUM ------" -ForegroundColor Green
	Write-host "Remaining BW Drum:       " -NoNewline -ForegroundColor Yellow 
	Write-Host "$BlackDrum" -ForegroundColor Gray
	Write-host "Remaining Cyan Drum:     " -NoNewline -ForegroundColor Yellow 
	Write-Host "$CyanDrum" -ForegroundColor Gray
	Write-host "Remaining Magenta Drum:  " -NoNewline -ForegroundColor Yellow 
	Write-Host "$MagentaDrum" -ForegroundColor Gray
	Write-host "Remaining Yellow Drum:   " -NoNewline -ForegroundColor Yellow 
	Write-Host "$YellowDrum" -ForegroundColor Gray
	Write-Host ""
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
	Write-Host 'Functions: uptime | pass | sid2sam | printer-remote | printer-info | msol | msgraph | azuread' -ForegroundColor Yellow
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
