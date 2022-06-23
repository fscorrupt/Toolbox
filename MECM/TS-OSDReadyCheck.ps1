$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

# OSD Ready Check
# Battery
$Battery=(Get-WmiObject win32_Battery).BatteryStatus
if ($Battery){
	if ($Battery -eq '2'){
		$IsAC='TRUE'
	} 
	Else {
		$IsAC = 'FALSE'
	}
}
Else{
	$IsAC='TRUE'
}

# Model
if ((Get-WmiObject win32_BaseBoard).Manufacturer -match 'Intel'){
	$Model=(Get-WmiObject win32_BaseBoard).Product
	} 
elseif ((Get-WmiObject win32_ComputerSystem).Manufacturer -eq 'LENOVO'){
	$Model=(Get-WmiObject win32_ComputerSystemProduct).Version
	} 
Else {
	$Model=(Get-WmiObject win32_ComputerSystem).Model
}

# RAM
if ((Get-wmiobject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum/1gb -ge '2'){
	$TotalRam='TRUE'
}
$tsenv.Value('TotalRam') = $TotalRam 
$tsenv.Value('Model') = $Model 
$tsenv.Value('IsAC') = $IsAC 