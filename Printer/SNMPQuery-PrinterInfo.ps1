$IP = Read-host "Enter IP of Printer"

Import-Module Proxx.SNMP -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
if ($ModuleImportError){
	Install-Module -Name Proxx.SNMP -Force
	Import-Module Proxx.SNMP
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
