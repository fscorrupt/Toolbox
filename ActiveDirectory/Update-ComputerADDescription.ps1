#Call the Script as System/Device
#Computer Object needs this right -> http://mctexpert.blogspot.com/2015/09/changing-computers-description-in.html

#Get Computer Infos
$build = [environment]::OSVersion.Version.Build
$CPU = (Get-WmiObject Win32_Processor).name
$COMPUTERNAME = $env:COMPUTERNAME

if ((Get-WmiObject win32_OperatingSystem).caption -match 'LTSC'){
	$LTSC = 'LTSC'
}
if(Get-WmiObject -Class win32_systemenclosure | Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 -or $_.chassistypes -eq 14}){ 
	$isLaptop = $true 
}

if ($CPU -match "i7-" -and $isLaptop){$PowerNotebook = "PowerNotebook"}

$operatingSystemVersion = switch ($build){
		'10240' {'1507'}
		'10586' {'1511'}
		'14393' {'1607'}
		'15063' {'1703'}
		'16299' {'1709'}
		'17134' {'1803'}
		'17763' {'1809'}
		'18362' {'1903'}
		'18363' {'1909'}
		'19041' {'2004'}
		'19042' {'20H2'}
		'19043' {'21H1'}
		'19044' {'21H2'}
		'22000' {'21H2'}
	}
	
	if ($LTSC){
		$operatingSystemVersion = $LTSC
	}
	$Model = if ((Get-WmiObject win32_BaseBoard).Manufacturer -match 'Intel'){(Get-WmiObject win32_BaseBoard).Product} elseif ((Get-WmiObject win32_ComputerSystem).Manufacturer -eq 'LENOVO'){(Get-WmiObject win32_ComputerSystemProduct).Version} Else {(Get-WmiObject win32_ComputerSystem).Model}
	if ($build -le '19044'){$OSVersion = 'Win 10 - '+ $operatingSystemVersion}
	Else {$OSVersion = 'Win 11 - '+ $operatingSystemVersion}
	
	#Search for Computer in AD
	$Search = [adsisearcher]"(&(objectCategory=Computer)(name=$COMPUTERNAME))"
	#Find all Properties
	$ADSearchResults=$Search.Findone()
	#Get only Required Properties + add to Object
	$SelectedValues = $ADSearchResults.GetDirectoryEntry() | ForEach-Object{
		New-Object -TypeName PSCustomObject -Property @{
			Description = $_.description.ToString()
			distinguishedname = $_.distinguishedname.ToString()
		}
	}

	#Getting Current Computer AD Description
	#Extracting User Name from AD Description
	if($SelectedValues.Description -match ';'){
		$UserName = $SelectedValues.Description.split(';')[0]
	}
	Else {
		$UserName = $SelectedValues.Description.split('|')[0].trimend(' ')
	}
	
	#Getting Computer distinguishedname
	$DN = $SelectedValues.distinguishedname

	#Building new AD Description
	if ($PowerNotebook){
		$ADDescription = "$UserName | $Model | $OSVersion | $PowerNotebook"
	}
	Else{
		$ADDescription = "$UserName | $Model | $OSVersion"
	}
	try{
		#Modify Computer Description
		$ObjClient = [ADSI]"LDAP://$DN"
		$ObjClient.Description = $ADDescription
		$ObjClient.SetInfo()
	}
	catch {
		if ($error[0].exception -match ('Access is denied'))
		{
			$result = 'AccessDenied'
		}
		Else {
			$result = 'Success'
		}
	}