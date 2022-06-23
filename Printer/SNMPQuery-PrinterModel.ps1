$IP = Read-host "Enter IP of Printer"
$SNMP = New-Object -ComObject olePrn.OleSNMP
$SNMP.Open($IP, "public")
$model = $SNMP.Get(".1.3.6.1.2.1.25.3.2.1.3.1")
$SNMP.Close()
Write-host "$model" -ForegroundColor Cyan