	$Requiredmodules = "Microsoft.PowerShell.Management", "PowerShellGet", "ActiveDirectory"
	foreach ($module in $Requiredmodules){	
		Import-Module $module -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
		if ($ModuleImportError){
			Write-Host "Required Module '$module' not found..."
			Write-Host "Installing '$module' for you..." -ForegroundColor Yellow
			Write-Host ''
			Install-Module -Name $module -AllowClobber -Force -Confirm:$False -ErrorAction SilentlyContinue
			Import-Module $module
		}
	}

	#Change Shell Color Theme
	$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$p = New-Object System.Security.Principal.WindowsPrincipal($id)

	cls

	Function Get-ADExchangeServer {
		# first a quick function to convert the server roles to a human readable form
		Function ConvertToExchangeRole {
			Param(
				[Parameter(Position=0)]
				[int]$roles
			)
			$roleNumber=@{
				2='MBX';
				4='CAS';
				16='UM';
				32='HUB';
				64='EDGE';
			}
			$roleList=New-Object -TypeName Collections.ArrayList
			foreach($key in ($roleNumber).Keys){
				if($key -band $roles){
					[void]$roleList.Add($roleNumber.$key)
				}
			}
			Write-Output $roleList
		}

		# Get the Configuration Context
		$rootDse=Get-ADRootDSE
		$cfgCtx=$rootDse.ConfigurationNamingContext

		# Query AD for Exchange Servers
		$exchServers=Get-ADObject -Filter "ObjectCategory -eq 'msExchExchangeServer'" `
		-SearchBase $cfgCtx `
		-Properties msExchCurrentServerRoles, networkAddress, serialNumber
		foreach($server in $exchServers){
			Try{
				$roles=ConvertToExchangeRole -roles $server.msExchCurrentServerRoles

				$fqdn=($server.networkAddress | 
				Where-Object {$_ -like 'ncacn_ip_tcp:*'}).Split(':')[1]

				New-Object -TypeName PSObject -Property @{
					Name=$server.Name;
					DnsHostName=$fqdn;
					Version=$server.serialNumber[0];
					ServerRoles=$roles;
				}
			}Catch{
				Write-Error "ExchangeServer: [$($server.Name)]. $($_.Exception.Message)"
			}
		}
	}
	Function GetDomain {
		$Root = [ADSI]"LDAP://RootDSE"
		$oForestConfig = $Root.Get("configurationNamingContext")
		$oSearchRoot = [ADSI]("LDAP://CN=Partitions," + $oForestConfig)
		$AdSearcher = [adsisearcher]"(&(objectcategory=crossref)(netbiosname=*))"
		$AdSearcher.SearchRoot = $oSearchRoot
		$domains = $AdSearcher.FindAll()
		return $domains
	}
	Function Get-MPFromAD {
		$domain = GetDomain

		Try {
			$ADSysMgmtContainer = [ADSI]("LDAP://CN=System Management,CN=System," + "$($Domain.Properties.ncname[0])")
			$AdSearcher = [adsisearcher]"(&(Name=SMS-MP-*)(objectClass=mSSMSManagementPoint))"
			$AdSearcher.SearchRoot = $ADSysMgmtContainer
			$ADManagementPoint = $AdSearcher.FindONE()
			$MP = $ADManagementPoint.Properties.mssmsmpname[0]
		} Catch {}

		Return $MP
	}
	function onprem-exc {
		$Exchange = (Get-ADExchangeServer | where ServerRoles -contains 'CAS')[0].DnsHostName
		if (!$Exchange){
			write-host "Could not find Exchange Server in AD... " -ForegroundColor Error
			write-host "Please specify Exchange Server FQDN manually... " -ForegroundColor yellow
			write-host "Exchange Server: " -ForegroundColor cyan -NoNewline
			$Exchange = Read-Host
		}
		$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$Exchange/powershell -AllowRedirection
		$Output = Import-PSSession -Session $ExchangeSession -AllowClobber -DisableNameChecking
	}
	function cloud-exc {
		$Exchange = (Get-ADExchangeServer | where ServerRoles -contains 'CAS')[1].DnsHostName
		$module = "ExchangeOnlineManagement"
		Import-Module $module -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
		if ($ModuleImportError){
			Write-Host "Required Module '$module' not found..."
			Write-Host "Installing '$module' for you..." -ForegroundColor Yellow
			Write-Host ''
			Install-Module -Name $module -AllowClobber -Force -Confirm:$False -ErrorAction SilentlyContinue
			Import-Module $module
		}
		$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$Exchange/powershell -AllowRedirection
		$Output = Import-PSSession -Session $ExchangeSession -AllowClobber -DisableNameChecking
		Connect-ExchangeOnline -ShowBanner:$false
	}
	function teams {
		$module = "MicrosoftTeams"
		Import-Module $module -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
		if ($ModuleImportError){
			Write-Host "Required Module '$module' not found..."
			Write-Host "Installing '$module' for you..." -ForegroundColor Yellow
			Write-Host ''
			Install-Module -Name $module -AllowClobber -Force -Confirm:$False -ErrorAction SilentlyContinue
			Import-Module $module
		}
		Connect-MicrosoftTeams
	}
	function OSInfo {
		$info = Get-ComputerInfo
		$Disk = (Get-Disk | where IsSystem -eq $true).AllocatedSize
		$Bitlocker = (New-Object -ComObject Shell.Application).NameSpace('C:').Self.ExtendedProperty('System.Volume.BitLockerProtection')
		$Bitlocker = switch ($Bitlocker){
				'0' {'Unencryptable'}
				'1' {'Encrypted'}
				'2' {'Not Encrypted'}
			}
		$OS = if($info.WindowsVersion){"$($info.OsName) $($info.OsArchitecture) | $($info.OsVersion) - $($info.WindowsVersion)"}Else{"$($info.OsName) $($info.OsArchitecture) | $($info.OsVersion)"}
		$Model = if($info.CsManufacturer -eq 'LENOVO'){$info.CsSystemFamilyCsModel}Else {$info.CsModel}
		$Processor = "$($info.CsProcessors.Name) | $($info.CsNumberOfLogicalProcessors) Logical Cores"
		$KeyboardLayout = $info.KeyboardLayout
		$Timezone = $info.TimeZone
		$Installdate = $info.OsInstallDate
		$Memory = ($info.CsTotalPhysicalMemory/1GB).ToString(".00") +" GB"
		$Disksize = ($Disk/1GB).ToString(".00") +" GB"
		$Domain = $info.CsDomain
		$serial = $info.BiosSeralNumber
		$Biosversion = $info.BiosSMBIOSBIOSVersion
		$BiosFirmType = $info.BiosFirmwareType
		$BootUptime = "$($info.OsLastBootUpTime.day).$($info.OsLastBootUpTime.month).$($info.OsLastBootUpTime.year) $($info.OsLastBootUpTime.hour):$($info.OsLastBootUpTime.Minute):$($info.OsLastBootUpTime.Second)"
		$Uptime = "Days: $($info.OsUptime.Days) Hours: $($info.OsUptime.Hours) Minutes: $($info.OsUptime.Minutes) Seconds: $($info.OsUptime.Seconds)"
		$Plattform = $info.PowerPlatformRole
		$HyperV = $info.HyperVisorPresent
		$Locale = $info.OsLocale

		Write-Host ""
		Write-Host "############### OS Specific" -ForegroundColor cyan
		Write-Host "OS:             " -ForegroundColor Yellow -NoNewline
		Write-Host "$OS"
		Write-Host "KeyboardLayout: " -ForegroundColor Yellow -NoNewline
		Write-Host "$KeyboardLayout"
		Write-Host "Timezone:       " -ForegroundColor Yellow -NoNewline
		Write-Host "$Timezone"
		Write-Host "Installdate:    " -ForegroundColor Yellow -NoNewline
		Write-Host "$Installdate"
		Write-Host "BootUptime:     " -ForegroundColor Yellow -NoNewline
		Write-Host "$BootUptime"
		Write-Host "Uptime:         " -ForegroundColor Yellow -NoNewline
		Write-Host "$Uptime"
		Write-Host "Domain:         " -ForegroundColor Yellow -NoNewline
		Write-Host "$Domain"
		Write-Host "HyperV-Role:    " -ForegroundColor Yellow -NoNewline
		Write-Host "$HyperV"
		Write-Host "Locale:         " -ForegroundColor Yellow -NoNewline
		Write-Host "$Locale"
		Write-Host "Bitlocker:      " -ForegroundColor Yellow -NoNewline
		Write-Host "$Bitlocker"
		Write-Host ""
		Write-Host "############### HW Specific" -ForegroundColor cyan
		Write-Host "Model:          " -ForegroundColor Yellow -NoNewline
		Write-Host "$Model"
		Write-Host "Processor:      " -ForegroundColor Yellow -NoNewline
		Write-Host "$Processor"
		Write-Host "Memory:         " -ForegroundColor Yellow -NoNewline
		Write-Host "$Memory"
		Write-Host "System Disk:    " -ForegroundColor Yellow -NoNewline
		Write-Host "$Disksize"
		Write-Host "serial:         " -ForegroundColor Yellow -NoNewline
		Write-Host "$serial"
		Write-Host "Biosversion:    " -ForegroundColor Yellow -NoNewline
		Write-Host "$Biosversion"
		Write-Host "BiosFirmType:   " -ForegroundColor Yellow -NoNewline
		Write-Host "$BiosFirmType"
		Write-Host "Plattform:      " -ForegroundColor Yellow -NoNewline
		Write-Host "$Plattform"
	}
	Function pass {
		-join(48..57+65..90+97..122|ForEach-Object{[char]$_}|Get-Random -C 20) | Set-Clipboard
		Write-Host 'Password copied to clipboard...' -ForegroundColor cyan
	}
	Function printpanel {
		write-host "Enter Printername: " -ForegroundColor Yellow -NoNewline
		$Printername = Read-Host
		$URL = "https://$Printername"+":50443/panel/remote_panel.cgi"
		if ($URL){
			[system.Diagnostics.Process]::Start("msedge",$URL) | Out-Null
		}
	}
	Function printinfo {
		$IP = Read-host "Enter IP of Printer"
		$module = "Proxx.SNMP"
		Import-Module $module -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
		if ($ModuleImportError){
			Write-Host "Required Module '$module' not found..."
			Write-Host "Installing '$module' for you..." -ForegroundColor Yellow
			Write-Host ''
			Install-Module -Name $module -AllowClobber -Force -Confirm:$False -ErrorAction SilentlyContinue
			Import-Module $module
		}

		$model = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.25.3.2.1.3.1).Value
		$total = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.1.1.0).Value
		$Serial = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.2.1.43.5.1.1.17.1).Value
		$printcolor = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.2.2).Value
		$copycolor = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.2.1).Value
		$printbw = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.1.2).Value
		$copybw = (Invoke-SnmpGet -IpAddress $IP -Oid 1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.1.1).Value
		$printername = (Invoke-SnmpGet -IpAddress $IP -Oid .1.3.6.1.2.1.1.3.0).Value
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
	Function msol {
		$module = "MSOnline"
		Import-Module $module -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
		if ($ModuleImportError){
			Write-Host "Required Module '$module' not found..."
			Write-Host "Installing '$module' for you..." -ForegroundColor Yellow
			Write-Host ''
			Install-Module -Name $module -AllowClobber -Force -Confirm:$False -ErrorAction SilentlyContinue
			Import-Module $module
		}
		Connect-MsolService
	}
	Function graph {
		$module = "Microsoft.Graph.Intune"
		Import-Module $module -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
		if ($ModuleImportError){
			Write-Host "Required Module '$module' not found..."
			Write-Host "Installing '$module' for you..." -ForegroundColor Yellow
			Write-Host ''
			Install-Module -Name $module -AllowClobber -Force -Confirm:$False -ErrorAction SilentlyContinue
			Import-Module $module
		}
		Connect-MSGraph
	}
	Function azuread {
		$module = "AzureAD"
		Import-Module $module -ErrorVariable ModuleImportError -ErrorAction SilentlyContinue
		if ($ModuleImportError){
			Write-Host "Required Module '$module' not found..."
			Write-Host "Installing '$module' for you..." -ForegroundColor Yellow
			Write-Host ''
			Install-Module -Name $module -AllowClobber -Force -Confirm:$False -ErrorAction SilentlyContinue
			Import-Module $module
		}
		Connect-AzureAD
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
	Function getdevice {
		# Site configuration
		$Domain = (Get-ADDomain).name
		$ProviderMachineName = Get-MPFromAD # SMS Provider machine name
		get-WMIObject -ComputerName $ProviderMachineName -Namespace "root\SMS" -Class "SMS_ProviderLocation" | foreach-object{ 
			if ($_.ProviderForLocalSite -eq $true){$SiteCode=$_.sitecode} 
		} 
		If($SiteCode){
			# Customizations
			$initParams = @{}

			# Import the ConfigurationManager.psd1 module 
			if((Get-Module ConfigurationManager) -eq $null) {
				Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
			}

			# Connect to the site's drive if it is not already present
			if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
				New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
			}

			# Set the current location to be the site code.
			$Currentlocation = get-location
			Set-Location "$($SiteCode):\" @initParams
	
			write-host "Enter samaccountname: " -ForegroundColor Yellow -NoNewline
			$Username = Read-Host 
			$DeviceName = (Get-CMUserDeviceAffinity -Username "$Domain\$Username").ResourceName
			Write-Host ''
			Write-Host "Primary Device of ($Username) is: " -NoNewline -ForegroundColor Cyan
			Write-Host $DeviceName -ForegroundColor Green
			Write-Host ''
			Set-Location $Currentlocation
		}
		Else {
			write-host "Could not find SCCM Sitecode in AD... " -ForegroundColor Error
			write-host "Please specify SCCM Server and Sitecode manually... " -ForegroundColor yellow
			write-host "SCCM Server: " -ForegroundColor cyan -NoNewline
			$ProviderMachineName = Read-Host
			write-host "Please specify SCCM Server and Sitecode manually... " -ForegroundColor cyan -NoNewline
			$SiteCode = Read-Host
			
			if (($SiteCode) -and ($ProviderMachineName)){
				# Customizations
				$initParams = @{}

				# Import the ConfigurationManager.psd1 module 
				if((Get-Module ConfigurationManager) -eq $null) {
					Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
				}

				# Connect to the site's drive if it is not already present
				if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
					New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
				}

				# Set the current location to be the site code.
				$Currentlocation = get-location
				Set-Location "$($SiteCode):\" @initParams
	
				write-host "Enter samaccountname: " -ForegroundColor Yellow -NoNewline
				$Username = Read-Host 
				$DeviceName = (Get-CMUserDeviceAffinity -Username "$Domain\$Username").ResourceName
				Write-Host ''
				Write-Host "Primary Device of ($Username) is: " -NoNewline -ForegroundColor Cyan
				Write-Host $DeviceName -ForegroundColor Green
				Write-Host ''
				Set-Location $Currentlocation
			}
		}
	}
	Function loaded {
		Write-Host 'Loaded Functions:' -ForegroundColor cyan
		Write-Host 'onprem-exc | cloud-exc | OSInfo | pass | sid2sam | printpanel | printinfo | msol | graph | azuread | teams | getdevice' -ForegroundColor Yellow
		write-host ''
	}
	# Run Loaded
	loaded
	if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		function prompt {
			#Assign Windows Title Text
			$host.ui.RawUI.WindowTitle = "Current Folder: $pwd"

			$CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
			$Date = (Get-Date -UFormat '%T')

			#Decorate the CMD Prompt
			Write-Host ""
			Write-host ' Elevated ' -BackgroundColor DarkRed -ForegroundColor White -NoNewline
			Write-Host " $($CmdPromptUser.Name.split("\")[1]) " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline

			Write-Host " $date " -NoNewline -BackgroundColor DarkGreen -ForegroundColor White
			return ": "
		}
	}
	Else{
		function prompt {
			#Assign Windows Title Text
			$host.ui.RawUI.WindowTitle = "Current Folder: $pwd"

			$CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
			$Date = (Get-Date -UFormat '%T')

			#Decorate the CMD Prompt
			Write-Host ""
			Write-host '' -BackgroundColor DarkRed -ForegroundColor White -NoNewline
			Write-Host " $($CmdPromptUser.Name.split("\")[1]) " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline

			Write-Host " $date " -NoNewline -BackgroundColor DarkGreen -ForegroundColor White
			return ": "
		}
	}
