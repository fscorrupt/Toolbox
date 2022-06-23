	$TempFileLocation = "$env:windir\Temp","$env:TEMP"
	$SoftwareDistributionLocation = "$env:windir\SoftwareDistribution\Download"
	$IISLogPath = "C:\inetpub\logs\LogFiles"
	$maxDaystoKeep = -30
	$ModuleName = "MSIPatches" # https://www.powershellgallery.com/packages/MSIPatches/1.0.20
	
	# Start Windows Temp folder Cleanup
	$TempFile = Get-ChildItem $TempFileLocation -Recurse
	$TempFileCount = ($TempFile).count

	if($TempFileCount -eq "0") { 
		Write-Host "INFO: There are no files in the folder $TempFileLocation"
	}
	Else {
		$TempFile | Remove-Item -Confirm:$false -Recurse -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		Write-Host "INFO: Cleared $TempFileCount files in the folder $TempFileLocation"
	}
	
	# Start local User Temp Cleanup
	Get-ChildItem -Path 'C:\Users' | foreach {
		Get-ChildItem -Path "$($_.FullName)\AppData\Local\Temp" -ErrorAction SilentlyContinue | Remove-Item -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
		Get-ChildItem -Path "$($_.FullName)\AppData\Local\Temporary Internet Files" -ErrorAction SilentlyContinue | Remove-Item -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
	}
	Write-Host "INFO: Cleared local user appdata temp files..."
	
	# Start IIS log File Cleanup
	if (Test-Path $IISLogPath){
		Write-Host "INFO: IIS detected, cleaning up old Log Files..."
		$itemsToDelete = Get-ChildItem -Path $IISLogPath -Recurse -File -Filter *.log | Where LastWriteTime -lt ((get-date).AddDays($maxDaystoKeep)) 
		If ($itemsToDelete.Count -gt 0)
		{ 
			Write-Host "INFO: Found '$($itemsToDelete.Count)' old IIS log Files..."
			ForEach ($item in $itemsToDelete)
			{ 
				Remove-Item $item.FullName -ErrorAction SilentlyContinue -Force -Confirm:$false
			}
			Write-Host "INFO: IIS Log Files cleaned..."
		}
	}
	
	# Start SoftwareDistribution Cleanup
	$SoftwareDistribution = Get-ChildItem $SoftwareDistributionLocation -Recurse
	$SoftwareDistributionCount = ($SoftwareDistribution).Count
	
	if($SoftwareDistributionCount -eq "0"){
		Write-Host "INFO: There are no files in the folder $SoftwareDistributionLocation"
	}
	Else
	{
		$SoftwareDistribution | Remove-Item -Confirm:$false -Recurse -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		Write-Host "INFO: Cleared $SoftwareDistributionCount files in the folder $SoftwareDistributionLocation"
	}
	
	# Start Orphaned Installer Cleanup
	# Install Module
	Write-Host '---------------------------------------'
	Install-Module -Name $ModuleName -Force
	Import-Module -Name $ModuleName -Force
	Write-Host "INFO: Importing Module - $ModuleName"

	Write-Host '---------------------------------------'
	Write-Host "INFO: Getting Orphaned Installers..."

	$patches = Get-OrphanedPatch
	$Allpatches = Get-MsiPatch

	if ($patches){
		Write-Host "WARNING: Found '$($patches.count)' orphaned installers..."
		Write-Host "INFO: Removing Orphaned installers now..."
		Write-Host '---------------------------------------'
		$patches | Remove-Item -force
		Write-Host "INFO: Orphaned Installers removed..."
		Write-Host "INFO: Installer Cleanup, gained: $($Allpatches.OrphanedPatchSize)..."
	}
	Else {
		Write-Host "INFO: No orphaned installers found..."
	}
