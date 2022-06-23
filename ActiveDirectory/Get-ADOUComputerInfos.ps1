$OU = Read-Host "Please enter search OU (Distinguished Name)"
# Create empty object
$objTemplate = '' | Select-Object -Property  Name, Description, Primaryuser, Modified, whenChanged, whenCreated, OperatingSystem, OperatingSystemVersion
$objResult = @()

$Computers = Get-ADComputer -Properties * -Filter * -SearchBase $OU | Select-Object Name,Description,msDS-IsPrimaryComputerFor,Modified, whenChanged, whenCreated, OperatingSystem, OperatingSystemVersion
foreach ($Computer in $Computers){
	 #Fill Temp object with current section data
	 $objTemp = $objTemplate | Select-Object *
	 $Primaryuser = if($Computer.'msDS-IsPrimaryComputerFor'){($Computer.'msDS-IsPrimaryComputerFor' -split "," | ConvertFrom-StringData).CN} Else {"Not Set"}
	 $objTemp.Name = $Computer.Name
	 $objTemp.Description = $Computer.Description
	 $objTemp.Primaryuser = $Primaryuser
	 $objTemp.Modified= $Computer.Modified
	 $objTemp.whenChanged = $Computer.whenChanged
	 $objTemp.whenCreated = $Computer.whenCreated
	 $objTemp.OperatingSystem = $Computer.OperatingSystem
	 $objTemp.OperatingSystemVersion = $Computer.OperatingSystemVersion
   
	 #Add section data results to final object
	 $objResult += $objTemp
}

#$objResult = $objResult | Sort-Object -Property Name | ft -AutoSize
$objResult | Out-GridView
pause